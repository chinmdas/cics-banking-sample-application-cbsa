# IBM Record Generator - Quick Reference Guide

This directory contains scripts and JCL for generating Java classes from COBOL copybooks using IBM Record Generator.

## 📋 Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Complete Workflow](#complete-workflow)
4. [Script Reference](#script-reference)
5. [JCL Reference](#jcl-reference)
6. [Examples](#examples)
7. [Troubleshooting](#troubleshooting)

## Overview

The IBM Record Generator workflow consists of three main steps:

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  COBOL Copybook │ --> │   ADATA File     │ --> │   Java Class    │
│   (.cpy)        │     │   (.adata)       │     │   (.java)       │
└─────────────────┘     └──────────────────┘     └─────────────────┘
     On z/OS                 On z/OS              On MacBook/Local
```

## Prerequisites

### On z/OS
- Enterprise COBOL compiler (V6.4.0 or higher)
- COBOL copybooks in a PDS (e.g., `HLQ.CBSA.DSECT`)
- ADATA output PDS (e.g., `HLQ.CBSA.ADATA`)

### On Local Machine (MacBook)
- Java 8 or higher
- IBM Record Generator V3.0.3 or higher
- Zowe CLI (recommended) or FTP access to z/OS

## Complete Workflow

### Option 1: Automated (Recommended)

Use the all-in-one script that downloads ADATA files and generates Java classes:

```bash
./download_and_generate_java.sh \
  --zos-hlq IN0050 \
  --output-dir src/webui/src/main/java/com/ibm/cics/cip/bankliberty/datainterfaces \
  --package com.ibm.cics.cip.bankliberty.datainterfaces
```

### Option 2: Manual Steps

#### Step 1: Generate ADATA Files on z/OS

**For a single copybook:**
```bash
# Submit CUSTOMER_ADATA.jcl
# Output: HLQ.CBSA.ADATA(CUSTOMER)
```

**For all copybooks:**
```bash
# Submit GENERATE_ALL_ADATA.jcl
# Output: HLQ.CBSA.ADATA(*)
```

#### Step 2: Download ADATA Files

```bash
# Create local directory
mkdir -p adatas

# Using Zowe CLI
zowe files download all-members "HLQ.CBSA.ADATA" \
  --binary \
  --directory adatas \
  --extension adata
```

#### Step 3: Generate Java Classes

```bash
./generate_all_java_classes.sh \
  adatas \
  src/webui/src/main/java/com/ibm/cics/cip/bankliberty/datainterfaces
```

## Script Reference

### download_and_generate_java.sh

Complete workflow script that downloads ADATA files from z/OS and generates Java classes.

**Required Parameters:**
- `--zos-hlq <hlq>` - z/OS High Level Qualifier (e.g., IN0050)
  - OR `--zos-dataset <dataset>` - Full dataset name (e.g., USER123.PROJECT.ADATA)
- `--output-dir <dir>` - Java output directory
- `--package <package>` - Java package name

**Optional Parameters:**
- `--use-ftp` - Use FTP instead of Zowe CLI
- `--ftp-host <host>` - FTP hostname (required with --use-ftp)
- `--ftp-user <user>` - FTP username (required with --use-ftp)

**Examples:**

```bash
# Using HLQ (will use HLQ.CBSA.ADATA)
./download_and_generate_java.sh \
  --zos-hlq IN0050 \
  --output-dir src/webui/src/main/java/com/ibm/cics/cip/bankliberty/datainterfaces \
  --package com.ibm.cics.cip.bankliberty.datainterfaces

# Using full dataset name
./download_and_generate_java.sh \
  --zos-dataset USER123.PROJECT.ADATA \
  --output-dir src/generated/java \
  --package com.example.generated

# Using FTP
./download_and_generate_java.sh \
  --zos-hlq IN0050 \
  --use-ftp \
  --ftp-host zos.example.com \
  --ftp-user IN0050 \
  --output-dir src/webui/src/main/java/com/ibm/cics/cip/bankliberty/datainterfaces \
  --package com.ibm.cics.cip.bankliberty.datainterfaces
```

### generate_all_java_classes.sh

Batch processes local ADATA files to generate Java classes.

**Usage:**
```bash
./generate_all_java_classes.sh <adata_directory> <output_directory>
```

**Example:**
```bash
./generate_all_java_classes.sh \
  ~/Downloads/adata \
  src/webui/src/main/java/com/ibm/cics/cip/bankliberty/datainterfaces
```

**Features:**
- ✅ Processes all `.adata` files in directory
- ✅ Interactive prompts for overwriting existing files
- ✅ Color-coded progress output
- ✅ Error handling with detailed logs
- ✅ Summary report at completion

## JCL Reference

### ALLOCATE_ADATA_PDS.jcl

Allocates the ADATA PDS on z/OS (one-time setup).

**Dataset:** `HLQ.CBSA.ADATA`

**Attributes:**
- RECFM=VB (Variable Blocked)
- LRECL=32756
- BLKSIZE=32760
- 50 directory blocks

**Submit once before generating ADATA files.**

### CUSTOMER_ADATA.jcl

Generates ADATA file for a single copybook (CUSTOMER).

**Input:** `HLQ.CBSA.DSECT(CUSTOMER)`  
**Output:** `HLQ.CBSA.ADATA(CUSTOMER)`

### GENERATE_ALL_ADATA.jcl

Generates ADATA files for all copybooks in the PDS.

**Input:** `HLQ.CBSA.DSECT(*)`  
**Output:** `HLQ.CBSA.ADATA(*)`

Uses a PROC to process each copybook member.

### GENERATE_MULTIPLE_ADATA.jcl

Generates ADATA files for specific copybooks (separate steps).

**Example copybooks:** CUSTOMER, ACCOUNT, PROCTRAN

## Examples

### Example 1: Generate Java Class for CUSTOMER Copybook

```bash
# 1. On z/OS: Submit CUSTOMER_ADATA.jcl
#    Creates: IN0050.CBSA.ADATA(CUSTOMER)

# 2. On MacBook: Download and generate
./download_and_generate_java.sh \
  --zos-hlq IN0050 \
  --output-dir src/webui/src/main/java/com/ibm/cics/cip/bankliberty/datainterfaces \
  --package com.ibm.cics.cip.bankliberty.datainterfaces

# Result: CUSTOMER.java created with proper field mappings
```

### Example 2: Generate Java Classes for All Copybooks

```bash
# 1. On z/OS: Submit GENERATE_ALL_ADATA.jcl
#    Creates: IN0050.CBSA.ADATA(*)

# 2. On MacBook: Download and generate all
./download_and_generate_java.sh \
  --zos-hlq IN0050 \
  --output-dir src/webui/src/main/java/com/ibm/cics/cip/bankliberty/datainterfaces \
  --package com.ibm.cics.cip.bankliberty.datainterfaces

# Result: All Java classes generated
```

### Example 3: Using Different HLQ

```bash
# For a different user/project
./download_and_generate_java.sh \
  --zos-hlq USER123 \
  --output-dir src/generated/java \
  --package com.mycompany.generated
```

### Example 4: Using Custom Dataset Name

```bash
# For non-standard dataset naming
./download_and_generate_java.sh \
  --zos-dataset MYPROJ.COBOL.ADATA \
  --output-dir src/generated/java \
  --package com.mycompany.generated
```

## Troubleshooting

### Issue: ADATA Dataset Not Found

**Error:** `IEFA107I ... DATA SET HLQ.CBSA.ADATA NOT FOUND`

**Solution:**
```bash
# Submit ALLOCATE_ADATA_PDS.jcl first
# Then retry ADATA generation
```

### Issue: Zowe CLI Not Found

**Error:** `Zowe CLI not found`

**Solution:**
```bash
# Option 1: Install Zowe CLI
npm install -g @zowe/cli

# Option 2: Use FTP instead
./download_and_generate_java.sh \
  --use-ftp \
  --ftp-host zos.example.com \
  --ftp-user YOUR_USER \
  ...
```

### Issue: Record Generator Not Found

**Error:** `IBM Record Generator not found`

**Solution:**
```bash
# Set RECORD_GEN_HOME environment variable
export RECORD_GEN_HOME=/Applications/IBM/RecordGenerator

# Or specify full path in script
```

### Issue: Java Class Generation Failed

**Error:** `Failed to generate Java class (RC=1)`

**Solution:**
```bash
# Check log file
cat /tmp/recordgen_COPYBOOK.log

# Common issues:
# - Missing 01-level in copybook
# - Invalid ADATA file format
# - Unsupported COBOL syntax
```

### Issue: Wrong Dataset Name

**Error:** Dataset name doesn't follow HLQ.CBSA.ADATA pattern

**Solution:**
```bash
# Use --zos-dataset instead of --zos-hlq
./download_and_generate_java.sh \
  --zos-dataset YOUR.CUSTOM.DATASET \
  --output-dir ... \
  --package ...
```

## Environment Variables

### RECORD_GEN_HOME

Location of IBM Record Generator installation.

**Default:** `/Applications/IBM/RecordGenerator`

**Set custom location:**
```bash
export RECORD_GEN_HOME=/path/to/RecordGenerator
```

## File Locations

```
etc/install/base/buildjcl/
├── README_RECORD_GENERATOR.md          # This file
├── download_and_generate_java.sh       # Complete workflow script
├── generate_all_java_classes.sh        # Batch Java generation
├── ALLOCATE_ADATA_PDS.jcl             # Allocate ADATA PDS
├── CUSTOMER_ADATA.jcl                 # Single copybook ADATA
├── GENERATE_ALL_ADATA.jcl             # All copybooks ADATA
├── GENERATE_MULTIPLE_ADATA.jcl        # Multiple copybooks ADATA
└── GENALLJCL.rexx                     # Dynamic JCL generator
```

## Additional Resources

- [IBM Record Generator Documentation](https://www.ibm.com/docs/en/record-generator/3.0.0)
- [RECORD_GENERATOR_GUIDE.md](../../../../RECORD_GENERATOR_GUIDE.md) - Detailed guide
- [Scenario Files](../../../../scenarios/) - Learning scenarios

## Quick Command Reference

```bash
# Make scripts executable
chmod +x *.sh

# Download and generate (Zowe CLI)
./download_and_generate_java.sh --zos-hlq HLQ --output-dir DIR --package PKG

# Download and generate (FTP)
./download_and_generate_java.sh --zos-hlq HLQ --use-ftp --ftp-host HOST --ftp-user USER --output-dir DIR --package PKG

# Generate from local ADATA files
./generate_all_java_classes.sh ADATA_DIR OUTPUT_DIR

# Get help
./download_and_generate_java.sh --help
```

---

**Last Updated:** March 2026  
**Version:** 1.0