#!/bin/bash
#------ Slurm configuration ------
#SBATCH --job-name=multiqc_raw
#SBATCH --partition=normal
#SBATCH --cpus-per-task=12
#SBATCH --mem=8G
#SBATCH --time=02:00:00
#SBATCH --output=/scratch/name/AcaciaSenegal-RefTrans/logs/multiqc_raw_%j.out
#SBATCH --error=/scratch/name/AcaciaSenegal-RefTrans/logs/multiqc_raw_%j.err
#SBATCH --nodelist=node06

set -euo pipefail

echo "======================================"
echo " MultiQC analysis started"
echo "======================================"

echo "Start time: $(date)"

# -----------------------------
# Variables
# -----------------------------
MINIFORGE_DIR="$HOME/miniforge3"
ENV_NAME="multiqc_env"

Fastqc_dir="/scratch/name/AcaciaSenegal-RefTrans/Results/QC/FastQC_Raw"
Multiqc_out="/scratch/name/AcaciaSenegal-RefTrans/Results/QC/MultiQC_Raw"
Log_dir="/scratch/name/AcaciaSenegal-RefTrans/logs"

# -----------------------------
# Create directories
# -----------------------------
mkdir -p "$Multiqc_out" "$Log_dir"

# -----------------------------
# Load conda
# -----------------------------
source "$MINIFORGE_DIR/etc/profile.d/conda.sh"

# -----------------------------
# Check conda environment
# -----------------------------
if ! conda env list | grep -qE "^${ENV_NAME}[[:space:]]"; then

    echo "ERROR: Conda environment '$ENV_NAME' not found."
    echo "Please run the installation script first."

    exit 1

fi

# -----------------------------
# Activate environment
# -----------------------------
conda activate "$ENV_NAME"

# -----------------------------
# Check FastQC directory
# -----------------------------
if [[ ! -d "$Fastqc_dir" ]]; then

    echo "ERROR: FastQC directory not found:"
    echo "$Fastqc_dir"

    exit 1

fi

# -----------------------------
# Check FastQC reports
# -----------------------------
if ! ls "$Fastqc_dir"/*_fastqc.zip >/dev/null 2>&1; then

    echo "ERROR: No FastQC reports found in:"
    echo "$Fastqc_dir"

    exit 1

fi

echo "Running MultiQC on FastQC results..."

# -----------------------------
# Run MultiQC
# -----------------------------
multiqc "$Fastqc_dir" \
    --outdir "$Multiqc_out"

echo "======================================"
echo " MultiQC analysis completed"
echo "======================================"

echo "End time: $(date)"
