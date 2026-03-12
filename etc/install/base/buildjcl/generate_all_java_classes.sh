#!/bin/bash
################################################################################
# generate_all_java_classes.sh
#
# Batch process ADATA files to generate Java classes using IBM Record Generator
#
# Prerequisites:
# 1. Download all ADATA files from IN0050.CBSA.ADATA to local directory
# 2. Set RECORD_GEN_HOME to IBM Record Generator installation directory
# 3. Ensure Java 8+ is available
#
# Usage:
#   ./generate_all_java_classes.sh <adata_directory> <output_directory>
#
# Example:
#   ./generate_all_java_classes.sh ~/Downloads/adata ~/git/cbsa/src/webui/src/main/java/com/ibm/cics/cip/bankliberty/datainterfaces
################################################################################

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
RECORD_GEN_HOME="${RECORD_GEN_HOME:-/Applications/IBM/RecordGenerator}"
RECORD_GEN_JAR="${RECORD_GEN_HOME}/lib/RecordGenerator.jar"

# Check arguments
if [ $# -ne 2 ]; then
    echo -e "${RED}Error: Invalid number of arguments${NC}"
    echo ""
    echo "Usage: $0 <adata_directory> <output_directory>"
    echo ""
    echo "Example:"
    echo "  $0 ~/Downloads/adata ~/git/cbsa/src/webui/src/main/java/com/ibm/cics/cip/bankliberty/datainterfaces"
    echo ""
    exit 1
fi

ADATA_DIR="$1"
OUTPUT_DIR="$2"

# Validate directories
if [ ! -d "$ADATA_DIR" ]; then
    echo -e "${RED}Error: ADATA directory does not exist: $ADATA_DIR${NC}"
    exit 1
fi

if [ ! -d "$OUTPUT_DIR" ]; then
    echo -e "${YELLOW}Warning: Output directory does not exist. Creating: $OUTPUT_DIR${NC}"
    mkdir -p "$OUTPUT_DIR"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Could not create output directory${NC}"
        exit 1
    fi
fi

# Validate Record Generator installation
if [ ! -f "$RECORD_GEN_JAR" ]; then
    echo -e "${RED}Error: IBM Record Generator not found at: $RECORD_GEN_JAR${NC}"
    echo ""
    echo "Please set RECORD_GEN_HOME environment variable:"
    echo "  export RECORD_GEN_HOME=/path/to/RecordGenerator"
    echo ""
    exit 1
fi

# Check Java
if ! command -v java &> /dev/null; then
    echo -e "${RED}Error: Java not found. Please install Java 8 or higher.${NC}"
    exit 1
fi

JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2 | cut -d'.' -f1)
if [ "$JAVA_VERSION" -lt 8 ]; then
    echo -e "${RED}Error: Java 8 or higher required. Current version: $JAVA_VERSION${NC}"
    exit 1
fi

# Display configuration
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}IBM Record Generator - Batch Processor${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "ADATA Directory:  ${GREEN}$ADATA_DIR${NC}"
echo -e "Output Directory: ${GREEN}$OUTPUT_DIR${NC}"
echo -e "Record Generator: ${GREEN}$RECORD_GEN_JAR${NC}"
echo -e "Java Version:     ${GREEN}$(java -version 2>&1 | head -n 1)${NC}"
echo ""

# Count ADATA files
ADATA_COUNT=$(find "$ADATA_DIR" -type f -name "*.adata" 2>/dev/null | wc -l | tr -d ' ')
if [ "$ADATA_COUNT" -eq 0 ]; then
    echo -e "${RED}Error: No .adata files found in $ADATA_DIR${NC}"
    exit 1
fi

echo -e "Found ${GREEN}$ADATA_COUNT${NC} ADATA file(s)"
echo ""

# Confirm before proceeding
read -p "Proceed with generation? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Cancelled by user${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Processing ADATA Files${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Process each ADATA file
SUCCESS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

for ADATA_FILE in "$ADATA_DIR"/*.adata; do
    # Get base filename without extension
    BASENAME=$(basename "$ADATA_FILE" .adata)
    OUTPUT_FILE="${OUTPUT_DIR}/${BASENAME}.java"
    
    echo -e "${BLUE}Processing:${NC} $BASENAME"
    
    # Check if output file already exists
    if [ -f "$OUTPUT_FILE" ]; then
        echo -e "  ${YELLOW}⚠${NC}  Output file exists: $OUTPUT_FILE"
        read -p "  Overwrite? (y/n/a=all/s=skip all) " -n 1 -r
        echo ""
        
        if [[ $REPLY =~ ^[Ss]$ ]]; then
            echo -e "  ${YELLOW}⊘${NC}  Skipping all remaining files"
            SKIP_COUNT=$((ADATA_COUNT - SUCCESS_COUNT - FAIL_COUNT))
            break
        elif [[ ! $REPLY =~ ^[YyAa]$ ]]; then
            echo -e "  ${YELLOW}⊘${NC}  Skipped"
            SKIP_COUNT=$((SKIP_COUNT + 1))
            echo ""
            continue
        fi
    fi
    
    # Run RecordClassGenerator
    java -cp "$RECORD_GEN_JAR" \
        com.ibm.recordgen.RecordClassGenerator \
        adatafile="$ADATA_FILE" \
        outputdir="$OUTPUT_DIR" \
        > /tmp/recordgen_${BASENAME}.log 2>&1
    
    RC=$?
    
    if [ $RC -eq 0 ] && [ -f "$OUTPUT_FILE" ]; then
        echo -e "  ${GREEN}✓${NC}  Generated: $OUTPUT_FILE"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        echo -e "  ${RED}✗${NC}  Failed (RC=$RC)"
        echo -e "  ${RED}✗${NC}  Log: /tmp/recordgen_${BASENAME}.log"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        
        # Show first few lines of error
        if [ -f /tmp/recordgen_${BASENAME}.log ]; then
            echo -e "  ${RED}Error details:${NC}"
            head -n 5 /tmp/recordgen_${BASENAME}.log | sed 's/^/    /'
        fi
    fi
    
    echo ""
done

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "Total files:      ${BLUE}$ADATA_COUNT${NC}"
echo -e "Successfully generated: ${GREEN}$SUCCESS_COUNT${NC}"
echo -e "Failed:           ${RED}$FAIL_COUNT${NC}"
echo -e "Skipped:          ${YELLOW}$SKIP_COUNT${NC}"
echo ""

if [ $FAIL_COUNT -gt 0 ]; then
    echo -e "${YELLOW}Warning: Some files failed to generate${NC}"
    echo -e "Check log files in /tmp/recordgen_*.log for details"
    echo ""
    exit 1
fi

if [ $SUCCESS_COUNT -gt 0 ]; then
    echo -e "${GREEN}✓ All files processed successfully${NC}"
    echo ""
    echo -e "Generated Java classes are in: ${GREEN}$OUTPUT_DIR${NC}"
    echo ""
fi

exit 0

# Made with Bob
