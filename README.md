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

Move to the Scripts directory

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

# STEP 3 - Read Preprocessing and Trimming

Read trimming and filtering were performed using:


- [fastp](https://github.com/OpenGene/fastp?utm_source=chatgpt.com)

fastp was selected due to its:

- high speed,
- integrated quality control,
- automatic adapter detection,
- and widespread adoption in modern RNA-seq workflows.

## Running Fastp

Move to the Scripts directory

```bash
cd /path/to/AcaciaSenegal-RefTrans/Scripts
```

Open nano text editor

```bash
nano fastp_trim.sh
```
save the following sbatch script

```bash
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
```

Run the script 
[Access fatsp_trim.sh](/Scripts/fastp_trim.sh)

```bash
sbash fastp_trim.sh
```

## Quality Control of Trim Reads

### Running FastQC

Move to the created directory

```bash
cd /path/to/AcaciaSenegal-RefTrans/Scripts
```

Open nano text editor

```bash
nano FastQC_Trim.sh
```
save the following sbatch script

```bash
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

```

Run the script 
[Access FastqQC_Trim.sh](/Scripts/FastQC_Trim.sh)

```bash
sbash FastQC_Trim.sh
```

At the end of the task, check the contents

```bash
ls -lh /path/to/AcaciaSenegal-RefTrans/Results/QC/FastQC_Trim/
```

Use generated html files to check read quality


### MultiQC

Run MultiQC analysis on fastqc html files

Open the nano text editor to edit a sbatch script

```bash
nano MultiQC_Trim.sh
```

save the following sbatch script

```bash
#!/bin/bash
#------ Slurm configuration ------
#SBATCH --job-name=multiqc_trim
#SBATCH --partition=normal
#SBATCH --cpus-per-task=12
#SBATCH --mem=8G
#SBATCH --time=02:00:00
#SBATCH --output=/scratch/name/AcaciaSenegal-RefTrans/logs/multiqc_trim_%j.out
#SBATCH --error=/scratch/name/AcaciaSenegal-RefTrans/logs/multiqc_trim_%j.err
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

Fastqc_dir="/scratch/name/AcaciaSenegal-RefTrans/Results/QC/FastQC_Trim"
Multiqc_out="/scratch/name/AcaciaSenegal-RefTrans/Results/QC/MultiQC_Trim"
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
```

Run the script
[Access MultiQC_Trim.sh](/Scripts/MultiQC_Trim.sh)

```bash
sbash MultiQC_Trim.sh
```

At the end of the task, check the contents

```bash
ls -lh /path/to/AcaciaSenegal-RefTrans/Results/QC/MultiQC_Trim/
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

# STEP 5 - <em>De Novo</em> Transcriptome Assembly

## Overview

Since no reference transcriptome is currently available for <em>Acacia senegal</em>, a <em>de novo</em> transcriptome assembly strategy was employed to reconstruct transcript sequences directly from Illumina RNA-seq reads.

<em>De novo</em> assembly enables:

- transcript reconstruction,
- gene discovery,
- identification of splice variants,
- and downstream functional genomics analyses in non-model organisms.

For this study, transcriptome assembly was performed using:

- [Trinity](https://github.com/trinityrnaseq/trinityrnaseq/wiki?utm_source=chatgpt.com)

Trinity is one of the most widely used and validated tools for de novo transcriptome assembly from Illumina RNA-seq data and is extensively cited in transcriptomics studies involving non-model plant species.

## Trinity Assembly Strategy

The assembly was conducted using paired-end trimmed reads generated after quality filtering and adapter removal.

Input files:

```bash
data/trimmed/Acacia_R1_trimmed.fastq.gz
data/trimmed/Acacia_R2_trimmed.fastq.gz
```
## Creating the Assembly Directory

```bash
mkdir -p results/Assembly/Trinity
```
## Running Trinity

Create trinity_env to resolve Trinity module default 


Open the nano text editor to edit a sbatch script

```bash
nano install_trinity.sh
```

save the following sbatch script

```bash
#!/bin/bash
#------ Slurm configuration ------
#SBATCH --job-name=install_trinity
#SBATCH --partition=normal
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=12:00:00
#SBATCH --output=/scratch/name/AcaciaSenegal-RefTrans/logs/install_trinity_%j.out
#SBATCH --error=/scratch/name/AcaciaSenegal-RefTrans/logs/install_trinity_%j.err
#SBATCH --nodelist=node06

set -euo pipefail

echo "======================================"
echo " Trinity environment installation"
echo "======================================"

echo "Job started: $(date)"

# -----------------------------
# Variables
# -----------------------------
MINIFORGE_DIR="$HOME/miniforge3"
ENV_NAME="trinity_env"

PROJECT_DIR="/scratch/name/AcaciaSenegal-RefTrans"
LOG_DIR="$PROJECT_DIR/logs"

# -----------------------------
# Create log directory
# -----------------------------
mkdir -p "$LOG_DIR"

# -----------------------------
# Check Miniforge installation
# -----------------------------
if [[ ! -d "$MINIFORGE_DIR" ]]; then

    echo "ERROR: Miniforge directory not found:"
    echo "$MINIFORGE_DIR"

    exit 1

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
# Configure channels
# -----------------------------
echo "Configuring conda channels..."

conda config --remove-key channels 2>/dev/null || true

conda config --add channels conda-forge
conda config --add channels bioconda
conda config --add channels defaults

conda config --set channel_priority strict

# -----------------------------
# Create Trinity environment
# -----------------------------
if conda env list | grep -qE "^${ENV_NAME}[[:space:]]"; then

    echo "Environment $ENV_NAME already exists."

else

    echo "Creating Trinity environment..."

    conda create \
        -n "$ENV_NAME" \
        -c conda-forge \
        -c bioconda \
        python=3.10 \
        trinity \
        salmon \
        bowtie2 \
        samtools \
        jellyfish \
        fastqc \
        multiqc \
        pigz \
        -y

fi

# -----------------------------
# Test Trinity installation
# -----------------------------
echo "Checking Trinity installation..."

conda activate "$ENV_NAME"

Trinity --version

conda deactivate

# -----------------------------
# Create TMP directory
# -----------------------------
mkdir -p /scratch/name/tmp

echo "======================================"
echo " Trinity installation completed"
echo "======================================"

echo "Job finished: $(date)"
```

Run the script
[Access install_trinity.sh](/Scripts/install_trinity.sh)

```bash
sbash install_trinity.sh
```

Open the nano text editor to edit a sbatch script

```bash
nano Trinity.sh
```

save the following sbatch script

```bash
#!/bin/bash
#------ Slurm configuration ------
#SBATCH --job-name=trinity_denovo
#SBATCH --partition=normal
#SBATCH --cpus-per-task=16
#SBATCH --mem=120G
#SBATCH --time=5-00:00:00
#SBATCH --output=/scratch/name/AcaciaSenegal-RefTrans/logs/trinity_%j.out
#SBATCH --error=/scratch/name/AcaciaSenegal-RefTrans/logs/trinity_%j.err
#SBATCH --nodelist=node06

set -euo pipefail

echo "======================================"
echo " Trinity de novo assembly started"
echo "======================================"

echo "Start time: $(date)"

# -----------------------------
# Variables
# -----------------------------
MINIFORGE_DIR="$HOME/miniforge3"
ENV_NAME="trinity_env"

PROJECT_DIR="/scratch/name/AcaciaSenegal-RefTrans"

Trimmed_dir="$PROJECT_DIR/Data/Trimmed"

Output_dir="$PROJECT_DIR/Results/Assembly/Trinity"

Log_dir="$PROJECT_DIR/logs"

TMP_DIR="/scratch/name/tmp/trinity_${SLURM_JOB_ID}"

# -----------------------------
# Create directories
# -----------------------------
mkdir -p \
    "$Output_dir" \
    "$Log_dir" \
    "$TMP_DIR"

# -----------------------------
# Export temporary directory
# -----------------------------
export TMPDIR="$TMP_DIR"

echo "Temporary directory:"
echo "$TMP_DIR"

# -----------------------------
# Load conda
# -----------------------------
source "$MINIFORGE_DIR/etc/profile.d/conda.sh"

# -----------------------------
# Check Trinity environment
# -----------------------------
if ! conda env list | grep -qE "^${ENV_NAME}[[:space:]]"; then

    echo "ERROR: Conda environment '$ENV_NAME' not found."

    exit 1

fi

# -----------------------------
# Activate Trinity environment
# -----------------------------
conda activate "$ENV_NAME"

echo "Using Trinity version:"
Trinity --version

# -----------------------------
# Check trimmed reads directory
# -----------------------------
if [[ ! -d "$Trimmed_dir" ]]; then

    echo "ERROR: Trimmed reads directory not found:"
    echo "$Trimmed_dir"

    exit 1

fi

# -----------------------------
# Prepare paired-end reads
# -----------------------------
LEFT_READS=$(ls "$Trimmed_dir"/*_trimmed_1.fastq.gz | tr '\n' ',' | sed 's/,$//')

RIGHT_READS=$(ls "$Trimmed_dir"/*_trimmed_2.fastq.gz | tr '\n' ',' | sed 's/,$//')

# -----------------------------
# Check reads existence
# -----------------------------
if [[ -z "$LEFT_READS" || -z "$RIGHT_READS" ]]; then

    echo "ERROR: No paired trimmed reads found."

    exit 1

fi

echo "--------------------------------------"
echo "Left reads:"
echo "$LEFT_READS"

echo "--------------------------------------"
echo "Right reads:"
echo "$RIGHT_READS"

# -----------------------------
# Trinity assembly
# -----------------------------
echo "--------------------------------------"
echo "Running Trinity assembly..."
echo "--------------------------------------"

Trinity \
    --seqType fq \
    --max_memory 100G \
    --left "$LEFT_READS" \
    --right "$RIGHT_READS" \
    --CPU 16 \
    --min_contig_length 300 \
    --output "$Output_dir" \
    --full_cleanup \
    --verbose

# -----------------------------
# Check final assembly
# -----------------------------
FINAL_FASTA="${Output_dir}.Trinity.fasta"

if [[ -f "$FINAL_FASTA" ]]; then

    echo "--------------------------------------"
    echo " Trinity assembly completed successfully"
    echo "Final assembly:"
    echo "$FINAL_FASTA"

else

    echo "ERROR: Trinity assembly failed."

    exit 1

fi

echo "======================================"
echo " Trinity de novo assembly completed"
echo "======================================"

echo "End time: $(date)"

# -----------------------------
# Cleanup temporary files
# -----------------------------
echo "Cleaning temporary directory..."

rm -rf "$TMP_DIR"

echo "Temporary files removed."
```

Run the script
[Access Trinity.sh](/Scripts/Trinity.sh)

```bash
sbash Trinity.sh
```

## Trinity assembly statistics

This step will generate statistics such as:
- total number of transcripts
- number of “genes”
- N50
- baverage length
- GC%
- longest transcript

```bash
source ~/miniforge3/etc/profile.d/conda.sh
conda activate trinity_env
TrinityStats.pl /scratch/name/AcaciaSenegal-RefTrans/Results/Assembly/Trinity.Trinity.fasta > ./Trinity_fasta_stats.txt
cat /scratch/name/AcaciaSenegal-RefTrans/Results/Assembly/Trinity_fasta_stats.txt
```
Here are the assembly statistics for Trinity

```
################################ ## Counts of transcripts, etc. ################################ Total trinity 'genes': 64469 Total trinity transcripts: 150467 Percent GC: 40.27 ######################################## Stats based on ALL transcript contigs: ######################################## Contig N10: 4547 Contig N20: 3638 Contig N30: 3081 Contig N40: 2649 Contig N50: 2280 Median contig length: 1223 Average contig: 1565.65 Total assembled bases: 235578723 ##################################################### ## Stats based on ONLY LONGEST ISOFORM per 'GENE': ##################################################### Contig N10: 4614 Contig N20: 3682 Contig N30: 3077 Contig N40: 2573 Contig N50: 2103 Median contig length: 684 Average contig: 1215.75 Total assembled bases: 78378312
```

# STEP 6 - Assembly Validation

## Experimental validation - read remapping

The goal is to realign the cleaned reads to “Trinity.Trinity.fasta” in order to evaluate:
- transcript representation,
- overall assembly quality,
- biological consistency,
- alignment rates.

Why is this scientifically important? A good transcriptome must:
- recover the majority of reads,
- achieve a high alignment rate,
- demonstrate that the reconstructed transcripts are supported by the data.

General interpretation
| Alignment rate | Interpretation |
| -------------- | -------------- |
| <70%           | poor assembly  |
| 70–80%         | acceptable     |
| 80–90%         | good           |
| >90%           | excellent      |

### Running

Open the nano text editor to edit a sbatch script

```bash
nano read_remapping.sh
```

save the following sbatch script

```bash
#!/bin/bash
#------ Slurm configuration ------
#SBATCH --job-name=trinity_remap
#SBATCH --partition=normal
#SBATCH --cpus-per-task=12
#SBATCH --mem=80G
#SBATCH --time=3-00:00:00
#SBATCH --output=/scratch/name/AcaciaSenegal-RefTrans/logs/remap_%j.out
#SBATCH --error=/scratch/name/AcaciaSenegal-RefTrans/logs/remap_%j.err
#SBATCH --nodelist=node06

set -euo pipefail

echo "======================================"
echo " Trinity read remapping started"
echo "======================================"

echo "Start time: $(date)"

# -----------------------------
# Variables
# -----------------------------
MINIFORGE_DIR="$HOME/miniforge3"
ENV_NAME="trinity_env"

PROJECT_DIR="/scratch/name/AcaciaSenegal-RefTrans"

TRIMMED_DIR="$PROJECT_DIR/Data/Trimmed"

ASSEMBLY_DIR="$PROJECT_DIR/Results/Assembly"

MAPPING_DIR="$PROJECT_DIR/Results/Read_Remapping"

LOG_DIR="$PROJECT_DIR/logs"

TMP_DIR="/scratch/name/tmp/remap_${SLURM_JOB_ID}"

ASSEMBLY_FASTA="$ASSEMBLY_DIR/Trinity.Trinity.fasta"

INDEX_PREFIX="$MAPPING_DIR/Trinity_index"

SAM_FILE="$MAPPING_DIR/Trinity_remap.sam"

BAM_FILE="$MAPPING_DIR/Trinity_remap.sorted.bam"

# -----------------------------
# Create directories
# -----------------------------
mkdir -p \
    "$MAPPING_DIR" \
    "$LOG_DIR" \
    "$TMP_DIR"

# -----------------------------
# Export temporary directory
# -----------------------------
export TMPDIR="$TMP_DIR"

echo "Temporary directory:"
echo "$TMP_DIR"

# -----------------------------
# Load conda
# -----------------------------
source "$MINIFORGE_DIR/etc/profile.d/conda.sh"

# -----------------------------
# Check Trinity environment
# -----------------------------
if ! conda env list | grep -qE "^${ENV_NAME}[[:space:]]"; then

    echo "ERROR: Conda environment '$ENV_NAME' not found."

    exit 1

fi

# -----------------------------
# Activate Trinity environment
# -----------------------------
conda activate "$ENV_NAME"

echo "Using Bowtie2 version:"
bowtie2 --version

echo "Using Samtools version:"
samtools --version | head -n 1

# -----------------------------
# Check assembly fasta
# -----------------------------
if [[ ! -f "$ASSEMBLY_FASTA" ]]; then

    echo "ERROR: Trinity assembly not found:"
    echo "$ASSEMBLY_FASTA"

    exit 1

fi

# -----------------------------
# Prepare paired-end reads
# -----------------------------
LEFT_READS=$(ls "$TRIMMED_DIR"/*_trimmed_1.fastq.gz | tr '\n' ',' | sed 's/,$//')

RIGHT_READS=$(ls "$TRIMMED_DIR"/*_trimmed_2.fastq.gz | tr '\n' ',' | sed 's/,$//')

# -----------------------------
# Check reads existence
# -----------------------------
if [[ -z "$LEFT_READS" || -z "$RIGHT_READS" ]]; then

    echo "ERROR: No paired trimmed reads found."

    exit 1

fi

echo "--------------------------------------"
echo "Left reads:"
echo "$LEFT_READS"

echo "--------------------------------------"
echo "Right reads:"
echo "$RIGHT_READS"

# -----------------------------
# Build Bowtie2 index
# -----------------------------
echo "--------------------------------------"
echo "Building Bowtie2 index..."
echo "--------------------------------------"

bowtie2-build \
    "$ASSEMBLY_FASTA" \
    "$INDEX_PREFIX"

# -----------------------------
# Read remapping
# -----------------------------
echo "--------------------------------------"
echo "Running Bowtie2 alignment..."
echo "--------------------------------------"

bowtie2 \
    -x "$INDEX_PREFIX" \
    -1 "$LEFT_READS" \
    -2 "$RIGHT_READS" \
    -S "$SAM_FILE" \
    -p 12 \
    2> "$MAPPING_DIR/bowtie2_alignment_stats.txt"

# -----------------------------
# Convert SAM to sorted BAM
# -----------------------------
echo "--------------------------------------"
echo "Converting SAM to sorted BAM..."
echo "--------------------------------------"

samtools view \
    -@ 12 \
    -bS "$SAM_FILE" | \
samtools sort \
    -@ 12 \
    -o "$BAM_FILE"

# -----------------------------
# Index BAM
# -----------------------------
echo "--------------------------------------"
echo "Indexing BAM file..."
echo "--------------------------------------"

samtools index "$BAM_FILE"

# -----------------------------
# Remove SAM file
# -----------------------------
echo "Removing SAM file..."

rm -f "$SAM_FILE"

# -----------------------------
# Final checks
# -----------------------------
if [[ -f "$BAM_FILE" ]]; then

    echo "--------------------------------------"
    echo " Read remapping completed successfully"
    echo "Final BAM:"
    echo "$BAM_FILE"

else

    echo "ERROR: BAM file was not generated."

    exit 1

fi

echo "======================================"
echo " Trinity read remapping completed"
echo "======================================"

echo "End time: $(date)"

# -----------------------------
# Cleanup temporary files
# -----------------------------
echo "Cleaning temporary directory..."

rm -rf "$TMP_DIR"

echo "Temporary files removed."

```

Run the script
[Access read_remapping.sh](/Scripts/read_remapping.sh)

```bash
sbash read_remapping.sh
```

Check output and appreciate 

```bash
cat /scratch/name/AcaciaSenegal-RefTrans/Results/Read_Remapping/bowtie2_alignment_stats.txt
```

```
68765704 reads; of these:
  68765704 (100.00%) were paired; of these:
    6343100 (9.22%) aligned concordantly 0 times
    14566317 (21.18%) aligned concordantly exactly 1 time
    47856287 (69.59%) aligned concordantly >1 times
    ----
    6343100 pairs aligned concordantly 0 times; of these:
      603201 (9.51%) aligned discordantly 1 time
    ----
    5739899 pairs aligned 0 times concordantly or discordantly; of these:
      11479798 mates make up the pairs; of these:
        2459466 (21.42%) aligned 0 times
        1231691 (10.73%) aligned exactly 1 time
        7788641 (67.85%) aligned >1 times
98.21% overall alignment rate
```

98.21% overall alignment rate
This is a very strong indicator that the transcriptome accurately represents the RNA-seq data

What this means biologically? THe assembly:
- accurately captures the expressed transcriptome
- contains the majority of biological transcripts
- is consistent with the experimental data
- provides an excellent representation of the reads

```
69.59% aligned concordantly >1 times
```
This means there has been a significant amount of multimapping. And that’s normal with Trinity.
Because a Trinity transcriptome contains:
- multiple isoforms,
- redundant transcripts,
- closely related gene families,
- partial fragments.
Therefore, this result confirms that filtering/reducing redundancy will be necessary later on.

## BUSCO Assessment of Transcriptome Completeness

### Why?

BUSCO analysis will be performed to evaluate the completeness and biological quality of the assembled Acacia senegal transcriptome using the embryophyta_odb10 plant lineage dataset.
BUSCO identifies highly conserved single-copy orthologous genes expected to be present in most plant species and classifies them as complete, duplicated, fragmented, or missing. This analysis provides an important measure of transcriptome completeness and assembly reliability.
The BUSCO assessment serves as a key validation step before downstream analyses such as transcript filtering, coding sequence prediction, and functional annotation.

### Running

Open the nano text editor to edit a sbatch script

```bash
nano busco_assessment.sh
```

save the following sbatch script

```bash
#!/bin/bash
#------ Slurm configuration ------
#SBATCH --job-name=busco_acacia
#SBATCH --partition=normal
#SBATCH --cpus-per-task=16
#SBATCH --mem=80G
#SBATCH --time=3-00:00:00
#SBATCH --output=/scratch/name/AcaciaSenegal-RefTrans/logs/busco_%j.out
#SBATCH --error=/scratch/name/AcaciaSenegal-RefTrans/logs/busco_%j.err
#SBATCH --nodelist=node06

set -euo pipefail

echo "======================================"
echo " BUSCO transcriptome assessment started"
echo "======================================"

echo "Start time: $(date)"

# -----------------------------
# Load modules
# -----------------------------
module load bioinfo-wave
module load singularity/4.0.1
module load busco/5.5.0

# -----------------------------
# Variables
# -----------------------------
PROJECT_DIR="/scratch/name/AcaciaSenegal-RefTrans"

ASSEMBLY_DIR="$PROJECT_DIR/Results/Assembly"

BUSCO_DIR="$PROJECT_DIR/Results/BUSCO"

DATABASE_DIR="$PROJECT_DIR/Database/BUSCO"

LOG_DIR="$PROJECT_DIR/logs"

TMP_DIR="/scratch/name/tmp/busco_${SLURM_JOB_ID}"

ASSEMBLY_FASTA="$ASSEMBLY_DIR/Trinity.Trinity.fasta"

LINEAGE="embryophyta_odb10"

OUTPUT_NAME="busco_acacia"

# -----------------------------
# Create directories
# -----------------------------
mkdir -p \
    "$BUSCO_DIR" \
    "$DATABASE_DIR" \
    "$LOG_DIR" \
    "$TMP_DIR"

# -----------------------------
# Export temporary directory
# -----------------------------
export TMPDIR="$TMP_DIR"

echo "Temporary directory:"
echo "$TMP_DIR"

# -----------------------------
# Check assembly fasta
# -----------------------------
if [[ ! -f "$ASSEMBLY_FASTA" ]]; then

    echo "ERROR: Assembly fasta file not found:"
    echo "$ASSEMBLY_FASTA"

    exit 1

fi

# -----------------------------
# Display BUSCO version
# -----------------------------
echo "Using BUSCO version:"
busco --version

# -----------------------------
# Download BUSCO lineage dataset
# -----------------------------
echo "--------------------------------------"
echo "Checking BUSCO lineage dataset..."
echo "--------------------------------------"

if [[ ! -d "$DATABASE_DIR/lineages/$LINEAGE" ]]; then

    echo "Downloading BUSCO lineage dataset: $LINEAGE"

    busco \
        --download "$LINEAGE" \
        --download_path "$DATABASE_DIR"

else

    echo "BUSCO lineage dataset already exists."

fi

# -----------------------------
# Run BUSCO
# -----------------------------
echo "--------------------------------------"
echo "Running BUSCO assessment..."
echo "--------------------------------------"

busco \
    -i "$ASSEMBLY_FASTA" \
    -l "$LINEAGE" \
    -o "$OUTPUT_NAME" \
    -m transcriptome \
    -c 16 \
    --download_path "$DATABASE_DIR" \
    --out_path "$BUSCO_DIR"

# -----------------------------
# Final check
# -----------------------------
SUMMARY_FILE="$BUSCO_DIR/$OUTPUT_NAME/short_summary.specific.${LINEAGE}.${OUTPUT_NAME}.txt"

if [[ -f "$SUMMARY_FILE" ]]; then

    echo "--------------------------------------"
    echo " BUSCO assessment completed successfully"
    echo "Summary file:"
    echo "$SUMMARY_FILE"

else

    echo "ERROR: BUSCO summary file not found."

    exit 1

fi

echo "======================================"
echo " BUSCO transcriptome assessment completed"
echo "======================================"

echo "End time: $(date)"

# -----------------------------
# Cleanup temporary files
# -----------------------------
echo "Cleaning temporary directory..."

rm -rf "$TMP_DIR"

echo "Temporary files removed."

```

Run the script
[Access busco_assessment.sh](/Scripts/busco_assessment.sh)

```bash
sbash busco_assessment.sh
```




































