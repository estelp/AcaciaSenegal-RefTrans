#!/bin/bash
#------Slurm configuration------
#SBATCH --job-name=fastqc_trim
#SBATCH --partition=normal
#SBATCH --cpus-per-task=12
#SBATCH --output=/scratch/name/AcaciaSenegal-RefTrans/logs/fastqc_trim_%j.out
#SBATCH --error=/scratch/name/AcaciaSenegal-RefTrans/logs/fastqc_trim_%j.err
#SBATCH --nodelist=node06

# Stop script if error
set -euo pipefail

# Modules loading
module load bioinfo-wave
module load FastQC/0.12.1

# Directories
Input_dir="/scratch/name/AcaciaSenegal-RefTrans/Data/Trimmed"
Output_dir="/scratch/name/AcaciaSenegal-RefTrans/Results/QC/FastQC_Trim"

# Create output directory
mkdir -p "$Output_dir"

echo "FastQC analysis started: $(date)"

# Loop on forward reads
for R1 in "$Input_dir"/*_1.fastq.gz; do

    # Sample basename
    base=$(basename "$R1" _1.fastq.gz)

    # Reverse read
    R2="$Input_dir/${base}_2.fastq.gz"

    # Check if R2 exists
    if [[ ! -f "$R2" ]]; then
        echo "Missing pair for sample: $base"
        continue
    fi

    echo "Processing sample: $base"

    # Run FastQC
    fastqc \
        --threads 12 \
        --outdir "$Output_dir" \
        "$R1" "$R2"

done

echo "FastQC analysis completed: $(date)"
