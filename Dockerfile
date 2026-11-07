# syntax=docker/dockerfile:1@sha256:4edf897a3ffa55b89f906fc8cc78afdb3f1834cc9c7083565e611a8a7d5fe99e
FROM ghcr.io/rubio-enterprises/base:main AS dev

USER root
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends build-essential graphviz graphviz-tools libatomic1 rsync && rm -rf /var/lib/apt/lists/*
# Mise 2026.11.1 reads the system config's lock at /etc/mise/mise.lock
# Native dependency sidecars under image/.mise/ are part of the lock
COPY image/ /etc/mise/
RUN mv /etc/mise/mise.toml /etc/mise/config.toml \
 && chmod -R a+rX /etc/mise
RUN MISE_OVERRIDE_CONFIG_FILENAMES=/opt/standards/mise/standards.toml \
    node /opt/standards/image/locked-tools.mjs /etc/mise/config.toml /etc/mise/mise.lock \
 && tools="$(yq -p toml -oy -r '.tools | keys | .[]' /etc/mise/config.toml)" \
 && mise install --locked $tools \
 && mise reshim \
 && chmod -R a+rX /etc/mise

COPY bin/prewarm-hook-tools.sh /usr/local/bin/prewarm-hook-tools
RUN /usr/local/bin/prewarm-hook-tools
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
RUN cd /workspaces/warmup \
 && runuser -u vscode -- env HOME=/home/vscode bin/setup.sh \
 && rm -rf /workspaces/warmup
USER vscode
