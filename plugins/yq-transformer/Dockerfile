FROM mikefarah/yq:4
LABEL org.opencontainers.image.source="https://github.com/uint0/kustomize-plugins"

USER yq
COPY --chown=yq ./plugin.sh ./plugin.sh
RUN chmod +x ./plugin.sh
ENTRYPOINT [ "./plugin.sh" ]