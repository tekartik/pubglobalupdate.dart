#!/bin/bash

# Fast fail the script on failures.
set -xe

dartfmt -w .
dartanalyzer --fatal-warnings bin test

pub run test -p vm,chrome
# pub run build_runner test