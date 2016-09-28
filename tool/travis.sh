#!/bin/bash

# Fast fail the script on failures.
set -e

dartanalyzer --fatal-warnings \
  bin/pubglobalupdate.dart \

pub run test -p vm