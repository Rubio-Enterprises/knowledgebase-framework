#!/bin/sh
set -eu
lefthook_bin="$(mise which lefthook)"
PATH="$(dirname "$lefthook_bin"):$PATH"
export PATH
KB_TEST_JUNIT="$PWD/reports/test/junit.xml" bash tests/run.sh "$@"
