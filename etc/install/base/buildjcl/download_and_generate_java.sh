#!/bin/bash
################################################################################
# download_and_generate_java.sh
#
# Complete workflow to download ADATA files from z/OS and generate Java classes
#
# This script performs:
# 1. Creates local "adatas" directory
# 2. Downloads all ADATA files from z/OS PDS (IN0050.CBSA.ADATA)
# 3. Runs IBM Record Generator on each ADATA file
# 4. Generates Java classes in the specified output directory
#
# Prerequisites:
# - If running on USS: Direct access to z/OS datasets
# - If running on MacBook: Zowe CLI or FTP access to z/OS
# - IBM Record Generator installed
# - Java 8+ available
#
# Usage:
#   ./download_and_generate_java.sh --zos-qualifier <qualifier> --output-dir <dir> [options]
#
# Required:
#   --zos-qualifier <qualifier>  z/OS dataset qualifier (script appends .ADATA)
#                                Example: IN0050.CBSA → IN0050.CBSA.ADATA
#   --output-dir <dir>           Directory where generated Java files will be created
#
# Optional:
#   --java-package <package>     Java package name for generated classes
#                                (default: com.ibm.cics.cip.bankliberty.datainterfaces)
#   --use-zowe                   Use Zowe CLI (for MacBook)
#   --use-ftp                    Use FTP (for MacBook)
#   --ftp-host <host>            FTP hostname (required with --use-ftp)
#   --ftp-user <user>            FTP username (required with --use-ftp)
#
# Default Behavior:
#   - Detects if running on USS (z/OS) by checking for //'dataset' syntax support
#   - If on USS: Uses USS cp command (fastest, no network transfer)
#   - If not on USS: Prompts user to choose between Zowe CLI or FTP
#
# Example 1: Running on USS (default - uses cp command)
#   ./download_and_generate_java.sh \
#     --zos-qualifier IN0050.CBSA \
#     --output-dir src/webui/src/main/java
#
# Example 2: Running on MacBook with Zowe CLI
#   ./download_and_generate_java.sh \
#     --zos-qualifier IN0050.CBSA \
#     --output-dir src/webui/src/main/java \
#     --use-zowe
#
# Example 3: Running on MacBook with FTP
#   ./download_and_generate_java.sh \
#     --zos-qualifier IN0050.CBSA \
#     --output-dir src/webui/src/main/java \
#     --use-ftp \
#     --ftp-host zos.example.com \
#     --ftp-user IN0050
################################################################################

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Default configuration
ZOS_QUALIFIER=""
OUTPUT_DIR=""
JAVA_PACKAGE=""  # Will use default if not provided
ADATA_LOCAL_DIR="./adatas"
DOWNLOAD_METHOD=""  # Will be auto-detected or set by user
USE_ZOWE=false
USE_FTP=false
FTP_HOST=""
FTP_USER=""

# IBM Record Generator JAR paths
# For USS (z/OS): Hardcoded paths
# For MacBook: Can be overridden with RECORD_GEN_HOME environment variable
if [ -f "/u/in0050/ibm-record-generator/ibm-recgen/ibm-recgen.jar" ]; then
    # Running on USS - use hardcoded paths
    RECORD_GEN_JAR="/u/in0050/ibm-record-generator/ibm-recgen/ibm-recgen.jar"
    JZOS_JAR="/u/in0050/ibm-record-generator/ibm-jzos/ibm.jzos.jar"
    CLASSPATH="${RECORD_GEN_JAR}:${JZOS_JAR}"
else
    # Running on MacBook - use RECORD_GEN_HOME
    RECORD_GEN_HOME="${RECORD_GEN_HOME:-/Applications/IBM/RecordGenerator}"
    RECORD_GEN_JAR="${RECORD_GEN_HOME}/lib/RecordGenerator.jar"
    CLASSPATH="${RECORD_GEN_JAR}"
fi

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --zos-qualifier)
            ZOS_QUALIFIER="$2"
            shift 2
            ;;
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --java-package)
            JAVA_PACKAGE="$2"
            shift 2
            ;;
        --use-zowe)
            USE_ZOWE=true
            DOWNLOAD_METHOD="zowe"
            shift
            ;;
        --use-ftp)
            USE_FTP=true
            DOWNLOAD_METHOD="ftp"
            shift
            ;;
        --ftp-host)
            FTP_HOST="$2"
            shift 2
            ;;
        --ftp-user)
            FTP_USER="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 --zos-qualifier <qualifier> --output-dir <dir> [options]"
            echo ""
            echo "Required:"
            echo "  --zos-qualifier <qualifier>  z/OS dataset qualifier (e.g., IN0050.CBSA)"
            echo "                               Script automatically appends .ADATA"
            echo "  --output-dir <dir>           Directory where Java files will be generated"
            echo ""
            echo "Optional:"
            echo "  --java-package <package>     Java package name for generated classes"
            echo "                               (default: com.ibm.cics.cip.bankliberty.datainterfaces)"
            echo "  --use-zowe                   Use Zowe CLI (for MacBook)"
            echo "  --use-ftp                    Use FTP (for MacBook)"
            echo "  --ftp-host <host>            FTP hostname (required with --use-ftp)"
            echo "  --ftp-user <user>            FTP username (required with --use-ftp)"
            echo ""
            echo "Default Behavior:"
            echo "  - Auto-detects if running on USS (z/OS)"
            echo "  - If on USS: Uses USS cp command (fastest)"
            echo "  - If not on USS: Prompts to choose Zowe CLI or FTP"
            echo ""
            echo "Examples:"
            echo "  # Running on USS (auto-detects, uses cp)"
            echo "  $0 --zos-qualifier IN0050.CBSA \\"
            echo "     --output-dir src/webui/src/main/java"
            echo ""
            echo "  # Running on MacBook with Zowe CLI"
            echo "  $0 --zos-qualifier IN0050.CBSA \\"
            echo "     --output-dir src/webui/src/main/java \\"
            echo "     --use-zowe"
            echo ""
            echo "  # Running on MacBook with FTP"
            echo "  $0 --zos-qualifier IN0050.CBSA \\"
            echo "     --output-dir src/webui/src/main/java \\"
            echo "     --use-ftp \\"
            echo "     --ftp-host zos.example.com \\"
            echo "     --ftp-user IN0050"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Validate required parameters
if [ -z "$ZOS_QUALIFIER" ]; then
    echo -e "${RED}Error: --zos-qualifier is required${NC}"
    echo ""
    echo "Usage: $0 --zos-qualifier <qualifier> --output-dir <dir>"
    echo "Example: $0 --zos-qualifier IN0050.CBSA --output-dir src/webui/src/main/java"
    echo ""
    echo "Use --help for more information"
    exit 1
fi

if [ -z "$OUTPUT_DIR" ]; then
    echo -e "${RED}Error: --output-dir is required${NC}"
    echo ""
    echo "Usage: $0 --zos-qualifier <qualifier> --output-dir <dir>"
    echo "Example: $0 --zos-qualifier IN0050.CBSA --output-dir src/webui/src/main/java"
    echo ""
    echo "Use --help for more information"
    exit 1
fi

# Build full ADATA dataset name by appending .ADATA
ZOS_ADATA_DATASET="${ZOS_QUALIFIER}.ADATA"

# Set default Java package if not provided
if [ -z "$JAVA_PACKAGE" ]; then
    JAVA_PACKAGE="com.ibm.cics.generated.records"
fi

################################################################################
# Auto-detect environment and determine download method
################################################################################
if [ -z "$DOWNLOAD_METHOD" ]; then
    # Try to detect if we're on USS by checking if we can access MVS datasets
    if [ -d "/usr/lpp/cicsts" ] || [ -d "/usr/lpp/db2" ] || uname -a | grep -q "OS/390"; then
        # We're likely on USS (z/OS)
        DOWNLOAD_METHOD="uss"
        echo -e "${GREEN}✓${NC}  Detected USS environment - will use USS cp command"
    else
        # We're not on USS - prompt user
        echo -e "${YELLOW}⚠  Not running on USS (z/OS)${NC}"
        echo ""
        echo "Please choose download method:"
        echo "  1) Zowe CLI"
        echo "  2) FTP"
        echo ""
        read -p "Enter choice (1 or 2): " -n 1 -r
        echo ""
        
        case $REPLY in
            1)
                DOWNLOAD_METHOD="zowe"
                USE_ZOWE=true
                ;;
            2)
                DOWNLOAD_METHOD="ftp"
                USE_FTP=true
                # Prompt for FTP details if not provided
                if [ -z "$FTP_HOST" ]; then
                    read -p "Enter FTP hostname: " FTP_HOST
                fi
                if [ -z "$FTP_USER" ]; then
                    read -p "Enter FTP username: " FTP_USER
                fi
                ;;
            *)
                echo -e "${RED}Invalid choice${NC}"
                exit 1
                ;;
        esac
    fi
fi

# Validate FTP parameters if FTP is used
if [ "$DOWNLOAD_METHOD" = "ftp" ]; then
    if [ -z "$FTP_HOST" ] || [ -z "$FTP_USER" ]; then
        echo -e "${RED}Error: --ftp-host and --ftp-user are required when using --use-ftp${NC}"
        exit 1
    fi
fi

# Display banner
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  IBM Record Generator - Complete Workflow                 ║${NC}"
echo -e "${CYAN}║  Download ADATA from z/OS → Generate Java Classes         ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Display configuration
echo -e "${BLUE}Configuration:${NC}"
echo -e "  z/OS Qualifier:   ${GREEN}${ZOS_QUALIFIER}${NC}"
echo -e "  ADATA Dataset:    ${GREEN}${ZOS_ADATA_DATASET}${NC}"
echo -e "  Local ADATA Dir:  ${GREEN}${ADATA_LOCAL_DIR}${NC}"
echo -e "  Java Output Dir:  ${GREEN}${OUTPUT_DIR}${NC}"
echo -e "  Java Package:     ${GREEN}${JAVA_PACKAGE}${NC}"
echo -e "  Download Method:  ${GREEN}${DOWNLOAD_METHOD^^}${NC}"
if [ "$DOWNLOAD_METHOD" = "ftp" ]; then
    echo -e "  FTP Host:         ${GREEN}${FTP_HOST}${NC}"
    echo -e "  FTP User:         ${GREEN}${FTP_USER}${NC}"
fi
echo ""

################################################################################
# Step 1: Create local ADATA directory
################################################################################
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Step 1: Creating local ADATA directory${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""

if [ -d "$ADATA_LOCAL_DIR" ]; then
    echo -e "${YELLOW}⚠  Directory already exists: ${ADATA_LOCAL_DIR}${NC}"
    read -p "Delete and recreate? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$ADATA_LOCAL_DIR"
        echo -e "${GREEN}✓${NC}  Deleted existing directory"
    else
        echo -e "${YELLOW}⚠${NC}  Using existing directory"
    fi
fi

mkdir -p "$ADATA_LOCAL_DIR"
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC}  Created directory: ${ADATA_LOCAL_DIR}"
else
    echo -e "${RED}✗${NC}  Failed to create directory"
    exit 1
fi
echo ""

################################################################################
# Step 2: Download ADATA files from z/OS
################################################################################
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Step 2: Downloading ADATA files from z/OS${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""

if [ "$DOWNLOAD_METHOD" = "uss" ]; then
    # USS cp Method (Default - fastest, no network transfer)
    echo -e "${CYAN}Using USS cp command to copy files from ${ZOS_ADATA_DATASET}...${NC}"
    echo ""
    
    # Get list of members in the PDS
    echo -e "${CYAN}Listing members in ${ZOS_ADATA_DATASET}...${NC}"
    
    # Use TSO LISTDS command to get member list
    MEMBER_LIST=$(tsocmd "LISTDS '${ZOS_ADATA_DATASET}' MEMBERS" 2>/dev/null | grep -v "^--" | grep -v "^$" | tail -n +2 | awk '{print $1}')
    
    if [ -z "$MEMBER_LIST" ]; then
        echo -e "${RED}✗${NC}  Failed to list members or dataset is empty"
        exit 1
    fi
    
    # Count members
    MEMBER_COUNT=$(echo "$MEMBER_LIST" | wc -l | tr -d ' ')
    echo -e "${GREEN}✓${NC}  Found ${GREEN}${MEMBER_COUNT}${NC} member(s)"
    echo ""
    
    # Copy each member
    SUCCESS_COUNT=0
    FAIL_COUNT=0
    
    for MEMBER in $MEMBER_LIST; do
        echo -e "${CYAN}Copying:${NC} ${MEMBER}"
        
        # Use USS cp command to copy PDS member to USS file
        cp "//'${ZOS_ADATA_DATASET}(${MEMBER})'" "${ADATA_LOCAL_DIR}/${MEMBER}.adata" 2>/dev/null
        
        if [ $? -eq 0 ] && [ -f "${ADATA_LOCAL_DIR}/${MEMBER}.adata" ]; then
            echo -e "  ${GREEN}✓${NC}  Copied to ${MEMBER}.adata"
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        else
            echo -e "  ${RED}✗${NC}  Failed to copy ${MEMBER}"
            FAIL_COUNT=$((FAIL_COUNT + 1))
        fi
    done
    
    echo ""
    echo -e "${GREEN}✓${NC}  Copied ${GREEN}${SUCCESS_COUNT}${NC} file(s)"
    
    if [ $FAIL_COUNT -gt 0 ]; then
        echo -e "${YELLOW}⚠${NC}  Failed to copy ${FAIL_COUNT} file(s)"
    fi
    
    if [ $SUCCESS_COUNT -eq 0 ]; then
        echo -e "${RED}✗${NC}  No files copied successfully"
        exit 1
    fi

elif [ "$DOWNLOAD_METHOD" = "ftp" ]; then
    # FTP Method
    echo -e "${CYAN}Using FTP to download files from ${ZOS_ADATA_DATASET}...${NC}"
    
    # Prompt for password
    read -sp "Enter FTP password for ${FTP_USER}: " FTP_PASS
    echo ""
    
    # Create FTP script
    FTP_SCRIPT=$(mktemp)
    cat > "$FTP_SCRIPT" <<EOF
user ${FTP_USER} ${FTP_PASS}
binary
cd '${ZOS_ADATA_DATASET}'
mget *
bye
EOF
    
    # Execute FTP
    cd "$ADATA_LOCAL_DIR"
    ftp -n "$FTP_HOST" < "$FTP_SCRIPT"
    FTP_RC=$?
    cd - > /dev/null
    
    # Cleanup
    rm -f "$FTP_SCRIPT"
    
    if [ $FTP_RC -ne 0 ]; then
        echo -e "${RED}✗${NC}  FTP download failed"
        exit 1
    fi
    
elif [ "$DOWNLOAD_METHOD" = "zowe" ]; then
    # Zowe CLI Method
    echo -e "${CYAN}Using Zowe CLI to download files...${NC}"
    
    # Check if Zowe CLI is installed
    if ! command -v zowe &> /dev/null; then
        echo -e "${RED}✗${NC}  Zowe CLI not found. Install it or use --use-ftp option"
        exit 1
    fi
    
    # Download all members
    zowe files download all-members "${ZOS_ADATA_DATASET}" \
        --binary \
        --directory "${ADATA_LOCAL_DIR}" \
        --extension "adata"
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}✗${NC}  Zowe download failed"
        exit 1
    fi
fi

# Count downloaded files
ADATA_COUNT=$(find "$ADATA_LOCAL_DIR" -type f -name "*.adata" 2>/dev/null | wc -l | tr -d ' ')
if [ "$ADATA_COUNT" -eq 0 ]; then
    echo -e "${RED}✗${NC}  No ADATA files downloaded"
    exit 1
fi

echo -e "${GREEN}✓${NC}  Downloaded ${GREEN}${ADATA_COUNT}${NC} ADATA file(s)"
echo ""

################################################################################
# Step 3: Generate Java classes using IBM Record Generator
################################################################################
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Step 3: Generating Java classes${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""

# Validate Record Generator
if [ ! -f "$RECORD_GEN_JAR" ]; then
    echo -e "${RED}✗${NC}  IBM Record Generator not found at: ${RECORD_GEN_JAR}"
    echo ""
    if [ -d "/usr/lpp/cicsts" ] || [ -d "/usr/lpp/db2" ]; then
        echo "Expected USS paths:"
        echo "  ibm-recgen.jar: /u/in0050/ibm-record-generator/ibm-recgen.jar"
        echo "  ibm.jzos.jar:   /u/in0050/ibm-record-generator/ibm-jzos/ibm.jzos.jar"
    else
        echo "Please set RECORD_GEN_HOME environment variable:"
        echo "  export RECORD_GEN_HOME=/path/to/RecordGenerator"
    fi
    exit 1
fi

# Check Java
if ! command -v java &> /dev/null; then
    echo -e "${RED}✗${NC}  Java not found. Please install Java 8 or higher."
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Process each ADATA file
SUCCESS_COUNT=0
FAIL_COUNT=0

for ADATA_FILE in "$ADATA_LOCAL_DIR"/*.adata; do
    BASENAME=$(basename "$ADATA_FILE" .adata)
    OUTPUT_FILE="${OUTPUT_DIR}/${BASENAME}.java"
    
    echo -e "${CYAN}Processing:${NC} ${BASENAME}"
    
    # Run RecordClassGenerator
    # IBM Record Generator V3.0.3 uses name=value syntax
    java -cp "$CLASSPATH" \
        com.ibm.recordgen.cobol.RecordClassGenerator \
        adatafile="$ADATA_FILE" \
        package="$JAVA_PACKAGE" \
        class="$BASENAME" \
        outputdir="$OUTPUT_DIR" \
        > "/tmp/recordgen_${BASENAME}.log" 2>&1
    
    RC=$?
    
    if [ $RC -eq 0 ] && [ -f "$OUTPUT_FILE" ]; then
        echo -e "  ${GREEN}✓${NC}  Generated: ${BASENAME}.java"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        echo -e "  ${RED}✗${NC}  Failed (RC=${RC})"
        echo -e "  ${RED}✗${NC}  Log: /tmp/recordgen_${BASENAME}.log"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        
        # Show error details
        if [ -f "/tmp/recordgen_${BASENAME}.log" ]; then
            echo -e "  ${RED}Error:${NC}"
            head -n 3 "/tmp/recordgen_${BASENAME}.log" | sed 's/^/    /'
        fi
    fi
    echo ""
done

################################################################################
# Summary
################################################################################
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Summary${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  Downloaded ADATA files:   ${GREEN}${ADATA_COUNT}${NC}"
echo -e "  Successfully generated:   ${GREEN}${SUCCESS_COUNT}${NC}"
echo -e "  Failed:                   ${RED}${FAIL_COUNT}${NC}"
echo ""

if [ $FAIL_COUNT -gt 0 ]; then
    echo -e "${YELLOW}⚠  Some files failed to generate${NC}"
    echo -e "   Check log files in /tmp/recordgen_*.log"
    echo ""
    exit 1
fi

if [ $SUCCESS_COUNT -gt 0 ]; then
    echo -e "${GREEN}✓  All Java classes generated successfully!${NC}"
    echo ""
    echo -e "  ADATA files:  ${GREEN}${ADATA_LOCAL_DIR}${NC}"
    echo -e "  Java classes: ${GREEN}${OUTPUT_DIR}${NC}"
    echo ""
fi

exit 0

# Made with Bob
