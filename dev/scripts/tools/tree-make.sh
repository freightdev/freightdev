#!/usr/bin/env bash

set -e

tree -L 7 -I 'archives|Shadcn|dev' | sed 's/\x1b\[[0-9;]*m//g' > test.txt
