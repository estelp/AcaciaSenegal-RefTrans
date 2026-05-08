# AcaciaSenegal-RefTrans
Comprehensive <em>de novo</em> reference transcriptome assembly and annotation pipeline for <em>Acacia senegal</em>

# Overview

<em>Acacia senegal</em> is a drought-tolerant tree species of major ecological and economic importance in arid and semi-arid regions, particularly across Africa. The species is best known as the primary natural source of gum arabic, a highly valued exudate widely used in the food, pharmaceutical, cosmetic, and industrial sectors. Beyond its commercial importance, <em>A. senegal</em> plays a critical role in ecosystem restoration, soil fertility improvement, carbon sequestration, and the resilience of agroforestry systems in drylands.
Despite its importance, genomic and transcriptomic resources for Acacia senegal remain extremely limited. In particular, no comprehensive reference transcriptome is currently available to support large-scale functional genomics, gene discovery, molecular marker development, or stress-response studies in this species.
This project aims to generate the first high-quality de novo reference transcriptome of Acacia senegal using Illumina RNA sequencing data. The resulting resource will serve as a foundational dataset for future molecular and bioinformatics investigations on this important species.

# Project Details

This repository contains the bioinformatics workflow developed for the de novo assembly, evaluation, and functional annotation of the <em>Acacia senegal</em> reference transcriptome.
The project is designed around reproducible and scalable bioinformatics practices using modern RNA-seq analysis tools and workflow management strategies. The pipeline integrates multiple analytical steps including:
- Raw RNA-seq data quality assessment
- Read preprocessing and filtering
- <em>De novo</em> transcriptome assembly
- Assembly quality evaluation
- Transcript redundancy reduction
- Functional annotation
- Transcriptome completeness assessment
- Workflow reproducibility and documentation
The workflow is intended to provide a reliable transcriptomic resource for downstream analyses such as:
- gene expression studies,
- stress-response investigations,
- comparative transcriptomics,
- candidate gene discovery,
- and molecular characterization of gum arabic biosynthesis pathways.
This repository also serves as the first phase of a broader research initiative focused on improving the molecular understanding of <em>Acacia senegal</em> through high-throughput sequencing and bioinformatics approaches.

# Objectives

## General Objective

To construct a high-quality <em>de novo</em> reference transcriptome for <em>Acacia senegal</em> using Illumina RNA-seq data.

## Specific Objectives

- Perform quality assessment and preprocessing of raw RNA-seq reads.
- Assemble the <em>Acacia senegal</em> transcriptome using <em>de novo</em> assembly strategies.
- Evaluate transcriptome assembly quality and completeness.
- Reduce transcript redundancy to improve assembly reliability.
- Functionally annotate assembled transcripts using public biological databases.
- Generate a reproducible and scalable bioinformatics workflow for transcriptome analysis.
- Establish foundational transcriptomic resources for future genomic and functional studies on <em>Acacia senegal</em>.
- Support future investigations related to gum arabic biosynthesis, stress adaptation, and molecular ecology in dryland environments.

# STEP 1 - Data Acquisition and Project Setup

## Sequencing Information

RNA sequencing was performed using the Illumina MiSeq platform with paired-end 150 bp reads (PE150) and an estimated sequencing depth of approximately 200× coverage.

## Raw RNA-seq files

```bash
- NG-32606_RNA_Acacia_lib675143_10197_1_1.fastq.gz
- NG-32606_RNA_Acacia_lib675143_10197_1_2.fastq.gz
```

## Project Directory Initialization

The project workspace was initialized on the HPC cluster using the following directory structure:

```bash
mkdir -p AcaciaSenegal-RefTrans/{Data/{raw,trimmed},results/{QC,Assembly},logs,Scripts}
```

## Data Transfer to the HPC Cluster

Raw sequencing files were transferred to the cluster and stored in the data/raw/ directory.

Example:

```bash
scp *.fastq.gz username@cluster:/path/to/AcaciaSenegal-RefTrans/data/raw/
```

# STEP 2 - Quality Control of Raw Reads

Initial quality assessment of raw RNA-seq reads was performed using:

- [FastQC](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/?utm_source=chatgpt.com)
- [MultiQC](https://multiqc.info/?utm_source=chatgpt.com)

The objective of this step is to evaluate:

- per-base sequence quality,
- GC content distribution,
- adapter contamination,
- duplicated reads,
- sequence length distribution,
- and overrepresented sequences.

## Running FastQC

Move to the created directory

```bash
cd /path/to/AcaciaSenegal-RefTrans/Scripts
```

Open nano text editor

```bash
nano FastQC_Raw.sh
```
save the following sbatch script

```bash
#!/bin/bash
#------Slurm configuration------
#SBATCH --job-name=fastqc_raw
#SBATCH --partition=normal
#SBATCH --cpus-per-task=12
#SBATCH --output=/scratch/name/AcaciaSenegal-RefTrans/logs/fastqc_raw_%j.out
#SBATCH --error=/scratch/name/AcaciaSenegal-RefTrans/logs/fastqc_raw_%j.err
#SBATCH --nodelist=node06

# Stop script if error
set -euo pipefail

# Modules loading
module load bioinfo-wave
module load FastQC/0.12.1

# Directories
Input_dir="/scratch/name/AcaciaSenegal-RefTrans/Data/Raw"
Output_dir="/scratch/name/AcaciaSenegal-RefTrans/Results/QC/FastQC_Raw"

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

```

Run the script 
[Access FastqQC_Raw.sh](/Scripts/FastQC_Raw.sh)

```bash
sbash FastQC_Raw.sh
```

At the end of the task, check the contents

```bash
ls -lh /path/to/AcaciaSenegal-RefTrans/Results/QC/FastQC_Raw/
```

Use generated html files to check read quality


## MultiQC

This step consolidates the html reports from FastQC into a single, easy-to-interpret report. To do this

Create the “MultiQC” directory in the QC directory for outputs 


```bash
mkdir -p /path/to/AcaciaSenegal-RefTrans/Results/QC/MultiQC_Raw
```

Create multiqc_env to resolve MultiQC module default 


Open the nano text editor to edit a sbatch script

```bash
nano install_multiqc.sh
```

save the following sbatch script

```bash
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

```

Run the script
[Access install_multiqc.sh](/Scripts/install_multiqc.sh)

```bash
sbash install_multiqc.sh
```
Run MultiQC analysis on fastqc html files

Open the nano text editor to edit a sbatch script

```bash
nano MultiQC_Raw.sh
```

save the following sbatch script

```bash
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
```

Run the script
[Access MultiQC_Raw.sh](/Scripts/MultiQC_Raw.sh)

```bash
sbash MultiQC_Raw.sh
```

At the end of the task, check the contents

```bash
ls -lh /path/to/AcaciaSenegal-RefTrans/Results/QC/MultiQC_Raw/
```

Use generated html files to check read quality

For the next step,
Move the entire contents of the QC directory to the NAS

```bash
scp -r /path/to/AcaciaSenegal-RefTrans/Results/QC san:/home/name/
```

Retrieve this QC directory from the NAS on your local machine to analyze the results

```bash
scp -r username@cluster:/path/to/AcaciaSenegal-RefTrans/Results/QC /path/to/working dorectory/on_your_laptop/
```





















