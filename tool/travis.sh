#!/bin/bash

# Fast fail the script on failures.
set -xe

dartanalyzer --fatal-warnings .

pub run test -p vm
pub run build_runner test