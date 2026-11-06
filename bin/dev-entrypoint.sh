#!/bin/sh
set -eu
# shellcheck source=bin/playwright-env.sh
. /usr/local/lib/knowledge-playwright-env.sh
exec /opt/standards/bin/entrypoint.sh "$@"
