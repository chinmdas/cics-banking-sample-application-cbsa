# Scenario: RecordClassGenerator Command Syntax Failure

## Use case
After successfully generating the ADATA file from CUSTOMER.cpy and downloading it to the local MacBook, Bob needed to run the IBM Record Generator's RecordClassGenerator to generate the CUSTOMER.java class. Bob had the ADATA file (`CUSTOMER.adata`) and the Record Generator JAR files installed locally, but did not know the correct command-line syntax.

The IBM Record Generator V3.0.3 requires specific parameter syntax that differs from typical Java command-line conventions.

## Prompt
> Run the RecordClassGenerator to generate CUSTOMER.java from the ADATA file.

## Output (incorrect)

Bob attempted to run RecordClassGenerator with incorrect syntax:

> I'll run the RecordClassGenerator with the ADATA file:
> 
> ```bash
> java -cp ibm-recgen.jar:ibm.jzos.jar \
>   com.ibm.recordgen.cobol.RecordClassGenerator \
>   -a CUSTOMER.adata \
>   -package com.ibm.cics.cip.bankliberty.datainterfaces \
>   -class CUSTOMER \
>   -output src/webui/src/main/java
> ```

The command failed with error:

```
Argument not recognized: -a
Arguments must be in the form: name=value
```

Bob tried several variations:
- Using `-a`, `-input`, `-help` flags (all rejected)
- Using `input=CUSTOMER.adata` (rejected)
- Using `library=CUSTOMER.adata` (rejected)

All attempts resulted in "Argument not recognized" or "not in the form: name=value" errors.

## Problem Analysis

> **Issue**: Bob did not know the correct parameter syntax for RecordClassGenerator and attempted to use standard command-line flag conventions that don't work with this tool.

Bob's errors included:
1. **Wrong parameter format**: Used `-a` flag instead of `adatafile=` parameter
2. **Wrong parameter names**: Tried `-input`, `-package`, `-class`, `-output` instead of the correct names
3. **No documentation reference**: Did not consult the IBM Record Generator documentation for correct syntax
4. **Assumption about conventions**: Assumed standard Java CLI conventions would work

The RecordClassGenerator uses a specific `name=value` parameter format without dashes, which is different from typical command-line tools.

**Correct Parameter Names**:
- `adatafile=` - Path to the ADATA file (not `-a` or `input=`)
- `package=` - Java package name (not `-package`)
- `class=` - Java class name (not `-class`)
- `symbol=` - COBOL record name (not documented in Bob's attempts)
- `outputdir=` - Output directory (not `-output`)

## Solution

**Rule**: Always consult the official IBM documentation for tool-specific syntax. IBM Record Generator uses `name=value` parameter format without dashes. Do not assume standard CLI conventions apply to all Java tools.

**Reference Documentation**: https://www.ibm.com/docs/en/record-generator/3.0.0?topic=cobol-running-recordclassgenerator#cobol_running_rcg

**Correct Syntax Example from Documentation**:
```bash
java com.ibm.recordgen.cobol.RecordClassGenerator \
     adatafile="//'USER.COBOL.ADATA(MYRECORD)'" \
     package=cobol.records \
     class=MyRecord \
     symbol=MY-RECORD \
     outputdir=generatedClasses
```

## Output (corrected)

After consulting the IBM documentation, Bob corrected the command:

> I found the correct syntax in the IBM documentation. The parameters use `name=value` format without dashes:
> 
> ```bash
> java -cp /Users/chinmaydas/Documents/ibm-record-generator/ibm-recgen/ibm-recgen.jar:/Users/chinmaydas/Documents/ibm-record-generator/ibm-jzos/ibm.jzos.jar \
>   com.ibm.recordgen.cobol.RecordClassGenerator \
>   adatafile=CUSTOMER.adata \
>   package=com.ibm.cics.cip.bankliberty.datainterfaces \
>   class=CUSTOMER \
>   symbol=CUSTOMER-RECORD \
>   outputdir=src/webui/src/main/java
> ```

The command executed successfully:

```
IBM Record Generator for Java V3.0.3 Build 20250630-0857 on: Thu Feb 26 07:56:50 IST 2026
Running with Java version : 21.0.8
Generating CUSTOMER.adata to: /Users/chinmaydas/git/vscodeGH/cics-banking-sample-application-cbsa/src/webui/src/main/java/com/ibm/cics/cip/bankliberty/datainterfaces/CUSTOMER.java
```

**Key Corrections**:
1. Changed `-a` to `adatafile=`
2. Changed `-package` to `package=`
3. Changed `-class` to `class=`
4. Added required `symbol=CUSTOMER-RECORD` parameter
5. Changed `-output` to `outputdir=`
6. Removed all dashes from parameter names

The generated CUSTOMER.java file included proper field definitions:
- `CUSTOMER_TITLE` StringField(8)
- `CUSTOMER_NAME` StringField(52)
- Correct getter/setter methods
- Proper field offsets calculated by the tool