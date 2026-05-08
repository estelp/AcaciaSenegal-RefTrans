#!/bin/bash

set -euo pipefail

echo "======================================"
echo " Miniforge + MultiQC installation"
echo "======================================"

# Variables
INSTALLER="$HOME/Miniforge3-Linux-x86_64.sh"
MINIFORGE_DIR="$HOME/miniforge3"
ENV_NAME="multiqc_env"

# Download Miniforge installer
echo "Downloading Miniforge..."

wget -q \
https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh \
-O "$INSTALLER"

chmod +x "$INSTALLER"

# Install Miniforge if not already present
if [[ ! -d "$MINIFORGE_DIR" ]]; then
    echo "Installing Miniforge..."
    bash "$INSTALLER" -b -p "$MINIFORGE_DIR"
else
    echo "Miniforge already installed."
fi

# Load conda (without activating any env)
source "$MINIFORGE_DIR/etc/profile.d/conda.sh"

# Update conda
echo "Updating conda..."
conda update -n base -c conda-forge conda -y

# Configure channels (best practice bioinfo)
conda config --add channels defaults
conda config --add channels bioconda
conda config --add channels conda-forge
conda config --set channel_priority strict

# Create environment if not exists
if ! conda env list | grep -q "multiqc_env"; then
    echo "Creating conda environment: multiqc_env"
    conda create -n multiqc_env python=3.8 multiqc=1.13 -y
else
    echo "Environment multiqc_env already exists"
fi

# Cleanup
rm -f "$INSTALLER"

echo "======================================"
echo " Installation finished"
echo "======================================"
