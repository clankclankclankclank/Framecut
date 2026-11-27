#!/bin/bash
# SPDX-License-Identifier: AGPL-3.0-or-later
set -uo pipefail
directory=$(cd -- "$(dirname -- "$0")" && pwd -P) || exit 1
/bin/bash "$directory/build_and_run_macos.sh" "$@"
result=$?
if (( result != 0 )) && [[ -t 0 && -t 1 ]]; then
    printf '\nBuild or launch failed (status %s). Press Return to close.\n' "$result"
    read -r _
fi
exit "$result"
