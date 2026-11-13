FROM ghcr.io/rubio-enterprises/base:main AS dev

USER root
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends build-essential graphviz graphviz-tools libatomic1 rsync && rm -rf /var/lib/apt/lists/*
# Mise 2026.11.1 reads the system config's lock at /etc/mise/mise.lock
# Native dependency sidecars under image/.mise/ are part of the lock
COPY image/ /etc/mise/
RUN --mount=type=secret,id=GITHUB_TOKEN /opt/standards/image/install.sh

COPY bin/prewarm-hook-tools.sh /usr/local/bin/prewarm-hook-tools
USER vscode
RUN /usr/local/bin/prewarm-hook-tools
USER root
COPY bin/playwright-env.sh /usr/local/lib/knowledge-playwright-env.sh
COPY bin/dev-entrypoint.sh /usr/local/bin/knowledge-entrypoint
ENTRYPOINT ["/usr/local/bin/knowledge-entrypoint"]
RUN . /usr/local/lib/knowledge-playwright-env.sh \
 && playwright install --with-deps chromium-headless-shell \
 && chown -R vscode:vscode /home/vscode/.cache/ms-playwright

FROM dev AS ci
COPY --link --from=ghcr.io/rubio-enterprises/runner:main --chown=1000:1000 /home/runner /opt/actions-runner
WORKDIR /opt/actions-runner

# Same home and cache paths as the eventual runner, not root's throwaway caches
COPY --chown=1000:1000 . /workspaces/warmup
RUN /opt/standards/image/warmup.sh
USER vscode
