#!/bin/bash
# yq (https://github.com/mikefarah/yq/) version 4.44.1

VERSION=v4.44.1

sudo wget https://github.com/mikefarah/yq/releases/latest/download/${VERSION}/yq_linux_amd64 -O /usr/local/bin/yq
sudo chmod +x /usr/local/bin/yq

yq --version

