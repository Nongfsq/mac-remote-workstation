#!/bin/zsh
set -euo pipefail

pmset -g batt
pmset -g live
ioreg -r -k AppleClamshellCausesSleep -d 1 | rg "AppleClamshell|SleepDisabled" || true
