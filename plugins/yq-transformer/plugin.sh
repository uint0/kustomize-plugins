#!/usr/bin/env sh
set -euo pipefail

#region setup
input=$(cat); readonly input
output="$input"

readonly transformations="$(echo "$input" | yq .functionConfig.spec.transformations)"
readonly log_level="$(echo "$input" | yq '.functionConfig.metadata.annotations."plugins.uint0.dev/log-level" // "warn"')"

trace() {
  if [[ "$log_level" == "debug" || "$log_level" == "trace" ]]; then echo "$@" >&2; fi
}
debug() {
  if [ "$log_level" == "trace" ]; then echo "$@" >&2; fi
}
#endregion

#region main
trace "initial=($output)"

i=0
while [ "$i" -lt "$(echo "$transformations" | yq ". | length")" ]; do
  select="$(echo "$transformations" | yq ".[$i].select")"; readonly select
  apply="$(echo "$transformations" | yq ".[$i].apply")"; readonly apply

  yq_transform=".items[] |= with(select($select); $apply)"
  debug "index=$i select=($select) apply=($apply) yq_transform=($yq_transform)"

  output="$(echo "$output" | yq "$yq_transform")"

  trace "output=($output)"

  i=$((i+1))
done
#endregion

echo "$output"
