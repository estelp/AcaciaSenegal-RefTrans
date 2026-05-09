#!/bin/bash
#------ Slurm configuration ------
#SBATCH --job-name=install_multiqc
#SBATCH --partition=normal
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=04:00:00
#SBATCH --output=/scratch/name/AcaciaSenegal-RefTrans/logs/install_multiqc_%j.out
#SBATCH --error=/scratch/name/AcaciaSenegal-RefTrans/logs/install_multiqc_%j.err
#SBATCH --nodelist=node06

set -euo pipefail

echo "======================================"
echo " Miniforge + MultiQC installation"
echo "======================================"

echo "Job started: $(date)"

# -----------------------------
# Variables
# -----------------------------
INSTALLER="$HOME/Miniforge3-Linux-x86_64.sh"
MINIFORGE_DIR="$HOME/miniforge3"
ENV_NAME="multiqc_env"
LOG_DIR="/scratch/name/AcaciaSenegal-RefTrans/logs"

# -----------------------------
# Create log directory
# -----------------------------
mkdir -p "$LOG_DIR"

# -----------------------------
# Check wget availability
# -----------------------------
if ! command -v wget &> /dev/null; then
    echo "ERROR: wget is not installed or not available."
    exit 1
fi

# -----------------------------
# Download Miniforge installer
# -----------------------------
echo "Downloading Miniforge installer..."

wget -qO "$INSTALLER" \
https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh

chmod +x "$INSTALLER"

# -----------------------------
# Install Miniforge
# -----------------------------
if [[ ! -d "$MINIFORGE_DIR" ]]; then

    echo "Installing Miniforge..."

    bash "$INSTALLER" -b -p "$MINIFORGE_DIR"

else

    echo "Miniforge already installed."

fi

# -----------------------------
# Load conda
# -----------------------------
source "$MINIFORGE_DIR/etc/profile.d/conda.sh"

# -----------------------------
# Update conda
# -----------------------------
echo "Updating conda..."

conda update -n base -c conda-forge conda -y

# -----------------------------
# Configure conda channels
# -----------------------------
echo "Configuring conda channels..."

conda config --remove-key channels 2>/dev/null || true

conda config --add channels conda-forge
conda config --add channels bioconda
conda config --add channels defaults

conda config --set channel_priority strict

# -----------------------------
# Create MultiQC environment
# -----------------------------
if conda env list | grep -qE "^${ENV_NAME}[[:space:]]"; then

    echo "Environment $ENV_NAME already exists."

else

    echo "Creating environment: $ENV_NAME"

    conda create \
        -n "$ENV_NAME" \
        -c conda-forge \
        -c bioconda \
        python=3.12 \
        multiqc \
	setuptools \
        -y

fi

# -----------------------------
# Cleanup installer
# -----------------------------
rm -f "$INSTALLER"

echo "======================================"
echo " Installation completed successfully"
echo "======================================"

echo "Job finished: $(date)"
