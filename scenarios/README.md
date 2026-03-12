# Bob Evaluation Scenarios - CUSTOMER-TITLE Implementation

This directory contains three scenarios documenting Bob's learning journey while implementing the CUSTOMER-TITLE field restructuring in the CICS Banking Sample Application.

## Overview

The task involved restructuring the CUSTOMER VSAM record to make CUSTOMER-TITLE an independent 8-byte field, separate from CUSTOMER-NAME (52 bytes). This required changes to both COBOL and Java code, with Java class generation using IBM Record Generator.

## Scenarios

### 1. [Discovering IBM Record Generator](scenario1_ibm_record_generator_discovery.md)

**Challenge**: Bob needed to regenerate the Java CUSTOMER class but didn't know about IBM Record Generator.

**Learning**: 
- IBM Record Generator is the standard tool for generating Java classes from COBOL structures
- Manual updates to JZOS field mappings are error-prone and not recommended
- The tool ensures accurate field offsets and maintains COBOL-Java consistency

**Key Resource**: [IBM Record Generator Documentation](https://www.ibm.com/docs/en/record-generator/3.0.0?topic=getting-started-record-generator-java)

**Outcome**: Bob learned to use the proper tool workflow: COBOL → ADATA → Java class generation

---

### 2. [COBOL Compilation Dataset Error](scenario2_cobol_compilation_dataset_error.md)

**Challenge**: Bob's JCL to generate ADATA file failed due to incorrect system dataset names.

**Error Encountered**:
```
IEF212I CUSTOMER STEPLIB - DATA SET NOT FOUND
IGY.V6R3M0.SIGYCOMP NOT CATALOGED
```

**Learning**:
- System dataset names are environment-specific and must match project standards
- Always consult the project's compilation rules documentation
- CBSA uses specific dataset qualifiers that differ from generic examples

**Key Resource**: `/Users/chinmaydas/.bob/.cobol_compilation_rules.md`

**Correct Datasets Used**:
- COBOL Compiler: `PP.COBOL390.V640.SIGYCOMP`
- CICS Libraries: `ANTZ.CICS.TS.DEV.INTEGRAT.*`
- LE Libraries: `PP.ADLE370.ZOS301.*`

**Outcome**: Bob learned to reference project-specific compilation standards before creating JCL

---

### 3. [RecordClassGenerator Syntax Error](scenario3_record_generator_syntax_error.md)

**Challenge**: Bob couldn't run RecordClassGenerator due to incorrect command-line syntax.

**Error Encountered**:
```
Argument not recognized: -a
Arguments must be in the form: name=value
```

**Learning**:
- IBM Record Generator uses `name=value` parameter format (no dashes)
- Standard CLI conventions don't apply to all Java tools
- Tool-specific documentation is essential for correct usage

**Key Resource**: [Running RecordClassGenerator Documentation](https://www.ibm.com/docs/en/record-generator/3.0.0?topic=cobol-running-recordclassgenerator#cobol_running_rcg)

**Correct Syntax**:
```bash
java -cp ibm-recgen.jar:ibm.jzos.jar \
  com.ibm.recordgen.cobol.RecordClassGenerator \
  adatafile=CUSTOMER.adata \
  package=com.ibm.cics.cip.bankliberty.datainterfaces \
  class=CUSTOMER \
  symbol=CUSTOMER-RECORD \
  outputdir=src/webui/src/main/java
```

**Outcome**: Bob learned to consult official documentation for tool-specific syntax requirements

---

## Common Themes

### 1. Documentation is Critical
All three scenarios were resolved by consulting official documentation:
- IBM Record Generator documentation for tool discovery and syntax
- Project compilation rules for environment-specific datasets
- Tool-specific guides for correct parameter formats

### 2. Don't Assume Standard Conventions
- IBM Record Generator uses non-standard parameter syntax
- Dataset names are environment-specific, not generic
- Tools may have unique requirements that differ from common practices

### 3. Follow Project Standards
- Projects have established standards for compilation and tooling
- These standards exist for good reasons (consistency, reliability)
- Always check for project-specific documentation before proceeding

### 4. Use the Right Tool for the Job
- Manual updates are error-prone when proper tools exist
- IBM provides specialized tools (Record Generator) for specific tasks
- Using the correct tool ensures accuracy and maintainability

---

## Related Documentation

- [RECORD_GENERATOR_GUIDE.md](../RECORD_GENERATOR_GUIDE.md) - Complete guide for IBM Record Generator process
- [CUSTOMER_TITLE_CHANGES_SUMMARY.md](../CUSTOMER_TITLE_CHANGES_SUMMARY.md) - Summary of all changes made
- [CUSTOMER_ADATA.jcl](../etc/install/base/buildjcl/CUSTOMER_ADATA.jcl) - JCL for generating ADATA file
- [.cobol_compilation_rules.md](../../.bob/.cobol_compilation_rules.md) - COBOL compilation standards

---

## Lessons for Future Tasks

1. **Before starting**: Check for project-specific documentation and standards
2. **When encountering errors**: Consult official documentation first
3. **When using new tools**: Read the tool's documentation for correct syntax
4. **When creating JCL**: Reference the project's compilation rules
5. **When generating code**: Use provided tools rather than manual updates

---

**Document Version**: 1.0  
**Created**: 2026-02-26  
**Task**: CUSTOMER-TITLE Field Implementation  
**Related Issue**: Restructuring CUSTOMER VSAM record