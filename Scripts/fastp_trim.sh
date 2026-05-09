#!/bin/bash
#------ Slurm configuration ------
#SBATCH --job-name=fastp_trim
#SBATCH --partition=normal
#SBATCH --cpus-per-task=12
#SBATCH --mem=16G
#SBATCH --time=08:00:00
#SBATCH --output=/scratch/name/AcaciaSenegal-RefTrans/logs/fastp_trim_%j.out
#SBATCH --error=/scratch/name/AcaciaSenegal-RefTrans/logs/fastp_trim_%j.err
#SBATCH --nodelist=node06

set -euo pipefail

echo "======================================"
echo " fastp trimming started"
echo "======================================"

echo "Start time: $(date)"

# -----------------------------
# Modules
# -----------------------------
module load bioinfo-wave
module load fastp/0.20.1

# -----------------------------
# Directories
# -----------------------------
Input_dir="/scratch/name/AcaciaSenegal-RefTrans/Data/Raw"
Trimmed_dir="/scratch/name/AcaciaSenegal-RefTrans/Data/Trimmed"
Report_dir="/scratch/name/AcaciaSenegal-RefTrans/Results/QC/FastP"
Log_dir="/scratch/name/AcaciaSenegal-RefTrans/logs"

# -----------------------------
# Create directories
# -----------------------------
mkdir -p \
    "$Trimmed_dir" \
    "$Report_dir" \
    "$Log_dir"

# -----------------------------
# Loop through samples
# -----------------------------
for R1 in "$Input_dir"/*_1.fastq.gz; do

    # Sample basename
    base=$(basename "$R1" _1.fastq.gz)

    # Mate pair
    R2="$Input_dir/${base}_2.fastq.gz"

    # Check R2 existence
    if [[ ! -f "$R2" ]]; then

        echo "Missing pair for sample: $base"

        continue

    fi

    echo "--------------------------------------"
    echo "Processing sample: $base"

    # Output files
    OUT1="$Trimmed_dir/${base}_trimmed_1.fastq.gz"
    OUT2="$Trimmed_dir/${base}_trimmed_2.fastq.gz"

    JSON="$Report_dir/${base}_fastp.json"
    HTML="$Report_dir/${base}_fastp.html"

    # -----------------------------
    # Run fastp
    # -----------------------------
    fastp \
        --in1 "$R1" \
        --in2 "$R2" \
        --out1 "$OUT1" \
        --out2 "$OUT2" \
        --thread 12 \
        --detect_adapter_for_pe \
        --trim_poly_g \
        --cut_front \
        --cut_tail \
        --cut_window_size 4 \
        --cut_mean_quality 20 \
        --length_required 50 \
        --json "$JSON" \
        --html "$HTML" \
        --report_title "$base fastp report"

    echo "Sample completed: $base"

done

echo "======================================"
echo " fastp trimming completed"
echo "======================================"

echo "End time: $(date)"
