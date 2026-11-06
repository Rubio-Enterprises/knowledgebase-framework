#!/bin/sh
set -eu
case "$(uname -m)" in
aarch64) export PLAYWRIGHT_HOST_PLATFORM_OVERRIDE=ubuntu24.04-arm64 ;;
x86_64) export PLAYWRIGHT_HOST_PLATFORM_OVERRIDE=ubuntu24.04-x64 ;;
*)
  echo "Unsupported Playwright architecture" >&2
  exit 1
  ;;
esac
