# CUSTOMER-TITLE Field Implementation Summary

## Overview
Successfully restructured the CUSTOMER VSAM record to make CUSTOMER-TITLE an independent 8-byte field, separate from CUSTOMER-NAME (now 52 bytes). The total record length remains 259 bytes.

## Complete Workflow: Commands and Steps

### Initial Request
**User Command:**
```
In CUSTOMER.cpy, you'll notice CUSTOMER-TITLE is part of CUSTOMER-NAME field.
I want to have CUSTOMER-TITLE as an independent record in CUSTOMER-RECORD and remove it from under CUSTOMER-NAME.
Do the code changes on both COBOL and Java side of things
```

### Phase 1: COBOL Structure Changes

#### Step 1: Modified CUSTOMER.cpy
**Action:** Updated the main CUSTOMER copybook structure
```cobol
# Before:
05 CUSTOMER-NAME           PIC X(60).

# After:
05 CUSTOMER-TITLE          PIC X(8).
05 CUSTOMER-NAME           PIC X(52).
```

#### Step 2: Updated Communication Area Copybooks
Modified the following copybooks to include CUSTOMER-TITLE:
- `CRECUST.cpy` - Added `COMM-TITLE PIC X(8)`
- `UPDCUST.cpy` - Added `COMM-TITLE PIC X(8)`
- `DELCUS.cpy` - Added `COMM-TITLE PIC X(8)`
- `INQCUST.cpy` - Added `INQCUST-TITLE PIC X(8)`
- `INQCUSTZ.cpy` - Added `INQCUST-TITLE PIC X(8)`

#### Step 3: Updated COBOL Programs
Modified programs to handle the new CUSTOMER-TITLE field:

- **`BANKDATA.cbl`** (Lines 544-555)
  - Added STRING statement to separate title from name during data population
  - Populates CUSTOMER-TITLE independently from CUSTOMER-NAME

- **`CRECUST.cbl`**
  - Added handling for COMM-TITLE field in COMMAREA
  - Stores title separately when creating new customer records

- **`UPDCUST.cbl`** (Lines 282-283, 288-289, 327-330)
  - Lines 282-283: Move COMM-TITLE to CUSTOMER-TITLE when updating name only
  - Lines 288-289: Move COMM-TITLE to CUSTOMER-TITLE when updating both address and name
  - Lines 327-330: Return updated CUSTOMER-TITLE in COMM-TITLE

- **`DELCUS.cbl`**
  - Added handling for COMM-TITLE field in COMMAREA
  - Includes title in deletion confirmation

- **`INQCUST.cbl`**
  - Added handling for INQCUST-TITLE field
  - Returns title separately in inquiry response

- **`BNK1DCS.cbl`** (Lines ~924, ~1095, ~1286, ~1950)
  - Added CUSTTITO field handling for BMS map interaction
  - Manages title input/output on customer detail screen

#### Step 4: Updated BMS Map
Modified `BNK1DCM.bms` (Line 9):
- Added CUSTTIT field for title input/display on customer detail screen

### Phase 2: Java Class Generation Using IBM Record Generator

#### Step 1: Learning About IBM Record Generator
**User Question:**
```
what is IBM Record Generator for Java?
```

**Response:** Explained that IBM Record Generator is a tool that generates Java classes from COBOL copybooks using ADATA files, which are metadata files produced by the Enterprise COBOL compiler.

#### Step 2: Creating JCL for ADATA Generation
**User Request:**
```
create a JCL that will generate ADATA file for CUSTOMER.cpy
```

**Action:** Created `etc/install/base/buildjcl/CUSTOMER_ADATA.jcl`
```jcl
//CUSTDATA JOB ...
//COMPILE  EXEC PGM=IGYCRCTL
//STEPLIB  DD DISP=SHR,DSN=IGY.V6R4M0.SIGYCOMP
//SYSLIB   DD DISP=SHR,DSN=IN0050.CBSA.COBOL
//SYSADATA DD DISP=SHR,DSN=IN0050.CBSA.ADATA(CUSTOMER)
//SYSIN    DD DISP=SHR,DSN=IN0050.CBSA.COBOL(CUSTOMER)
```

#### Step 3: Allocating ADATA PDS
**Issue:** Dataset `IN0050.CBSA.ADATA` not found

**Solution:** Created `etc/install/base/buildjcl/ALLOCATE_ADATA_PDS.jcl`
```jcl
//ALLOCATE JOB ...
//ALLOC    EXEC PGM=IEFBR14
//ADATA    DD DSN=IN0050.CBSA.ADATA,
//            DISP=(NEW,CATLG,DELETE),
//            SPACE=(TRK,(10,5,10)),
//            DCB=(RECFM=VB,LRECL=32756,BLKSIZE=32760)
```

#### Step 4: Submitting JCL on z/OS
**User Actions:**
1. Allocated ADATA PDS using ALLOCATE_ADATA_PDS.jcl
2. Submitted CUSTOMER_ADATA.jcl to generate ADATA file
3. Verified ADATA file was created: `IN0050.CBSA.ADATA(CUSTOMER)` (15,819 bytes)

#### Step 5: Downloading ADATA File
**User Command (on USS):**
```bash
cp "//'IN0050.CBSA.ADATA(CUSTOMER)'" /u/in0050/CUSTOMER.adata
```

**Then transferred to MacBook:**
```bash
scp in0050@zos-host:/u/in0050/CUSTOMER.adata ./
```

#### Step 6: Running IBM Record Generator
**User Command (on MacBook):**
```bash
java -cp /Users/chinmaydas/Documents/ibm-record-generator/ibm-recgen/ibm-recgen.jar:/Users/chinmaydas/Documents/ibm-record-generator/ibm-jzos/ibm.jzos.jar \
  com.ibm.recordgen.cobol.RecordClassGenerator \
  adatafile=CUSTOMER.adata \
  package=com.ibm.cics.cip.bankliberty.datainterfaces \
  class=CUSTOMER \
  symbol=CUSTOMER-RECORD \
  outputdir=src/webui/src/main/java
```

**Result:** Generated `CUSTOMER.java` with:
- `CUSTOMER_TITLE` StringField(8)
- `CUSTOMER_NAME` StringField(52)
- Proper getter/setter methods

### Phase 3: Automation Script Development

#### Step 1: Creating Batch ADATA Generation Script
**User Request:**
```
create a shell script that will automate the process of downloading ADATA files from z/OS and generating Java classes
```

**Action:** Created `etc/install/base/buildjcl/download_and_generate_java.sh` with features:
- Auto-detects USS vs MacBook environment
- Three download methods:
  1. USS `cp` command (default on z/OS)
  2. Zowe CLI (for MacBook)
  3. FTP (for MacBook)
- Batch processes all ADATA files
- Generates Java classes automatically

#### Step 2: Configuring for USS Environment
**User Feedback:**
```
I am getting this error:
IBM Record Generator not found at: /Applications/IBM/RecordGenerator/lib/RecordGenerator.jar
```

**User Provided Paths:**
```
ibm-recgen.jar is at /u/in0050/ibm-record-generator/ibm-recgen.jar
ibm.jzos.jar is at /u/in0050/ibm-record-generator/ibm-jzos/ibm.jzos.jar
```

**Action:** Updated script to hardcode USS paths:
```bash
if [ -f "/u/in0050/ibm-record-generator/ibm-recgen.jar" ]; then
    RECORD_GEN_JAR="/u/in0050/ibm-record-generator/ibm-recgen.jar"
    JZOS_JAR="/u/in0050/ibm-record-generator/ibm-jzos/ibm.jzos.jar"
    CLASSPATH="${RECORD_GEN_JAR}:${JZOS_JAR}"
fi
```

#### Step 3: Fixing Command Syntax
**User Error:**
```
Exception in thread "main" java.lang.IllegalArgumentException: Argument '-a' not in the form: name=value
```

**Issue:** IBM Record Generator V3.0.3 uses old `name=value` syntax, not `-flag` syntax

**Action:** Updated command to:
```bash
java -cp "$CLASSPATH" \
  com.ibm.recordgen.cobol.RecordClassGenerator \
  adatafile="$ADATA_FILE" \
  package="$JAVA_PACKAGE" \
  class="$BASENAME" \
  outputdir="$OUTPUT_DIR"
```

#### Step 4: Making Java Package Configurable
**User Request:**
```
you have hardcoded output dir to have this com/ibm/cics/cip/bankliberty/datainterfaces
can u remove it?
```

**Action:** Added `--java-package` parameter:
```bash
./download_and_generate_java.sh \
  --zos-qualifier IN0050.CBSA \
  --output-dir /u/in0050/generated-java \
  --java-package com.mycompany.myapp.models  # Optional
```

### Phase 4: Java Application Updates

#### Step 1: Updated CustomerJSON.java
Added `customerTitle` field with proper annotations and methods:
```java
@FormParam("customerTitle")
private String customerTitle;

public String getCustomerTitle() { return customerTitle; }
public void setCustomerTitle(String customerTitle) { this.customerTitle = customerTitle; }
```

#### Step 2: Updated Customer.java (VSAM Handler)
Modified all methods to:
- Write title and name separately to VSAM
- Read title and name separately from VSAM
- Combine title and name for display purposes

Key methods updated:
- `getCustomer()` - Combines title and name when reading
- `updateCustomer()` - Handles title separately when writing
- `createCustomer()` - Handles title separately when writing
- `deleteCustomer()` - Combines title and name
- All customer list methods - Combine title and name for display

### Final Script Usage

**On USS (z/OS):**
```bash
./download_and_generate_java.sh \
  --zos-qualifier IN0050.CBSA \
  --output-dir /u/in0050/generated-java
```

**On MacBook with Zowe CLI:**
```bash
./download_and_generate_java.sh \
  --zos-qualifier IN0050.CBSA \
  --output-dir src/webui/src/main/java/com/ibm/cics/cip/bankliberty/datainterfaces \
  --use-zowe
```

**On MacBook with FTP:**
```bash
./download_and_generate_java.sh \
  --zos-qualifier IN0050.CBSA \
  --output-dir src/webui/src/main/java/com/ibm/cics/cip/bankliberty/datainterfaces \
  --use-ftp \
  --ftp-host zos.example.com \
  --ftp-user IN0050
```

## Changes Made

### 1. COBOL Changes

#### Copybooks Modified:
- **`src/base/cobol_copy/CUSTOMER.cpy`** (Lines 13-14)
  - Changed from single 60-byte CUSTOMER-NAME to:
    ```cobol
    05 CUSTOMER-TITLE          PIC X(8).
    05 CUSTOMER-NAME           PIC X(52).
    ```

- **`src/base/cobol_copy/CRECUST.cpy`**
  - Added `COMM-TITLE PIC X(8)` field

- **`src/base/cobol_copy/UPDCUST.cpy`**
  - Added `COMM-TITLE PIC X(8)` field

- **`src/base/cobol_copy/DELCUS.cpy`**
  - Added `COMM-TITLE PIC X(8)` field

- **`src/base/cobol_copy/INQCUST.cpy`**
  - Added `INQCUST-TITLE PIC X(8)` field

- **`src/base/cobol_copy/INQCUSTZ.cpy`**
  - Added `INQCUST-TITLE PIC X(8)` field

#### COBOL Programs Modified:
- **`src/base/cobol_src/BANKDATA.cbl`** (Lines 544-555)
  - Separates title from name using STRING statement
  - Populates CUSTOMER-TITLE field independently

- **`src/base/cobol_src/CRECUST.cbl`**
  - Added title field handling in COMMAREA processing

- **`src/base/cobol_src/UPDCUST.cbl`**
  - Added title field handling in COMMAREA processing

- **`src/base/cobol_src/DELCUS.cbl`**
  - Added title field handling in COMMAREA processing

- **`src/base/cobol_src/INQCUST.cbl`**
  - Added title field handling in COMMAREA processing

- **`src/base/cobol_src/BNK1DCS.cbl`** (Lines ~924, ~1095, ~1286, ~1950)
  - Added CUSTTITO field handling for BMS map interaction

#### BMS Map Modified:
- **`src/base/bms_src/BNK1DCM.bms`** (Line 9)
  - Added CUSTTIT field for title input/display

### 2. Java Changes

#### IBM Record Generator Process:
1. **Created JCL**: `etc/install/base/buildjcl/CUSTOMER_ADATA.jcl`
   - Generates ADATA file from CUSTOMER.cpy using Enterprise COBOL compiler
   - Uses correct system datasets per compilation rules
   - Output: `IN0050.CBSA.ADATA(CUSTOMER)`

2. **Generated ADATA File**: `CUSTOMER.adata` (15,819 bytes)
   - Downloaded from z/OS to local machine
   - Contains COBOL metadata for Java class generation

3. **Generated Java Class**: `src/webui/src/main/java/com/ibm/cics/cip/bankliberty/datainterfaces/CUSTOMER.java`
   - Line 38: `CUSTOMER_TITLE` StringField(8)
   - Line 42: `CUSTOMER_NAME` StringField(52)
   - Lines 117, 190-203: Instance variable and getter/setter for customerTitle
   - Lines 118, 205-218: Instance variable and getter/setter for customerName

#### Java Classes Modified:

- **`src/webui/src/main/java/com/ibm/cics/cip/bankliberty/api/json/CustomerJSON.java`**
  - Added `customerTitle` field with @FormParam annotation
  - Added `getCustomerTitle()` and `setCustomerTitle()` methods
  - Updated `toString()` method to include customerTitle

- **`src/webui/src/main/java/com/ibm/cics/cip/bankliberty/web/vsam/Customer.java`**
  - Updated `getCustomer()` method (line 278): Combines title and name when reading
  - Updated `updateCustomer()` method (lines 448-453, 492): Handles title separately when writing, combines when reading
  - Updated `createCustomer()` method (lines 655-663, 758): Handles title separately when writing, combines when reading
  - Updated `deleteCustomer()` method (line 580): Combines title and name
  - Updated all customer list methods (lines 389, 941, 1044, 1149, 1358, 1458, 1558): Combine title and name for display

### 3. Documentation Created:

- **`RECORD_GENERATOR_GUIDE.md`**
  - Comprehensive guide for IBM Record Generator process
  - Includes JCL creation, ADATA generation, and usage instructions
  - Step-by-step instructions for future use

- **`CUSTOMER_TITLE_CHANGES_SUMMARY.md`** (this file)
  - Complete summary of all changes made

## Technical Details

### Record Structure:
- **Total Record Length**: 259 bytes (unchanged)
- **CUSTOMER-TITLE**: 8 bytes (new independent field)
- **CUSTOMER-NAME**: 52 bytes (reduced from 60 bytes)
- **Combined Length**: 60 bytes (same as before)

### Field Mappings:
- **COBOL**: `CUSTOMER-TITLE PIC X(8)` + `CUSTOMER-NAME PIC X(52)`
- **Java**: `StringField CUSTOMER_TITLE(8)` + `StringField CUSTOMER_NAME(52)`
- **Display**: Title and name are combined with a space for user display

### Data Flow:
1. **Input**: User provides title and name separately (or combined)
2. **Storage**: Title and name stored in separate VSAM fields
3. **Retrieval**: Title and name read separately from VSAM
4. **Display**: Title and name combined for presentation

## IBM Record Generator Command

```bash
java -cp /Users/chinmaydas/Documents/ibm-record-generator/ibm-recgen/ibm-recgen.jar:/Users/chinmaydas/Documents/ibm-record-generator/ibm-jzos/ibm.jzos.jar \
  com.ibm.recordgen.cobol.RecordClassGenerator \
  adatafile=CUSTOMER.adata \
  package=com.ibm.cics.cip.bankliberty.datainterfaces \
  class=CUSTOMER \
  symbol=CUSTOMER-RECORD \
  outputdir=src/webui/src/main/java
```

## Testing Requirements

### COBOL Programs to Recompile:
- BANKDATA.cbl
- CRECUST.cbl
- UPDCUST.cbl
- DELCUS.cbl
- INQCUST.cbl
- BNK1DCS.cbl
- Any other programs using CUSTOMER copybook

### Java Build:
```bash
cd src/webui
mvn clean compile
```

### Test Scenarios:
1. **Create Customer**: Verify title is stored separately in VSAM
2. **Update Customer**: Verify title can be updated independently
3. **Inquire Customer**: Verify title and name are displayed correctly
4. **Delete Customer**: Verify title is included in deletion confirmation
5. **List Customers**: Verify title appears in customer lists
6. **Search by Name**: Verify search works with combined title+name

## Benefits

1. **Data Integrity**: Title is now a separate field, preventing data corruption
2. **Flexibility**: Title can be validated and processed independently
3. **Maintainability**: Clear separation of concerns in data structure
4. **Compatibility**: Total record length unchanged, existing data migration possible
5. **Standards**: Follows IBM best practices using Record Generator

## Notes

- The `validateTitle()` method in CustomerJSON.java already exists and validates against standard titles (Mr, Mrs, Miss, Ms, Dr, Drs, Professor, Lord, Sir, Lady)
- When reading from VSAM, title and name are combined with a space for display purposes
- When writing to VSAM, title is stored separately if provided
- The BMS map now includes a separate CUSTTIT field for title input

## Files Requiring Deployment

### z/OS (COBOL):
- All modified copybooks in `src/base/cobol_copy/`
- All modified COBOL programs in `src/base/cobol_src/`
- Modified BMS map in `src/base/bms_src/`

### Liberty (Java):
- `src/webui/src/main/java/com/ibm/cics/cip/bankliberty/datainterfaces/CUSTOMER.java`
- `src/webui/src/main/java/com/ibm/cics/cip/bankliberty/api/json/CustomerJSON.java`
- `src/webui/src/main/java/com/ibm/cics/cip/bankliberty/web/vsam/Customer.java`

## Completion Status

✅ All COBOL changes completed
✅ All Java changes completed
✅ IBM Record Generator successfully used
✅ Documentation created
✅ Ready for testing and deployment