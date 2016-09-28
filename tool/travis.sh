#!/bin/bash

# Fast fail the script on failures.
set -e

dartanalyzer --fatal-warnings \
  lib/cmd_run.dart \
  lib/dartbin.dart \
  lib/process_run.dart

pub run test -p vm