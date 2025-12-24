#!/bin/bash

# Download latest Miniconda installer (Linux, Python 3.13)
wget https://repo.anaconda.com/miniconda/Miniconda3-py310_23.7.2-1-Linux-x86_64.sh -O ~/miniconda.sh

# Run the installer
bash ~/miniconda.sh

# Follow prompts to install (default location is ~/.miniconda3)

# After installation, restart your shell or source conda.sh
source ~/.miniconda3/etc/profile.d/conda.sh

# Confirm conda works again
conda --version
