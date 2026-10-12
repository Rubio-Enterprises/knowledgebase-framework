#!/usr/bin/env bash
# The Shell's Copier migration task (ADR-0010). Copier runs it in the knowledgebase's folder when
# `copier update` crosses a major version:
#
#   migrate.sh <version>
#
# It leaves shell/migrations/<version>.md as the knowledgebase's MIGRATION-<version>.md and points a
# root knowledgebase's lefthook.yml at the new major's Hooks. An embedded knowledgebase's repository
# owns its lefthook.yml, so the Migration file covers that step instead.
set -euo pipefail

version=$1
shell="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
major="${version%%.*}"
previous=$((major - 1))

cp "$shell/migrations/$version.md" "MIGRATION-$version.md"

if [ -f lefthook.yml ] && grep 'knowledgebase-framework' lefthook.yml >/dev/null; then
  sed -e "s/^\([[:space:]]*ref:[[:space:]]*\)v${previous}[[:space:]]*$/\1v$major/" \
    -e "s/knowledgebase-framework-v$previous/knowledgebase-framework-v$major/g" \
    -e "s/framework's v$previous branch/framework's v$major branch/" lefthook.yml >lefthook.yml.new
  mv lefthook.yml.new lefthook.yml
  # Fetch the new major's Hooks now, so the next commit runs them.
  lefthook install >/dev/null 2>&1 || echo "Couldn't fetch the v$major Hooks: go online and run 'lefthook install'." >&2
fi

echo "Left MIGRATION-$version.md: have an agent complete it, then commit everything once."
