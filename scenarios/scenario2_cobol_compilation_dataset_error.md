# Scenario: COBOL Compilation Failure Due to Incorrect System Dataset

## Use case
Bob needed to create JCL to compile the CUSTOMER copybook with the ADATA option to generate metadata for IBM Record Generator. The compilation required using the correct Enterprise COBOL compiler and CICS libraries specific to the CBSA environment.

Bob created initial JCL [`CUSTOMER_ADATA.jcl`](../etc/install/base/buildjcl/CUSTOMER_ADATA.jcl) but encountered compilation errors due to using incorrect system dataset names.

## Prompt
> Create JCL to compile CUSTOMER.cpy with ADATA option to generate the ADATA file needed for IBM Record Generator.

## Output (incorrect)

Bob created JCL with incorrect dataset references:

> I'll create the JCL to compile CUSTOMER.cpy with ADATA option:
> 
> ```jcl
> //STEPLIB  DD DSN=IGY.V6R3M0.SIGYCOMP,DISP=SHR
> //         DD DSN=CICSTS.CICS630.SDFHLOAD,DISP=SHR
> //SYSLIB   DD DSN=IN0050.CBSA.DSECT,DISP=SHR
> //         DD DSN=CICSTS.CICS630.SDFHCOB,DISP=SHR
> ```

When submitted, the JCL failed with error:

```
IEF212I CUSTOMER STEPLIB - DATA SET NOT FOUND
IGY.V6R3M0.SIGYCOMP NOT CATALOGED
```

## Problem Analysis

> **Issue**: Bob used generic or incorrect dataset names that don't exist in the CBSA z/OS environment, causing compilation failure.

Bob's errors included:
1. **Wrong COBOL compiler dataset**: Used `IGY.V6R3M0.SIGYCOMP` instead of the correct `PP.COBOL390.V640.SIGYCOMP`
2. **Wrong CICS library qualifier**: Used `CICSTS.CICS630` instead of `ANTZ.CICS.TS.DEV.INTEGRAT`
3. **Missing LE libraries**: Did not include Language Environment libraries (`PP.ADLE370.ZOS301.*`)
4. **No reference to standards**: Did not consult the project's compilation rules documentation

The CBSA environment has specific dataset naming conventions and versions that must be followed. These are documented in the project's compilation rules file.

**Correct Dataset Names** (from `/Users/chinmaydas/.bob/.cobol_compilation_rules.md` which is a rule file for BOB):
- **COBOL Compiler**: `PP.COBOL390.V640.SIGYCOMP` (COBOL V6.4.0)
- **CICS Libraries**: `ANTZ.CICS.TS.DEV.INTEGRAT.SDFHLOAD` and `ANTZ.CICS.TS.DEV.INTEGRAT.SDFHCOB`
- **LE Libraries**: `PP.ADLE370.ZOS301.SCEESAMP` and `PP.ADLE370.ZOS301.SCEELKED`

## Solution

**Rule**: Always consult the project's COBOL compilation rules documentation before creating JCL. Use the exact dataset names specified in the standards document, as these are environment-specific and critical for successful compilation.

**Reference File**: `/Users/chinmaydas/.bob/.cobol_compilation_rules.md`

**Key Standards**:
- COBOL Compiler V6.4.0: `PP.COBOL390.V640.SIGYCOMP`
- CICS TS Development: `ANTZ.CICS.TS.DEV.INTEGRAT.*`
- Language Environment z/OS 3.01: `PP.ADLE370.ZOS301.*`

## Output (corrected)

After consulting the compilation rules document, Bob corrected the JCL:

> I need to reference the correct system datasets from the compilation rules. Let me update the JCL:
> 
> ```jcl
> //STEPLIB  DD DSN=PP.COBOL390.V640.SIGYCOMP,DISP=SHR
> //         DD DSN=ANTZ.CICS.TS.DEV.INTEGRAT.SDFHLOAD,DISP=SHR
> //SYSLIB   DD DSN=IN0050.CBSA.DSECT,DISP=SHR
> //         DD DSN=ANTZ.CICS.TS.DEV.INTEGRAT.SDFHCOB,DISP=SHR
> //         DD DSN=PP.ADLE370.ZOS301.SCEESAMP,DISP=SHR
> ```

The corrected JCL successfully compiled CUSTOMER.cpy and generated the ADATA file to `IN0050.CBSA.ADATA(CUSTOMER)`.

**Key Corrections**:
1. Changed COBOL compiler to `PP.COBOL390.V640.SIGYCOMP`
2. Changed CICS libraries to `ANTZ.CICS.TS.DEV.INTEGRAT.*`
3. Added LE library `PP.ADLE370.ZOS301.SCEESAMP`
4. Maintained proper library concatenation order per standards

The compilation completed successfully with RC=0, generating a 15,819-byte ADATA file containing the COBOL metadata needed for Java class generation.