FROM ghcr.io/actions/actions-runner:latest

USER root

RUN apt-get update -qq && \
    apt-get install -qqy --no-install-recommends \
    skopeo && \
    apt-get autoremove --purge -qqy && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

COPY --chown=runner:docker entrypoint.sh /home/runner/entrypoint.sh

RUN chmod +x /home/runner/entrypoint.sh

USER runner
ENTRYPOINT ["/home/runner/entrypoint.sh"]
