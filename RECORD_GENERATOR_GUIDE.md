# IBM Record Generator for Java - CUSTOMER.cpy Guide

This guide explains how to use IBM Record Generator for Java to generate Java classes from the updated CUSTOMER.cpy copybook.

## Prerequisites

You have already completed:
- ✅ Downloaded `ibm-recgen.jar` and `ibmjzos.jar` to your MacBook
- ✅ Java environment: OpenJDK 21.0.8 with IBM Semeru Runtime

## Step 1: Create ADATA File on z/OS

The ADATA file must be created on z/OS using the Enterprise COBOL compiler.

### Option A: Using the Provided JCL

A JCL file has been created at [`etc/install/base/buildjcl/CUSTOMER_ADATA.jcl`](etc/install/base/buildjcl/CUSTOMER_ADATA.jcl)

**To submit this JCL:**

1. Upload the JCL to your z/OS system
2. Ensure the following datasets exist:
   - `CBSA.CICSBSA.DSECT` - Contains CUSTOMER.cpy
   - `CBSA.CICSBSA.ADATA` - Will store the generated ADATA file
3. Submit the JCL job
4. Check the job output for successful completion (RC=0)
5. The ADATA file will be created as: `CBSA.CICSBSA.ADATA(CUSTOMER)`

### Option B: Using Ansible Playbook

If you're using your Ansible playbook to build COBOL programs, you can add a task to generate the ADATA file:

```yaml
- name: Generate ADATA file for CUSTOMER copybook
  zos_job_submit:
    src: "{{ playbook_dir }}/etc/install/base/buildjcl/CUSTOMER_ADATA.jcl"
    location: LOCAL
    wait_time_s: 300
  register: adata_job_result

- name: Display ADATA generation result
  debug:
    var: adata_job_result
```

### Key Compiler Options in the JCL

- `ADATA` - Generates the ADATA file
- `NOCOMPILE(W)` - Syntax check only, no object code generation
- `SYSADATA DD` - Specifies where to write the ADATA file

## Step 2: Download ADATA File to Your MacBook

After the JCL completes successfully, download the ADATA file from z/OS:

```bash
# Using zowe CLI (if available)
zowe files download ds "CBSA.CICSBSA.ADATA(CUSTOMER)" -f CUSTOMER.adata

# Or use FTP/SFTP to download the file in binary mode
```

**Important:** Download in **BINARY** mode to preserve the file format.

## Step 3: Run IBM Record Generator on Your MacBook

Once you have the ADATA file locally, run the RecordClassGenerator:

```bash
# Navigate to your project directory
cd /Users/chinmaydas/git/vscodeGH/cics-banking-sample-application-cbsa

# Run the Record Generator
java -cp /path/to/ibm-recgen.jar:/path/to/ibmjzos.jar \
  com.ibm.jzos.recordgen.cobol.RecordClassGenerator \
  -a CUSTOMER.adata \
  -o src/webui/src/main/java \
  -p com.ibm.cics.cip.bankliberty.datainterfaces \
  -c CUSTOMER
```

### Command Parameters Explained

- `-cp` - Classpath containing both ibm-recgen.jar and ibmjzos.jar
- `-a CUSTOMER.adata` - Input ADATA file
- `-o src/webui/src/main/java` - Output directory for generated Java class
- `-p com.ibm.cics.cip.bankliberty.datainterfaces` - Java package name
- `-c CUSTOMER` - Java class name

### Expected Output

The tool will generate:
- `src/webui/src/main/java/com/ibm/cics/cip/bankliberty/datainterfaces/CUSTOMER.java`

This file will contain:
- Field definitions for all COBOL fields including the new `CUSTOMER_TITLE`
- Getter and setter methods for each field
- Proper JZOS field mappings (StringField, IntField, etc.)

## Step 4: Verify the Generated Class

After generation, verify the CUSTOMER.java file contains:

```java
// Should include these fields:
private StringField CUSTOMER_EYECATCHER = CobolDatatypeFactory.getStringField(4, this);
private StringField CUSTOMER_SORTCODE = CobolDatatypeFactory.getStringField(6, this);
private StringField CUSTOMER_NUMBER = CobolDatatypeFactory.getStringField(10, this);
private StringField CUSTOMER_TITLE = CobolDatatypeFactory.getStringField(8, this);  // NEW!
private StringField CUSTOMER_NAME = CobolDatatypeFactory.getStringField(52, this);  // Updated length
private StringField CUSTOMER_ADDRESS = CobolDatatypeFactory.getStringField(160, this);
// ... etc
```

## Step 5: Update Other Java Classes

After the CUSTOMER.java is generated, you'll need to update other Java classes that use customer data:

### Files to Update:

1. **`src/webui/src/main/java/com/ibm/cics/cip/bankliberty/web/vsam/Customer.java`**
   - Add calls to `setCustomerTitle()` when populating customer data
   - Extract title from name field if needed for backward compatibility

2. **`src/webui/src/main/java/com/ibm/cics/cip/bankliberty/api/json/CustomerJSON.java`**
   - Add `customerTitle` field
   - Add getter/setter methods
   - Update `toString()` method

3. **`src/webui/src/main/java/com/ibm/cics/cip/bankliberty/webui/data_access/Customer.java`**
   - Add title handling if this class is used

## Step 6: Build and Test

1. Compile the Java code:
   ```bash
   cd src/webui
   mvn clean compile
   ```

2. Run your Ansible playbook to deploy to z/OS

3. Test the application to ensure:
   - Customer records can be created with titles
   - Existing customer records display correctly
   - Title field is properly separated from name field

## Troubleshooting

### ADATA File Issues

**Problem:** JCL fails with "CUSTOMER not found"
- **Solution:** Ensure CUSTOMER.cpy is in the SYSLIB concatenation (CBSA.CICSBSA.DSECT)

**Problem:** ADATA dataset not found
- **Solution:** Create the dataset first:
  ```
  //ALLOC EXEC PGM=IEFBR14
  //ADATA DD DSN=CBSA.CICSBSA.ADATA,DISP=(NEW,CATLG),
  //      SPACE=(TRK,(10,5,10)),
  //      DCB=(RECFM=VB,LRECL=32756,BLKSIZE=32760)
  ```

### Record Generator Issues

**Problem:** ClassNotFoundException for RecordClassGenerator
- **Solution:** Ensure both ibm-recgen.jar and ibmjzos.jar are in the classpath

**Problem:** Generated class has wrong field lengths
- **Solution:** Verify the CUSTOMER.cpy used to generate ADATA matches your updated version

**Problem:** Record length mismatch at runtime
- **Solution:** Ensure all COBOL programs are recompiled with the updated CUSTOMER.cpy

## Current CUSTOMER Record Structure

After the changes, the CUSTOMER record structure is:

```
CUSTOMER-RECORD (259 bytes total)
├── CUSTOMER-EYECATCHER (4 bytes)
├── CUSTOMER-KEY (16 bytes)
│   ├── CUSTOMER-SORTCODE (6 bytes)
│   └── CUSTOMER-NUMBER (10 bytes)
├── CUSTOMER-TITLE (8 bytes)        ← NEW independent field
├── CUSTOMER-NAME (52 bytes)        ← Reduced from 60 bytes
├── CUSTOMER-ADDRESS (160 bytes)
├── CUSTOMER-DATE-OF-BIRTH (8 bytes)
├── CUSTOMER-CREDIT-SCORE (3 bytes)
└── CUSTOMER-CS-REVIEW-DATE (8 bytes)
```

## Batch Processing All Copybooks

When you need to generate Java classes for **ALL** copybooks in your PDS (e.g., `IN0050.CBSA.DSECT`), use the automated approach:

### Step 1: Generate ADATA Files for All Copybooks on z/OS

**Option A: Using Static JCL (Recommended for Production)**

Submit the pre-generated JCL: [`GENERATE_ALL_ADATA.jcl`](etc/install/base/buildjcl/GENERATE_ALL_ADATA.jcl)

This JCL:
- Defines a PROC with a symbolic `MEMBER` parameter
- Executes the PROC for each copybook in `IN0050.CBSA.DSECT`
- Generates individual ADATA files in `IN0050.CBSA.ADATA`
- Includes all 30+ copybook members from the project

**To submit:**
```bash
# Upload to z/OS
# Submit: TSO SUBMIT 'IN0050.CBSA.JCL(GENALL)'
```

**Option B: Using REXX for Dynamic Generation**

For dynamic member discovery, use the REXX script: [`GENALLJCL.rexx`](etc/install/base/buildjcl/GENALLJCL.rexx)

This script:
- Reads all members from `IN0050.CBSA.DSECT` dynamically
- Generates JCL with EXEC statements for each member
- Writes output to `IN0050.CBSA.JCL(GENALLJCL)`

**To run:**
```bash
# Upload GENALLJCL.rexx to z/OS
# Execute: TSO EXEC 'your.rexx.lib(GENALLJCL)'
# Then submit: TSO SUBMIT 'IN0050.CBSA.JCL(GENALLJCL)'
```

### Step 2: Download All ADATA Files to MacBook

After the JCL completes, download all ADATA files:

```bash
# Create local directory
mkdir -p ~/Downloads/cbsa_adata

# Download all ADATA files (using zowe CLI)
zowe files download all-members "IN0050.CBSA.ADATA" \
  --binary \
  --directory ~/Downloads/cbsa_adata

# Or use FTP/SFTP in binary mode
```

### Step 3: Batch Generate Java Classes on MacBook

Use the automated shell script: [`generate_all_java_classes.sh`](etc/install/base/buildjcl/generate_all_java_classes.sh)

**Features:**
- ✅ Processes all `.adata` files in a directory
- ✅ Interactive prompts for overwriting existing files
- ✅ Color-coded progress output
- ✅ Error handling with detailed logs
- ✅ Summary report at completion

**To run:**
```bash
# Make script executable
chmod +x etc/install/base/buildjcl/generate_all_java_classes.sh

# Set IBM Record Generator home (if not already set)
export RECORD_GEN_HOME=/Applications/IBM/RecordGenerator

# Run the batch processor
./etc/install/base/buildjcl/generate_all_java_classes.sh \
  ~/Downloads/cbsa_adata \
  src/webui/src/main/java/com/ibm/cics/cip/bankliberty/datainterfaces
```

**Script Output:**
```
========================================
IBM Record Generator - Batch Processor
========================================

ADATA Directory:  /Users/chinmaydas/Downloads/cbsa_adata
Output Directory: /Users/chinmaydas/git/.../datainterfaces
Record Generator: /Applications/IBM/RecordGenerator/lib/RecordGenerator.jar
Java Version:     openjdk version "21.0.8" 2024-07-16

Found 30 ADATA file(s)

Proceed with generation? (y/n) y

========================================
Processing ADATA Files
========================================

Processing: CUSTOMER
  ✓  Generated: .../datainterfaces/CUSTOMER.java

Processing: ACCOUNT
  ✓  Generated: .../datainterfaces/ACCOUNT.java

...

========================================
Summary
========================================

Total files:      30
Successfully generated: 30
Failed:           0
Skipped:          0

✓ All files processed successfully
```

### Copybooks Included in Batch Processing

The following copybooks from `src/base/cobol_copy/` will be processed:

**Core Data Structures:**
- `CUSTOMER.cpy` - Customer master record
- `ACCOUNT.cpy` - Account master record
- `PROCTRAN.cpy` - Processed transaction record
- `SORTCODE.cpy` - Sort code data

**Control Structures:**
- `CUSTCTRL.cpy` - Customer control record
- `ACCTCTRL.cpy` - Account control record

**Communication Areas:**
- `CRECUST.cpy` - Create customer commarea
- `UPDCUST.cpy` - Update customer commarea
- `DELCUS.cpy` - Delete customer commarea
- `INQCUST.cpy` - Inquire customer commarea
- `INQCUSTZ.cpy` - Inquire customer (zOS Connect)
- `CREACC.cpy` - Create account commarea
- `UPDACC.cpy` - Update account commarea
- `DELACC.cpy` - Delete account commarea
- `DELACCZ.cpy` - Delete account (zOS Connect)
- `INQACC.cpy` - Inquire account commarea
- `INQACCCU.cpy` - Inquire account by customer
- `INQACCCZ.cpy` - Inquire account by customer (zOS Connect)
- `INQACCZ.cpy` - Inquire account (zOS Connect)

**Utility Structures:**
- `GETCOMPY.cpy` - Get company data
- `GETSCODE.cpy` - Get sort code
- `NEWACCNO.cpy` - New account number
- `NEWCUSNO.cpy` - New customer number
- `STCUSTNO.cpy` - Store customer number
- `PAYDBCR.cpy` - Payment debit/credit
- `XFRFUN.cpy` - Transfer funds

**Database Structures:**
- `ACCDB2.cpy` - Account DB2 structure
- `CONTDB2.cpy` - Control DB2 structure
- `PROCDB2.cpy` - Process DB2 structure
- `PROCISRT.cpy` - Process insert

**Map Structures:**
- `BANKMAP.cpy` - Bank map copybook
- `CUSTMAP.cpy` - Customer map copybook
- `CONTROLI.cpy` - Control information
- `BNK1DDM.cpy` - BNK1 data definition map

**Other:**
- `ABNDINFO.cpy` - Abend information
- `RESPSTR.cpy` - Response structure
- `WAZI.cpy` - Wazi structure

### Troubleshooting Batch Processing

**Problem:** Some ADATA files fail to generate Java classes

**Solution:** Check the log files in `/tmp/recordgen_*.log` for specific errors:
```bash
# View error logs
ls -la /tmp/recordgen_*.log
cat /tmp/recordgen_COPYBOOK.log
```

Common issues:
- Missing COBOL record definition (no 01-level in copybook)
- Invalid ADATA file format
- Unsupported COBOL syntax

**Problem:** Script reports "No .adata files found"

**Solution:** Ensure ADATA files were downloaded in binary mode and have `.adata` extension

**Problem:** Permission denied when running script

**Solution:** Make script executable:
```bash
chmod +x etc/install/base/buildjcl/generate_all_java_classes.sh
```

## References

- [IBM Record Generator Documentation](https://www.ibm.com/docs/en/record-generator/3.0.0?topic=getting-started-record-generator-java)
- [Creating ADATA files with Enterprise COBOL](https://www.ibm.com/docs/en/record-generator/3.0.0?topic=java-creating-adata-files-enterprise-cobol-zos-compiler)
- [Running the COBOL RecordClassGenerator](https://www.ibm.com/docs/en/record-generator/3.0.0?topic=java-running-cobol-recordclassgenerator)
# Handling Multiple Copybooks - Best Practices

When you need to generate Java classes for multiple COBOL copybooks, you have two main approaches:

## Approach 1: Separate Steps (RECOMMENDED)

Create individual JCL steps for each copybook. This is the **recommended approach** because:

✅ **Advantages:**
- Each copybook gets its own ADATA file
- Easier to debug individual copybook issues
- Can run steps in parallel if needed
- Clear separation of concerns
- Independent versioning and updates

**Example JCL:** See [`GENERATE_MULTIPLE_ADATA.jcl`](etc/install/base/buildjcl/GENERATE_MULTIPLE_ADATA.jcl)

```jcl
//CUSTOMER EXEC PGM=IGYCRCTL,...
//SYSADATA DD DSN=IN0050.CBSA.ADATA(CUSTOMER),DISP=SHR
//SYSIN    DD *
       COPY CUSTOMER.
/*

//ACCOUNT EXEC PGM=IGYCRCTL,...
//SYSADATA DD DSN=IN0050.CBSA.ADATA(ACCOUNT),DISP=SHR
//SYSIN    DD *
       COPY ACCOUNT.
/*

//PROCTRAN EXEC PGM=IGYCRCTL,...
//SYSADATA DD DSN=IN0050.CBSA.ADATA(PROCTRAN),DISP=SHR
//SYSIN    DD *
       COPY PROCTRAN.
/*
```

**Then generate Java classes separately:**
```bash
# Generate CUSTOMER.java
java -cp ibm-recgen.jar:ibm.jzos.jar \
  com.ibm.recordgen.cobol.RecordClassGenerator \
  adatafile=CUSTOMER.adata \
  package=com.ibm.cics.cip.bankliberty.datainterfaces \
  class=CUSTOMER \
  symbol=CUSTOMER-RECORD \
  outputdir=src/webui/src/main/java

# Generate ACCOUNT.java
java -cp ibm-recgen.jar:ibm.jzos.jar \
  com.ibm.recordgen.cobol.RecordClassGenerator \
  adatafile=ACCOUNT.adata \
  package=com.ibm.cics.cip.bankliberty.datainterfaces \
  class=ACCOUNT \
  symbol=ACCOUNT-RECORD \
  outputdir=src/webui/src/main/java

# Generate PROCTRAN.java
java -cp ibm-recgen.jar:ibm.jzos.jar \
  com.ibm.recordgen.cobol.RecordClassGenerator \
  adatafile=PROCTRAN.adata \
  package=com.ibm.cics.cip.bankliberty.datainterfaces \
  class=PROCTRAN \
  symbol=PROCTRAN-RECORD \
  outputdir=src/webui/src/main/java
```

## Approach 2: Single Step with Multiple COPY Statements

Include all copybooks in one compilation step. Use this when:
- Copybooks are closely related
- You want faster execution
- You need all copybooks in one ADATA file

❌ **Disadvantages:**
- All copybooks in one ADATA file
- Harder to debug individual issues
- Must regenerate all if one changes

```jcl
//MULTI   EXEC PGM=IGYCRCTL,...
//SYSADATA DD DSN=IN0050.CBSA.ADATA(MULTIPLE),DISP=SHR
//SYSIN    DD *
       COPY CUSTOMER.
       COPY ACCOUNT.
       COPY PROCTRAN.
/*
```

**Then extract specific records using symbol parameter:**
```bash
# Extract CUSTOMER from combined ADATA
java -cp ibm-recgen.jar:ibm.jzos.jar \
  com.ibm.recordgen.cobol.RecordClassGenerator \
  adatafile=MULTIPLE.adata \
  package=com.ibm.cics.cip.bankliberty.datainterfaces \
  class=CUSTOMER \
  symbol=CUSTOMER-RECORD \
  outputdir=src/webui/src/main/java
```

## Automation with Shell Script

For multiple copybooks, create a shell script to automate the process:

```bash
#!/bin/bash
# generate_all_java_classes.sh

COPYBOOKS=("CUSTOMER" "ACCOUNT" "PROCTRAN")
PACKAGE="com.ibm.cics.cip.bankliberty.datainterfaces"
OUTPUTDIR="src/webui/src/main/java"
CLASSPATH="/path/to/ibm-recgen.jar:/path/to/ibm.jzos.jar"

for copybook in "${COPYBOOKS[@]}"; do
    echo "Generating ${copybook}.java..."
    java -cp "$CLASSPATH" \
        com.ibm.recordgen.cobol.RecordClassGenerator \
        adatafile="${copybook}.adata" \
        package="$PACKAGE" \
        class="$copybook" \
        symbol="${copybook}-RECORD" \
        outputdir="$OUTPUTDIR"
    
    if [ $? -eq 0 ]; then
        echo "✅ ${copybook}.java generated successfully"
    else
        echo "❌ Failed to generate ${copybook}.java"
        exit 1
    fi
done

echo "All Java classes generated successfully!"
```

## IBM Documentation Guidance

According to IBM Record Generator documentation:

> **Best Practice**: Generate separate ADATA files for each copybook when possible. This provides better maintainability and allows independent updates to individual data structures.

**Reference**: [IBM Record Generator Documentation](https://www.ibm.com/docs/en/record-generator/3.0.0)

---
