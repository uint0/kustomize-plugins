#!/usr/bin/env bash

set -euo pipefail

docker compose build

work_dir="$(mktemp -d)"
trap "rm -rf $work_dir" EXIT

check_output() {
  local expect="$1"
  local actual="$2"

  local yaml_norm="[.] | sort_by(.kind + .metadata.name) | .[] | sort_keys(..) | ... comments=""" 

  diff --width "${COLUMNS:-240}" -y \
    <(cat "$expect" | grep -v internal.config.kubernetes.io | yq ea -P "$yaml_norm" -o=props) \
    <(cat "$actual" | grep -v internal.config.kubernetes.io | yq ea -P "$yaml_norm" -o=props)
}

rv=0
for plugin in $(ls -1 plugins); do
  for test in $(ls -1 "plugins/$plugin/test"); do
    echo -n "Test [$plugin/$test] .. "

    test_dir="$work_dir/$plugin/$test"

    mkdir -p "$test_dir"
    output_file="$test_dir/out.yaml"
    log_file="$test_dir/build.log"
    diff_file="$test_dir/diff"

    passed=true
    if ! kustomize build --enable-alpha-plugins --output "$output_file" ./plugins/$plugin/test/$test/ > "$log_file" 2>&1; then
        passed=false
    elif ! check_output "$output_file" "plugins/$plugin/test/$test/_expect/manifests.yaml" > "$diff_file" 2>&1; then
        passed=false
    fi

    if ! "$passed"; then
        echo -e "\e[31mFAIL\e[0m"

        if [ -f "$log_file" ]; then
            echo "  Bld:"
            cat "$log_file" | nl -w 6
        else
            echo "  Bld: None"
        fi
        if [ -f "$diff_file" ]; then
            echo "  Dif:"
            cat "$diff_file" | nl -w 6
        else
            echo "  Dif: None"
        fi

        rv=1
    else
        echo -e "\e[32mPASS\e[0m"
    fi
  done
done

exit "$rv"
