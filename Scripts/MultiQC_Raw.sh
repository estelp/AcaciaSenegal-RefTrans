#!/bin/bash
#----Slurm configuration----
#SBATCH --job-name=multiqc_raw
#SBATCH --partition=normal
#SBATCH --cpus-per-task=12
#SBATCH --output=/scratch/name/AcaciaSenegal-RefTrans/logs/multiqc_raw_%j.out
#SBATCH --error=/scratch/name/AcaciaSenegal-RefTrans/logs/multiqc_raw_%j.err
#SBATCH --nodelist=node06

set -euo pipefail

echo "MultiQC started: $(date)"

# -----------------------------
# Conda activation
# -----------------------------
source ~/miniforge3/etc/profile.d/conda.sh
conda activate multiqc_env

# -----------------------------
# Directories (MATCH FASTQC)
# -----------------------------
Fastqc_dir="/scratch/name/AcaciaSenegal-RefTrans/Results/QC/FastQC_Raw"
Multiqc_out="/scratch/name/AcaciaSenegal-RefTrans/Results/QC/MultiQC_Raw"

mkdir -p "$Multiqc_out"

# -----------------------------
# Check input
# -----------------------------
if [[ ! -d "$Fastqc_dir" ]]; then
    echo "ERROR: FastQC directory not found: $Fastqc_dir"
    exit 1
fi

echo "Running MultiQC on: $Fastqc_dir"

# -----------------------------
# Run MultiQC
# -----------------------------
multiqc "$Fastqc_dir" \
    -o "$Multiqc_out" \
    --threads 12

echo "MultiQC finished: $(date)"
