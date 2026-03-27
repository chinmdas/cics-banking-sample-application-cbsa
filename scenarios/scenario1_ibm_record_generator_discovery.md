# Scenario: Discovering IBM Record Generator for Java Class Generation

## Use case
Bob was tasked with restructuring the CUSTOMER VSAM record in the CICS Banking Sample Application to make CUSTOMER-TITLE an independent 8-byte field, separate from CUSTOMER-NAME. After successfully updating the COBOL copybook [`CUSTOMER.cpy`](../src/base/cobol_copy/CUSTOMER.cpy), Bob needed to regenerate the corresponding Java class to reflect the new structure.

The user requested that Bob use IBM Record Generator instead of manually updating the Java class, but Bob had no prior knowledge of this tool or how to use it.

## Prompt
> I want you to use IBM Record Generator to generate the CUSTOMER.java file from the COBOL copybook instead of manually updating it.

## Output (incorrect)

Bob initially attempted to manually update the Java class:

> I'll update the CUSTOMER.java file to add the CUSTOMER_TITLE field. Let me modify the datainterfaces/CUSTOMER.java file to include:
> 
> ```java
> protected static final StringField CUSTOMER_TITLE = factory.getStringField(8);
> protected static final StringField CUSTOMER_NAME = factory.getStringField(52);
> ```
> 
> And add the corresponding getter/setter methods...

## Problem Analysis

> **Issue**: Bob did not know about IBM Record Generator and attempted to manually update the Java class instead of using the proper tool.

Bob's approach had several problems:
1. **Manual updates are error-prone**: Manually updating JZOS field mappings can lead to offset calculation errors and field alignment issues
2. **Not following best practices**: IBM provides Record Generator specifically for generating Java classes from COBOL structures
3. **Maintenance burden**: Manual updates make it harder to keep Java and COBOL structures in sync
4. **Missing tool knowledge**: Bob was unaware of the IBM Record Generator tool and its capabilities

The correct approach requires:
- Understanding that IBM Record Generator is the standard tool for this task
- Knowing how to generate ADATA files from COBOL copybooks
- Understanding the RecordClassGenerator command-line syntax
- Following the proper workflow: COBOL → ADATA → Java class

## Solution

**Rule**: When generating Java classes from COBOL copybooks for JZOS applications, always use IBM Record Generator for Java. The tool ensures accurate field mappings, proper offset calculations, and maintains consistency between COBOL and Java structures.

**Reference Documentation**: https://www.ibm.com/docs/en/record-generator/3.0.0?topic=getting-started-record-generator-java

**Key Steps**:
1. Generate ADATA file from COBOL copybook using Enterprise COBOL compiler with ADATA option
2. Use RecordClassGenerator to generate Java class from ADATA file
3. Verify the generated class has correct field definitions and offsets

## Output (corrected)

After being directed to use IBM Record Generator and consulting the documentation, Bob provided:

> I'll use IBM Record Generator to generate the CUSTOMER.java class. First, I need to:
> 
> 1. Create JCL to compile CUSTOMER.cpy with ADATA option to generate metadata
> 2. Download the ADATA file from z/OS
> 3. Run RecordClassGenerator to generate the Java class
> 
> Let me create the JCL file [`CUSTOMER_ADATA.jcl`](../etc/install/base/buildjcl/CUSTOMER_ADATA.jcl) to generate the ADATA file...

Bob successfully:
- Created JCL to generate ADATA file from CUSTOMER.cpy
- Submitted the JCL and downloaded the ADATA file
- Used RecordClassGenerator with correct parameters to generate CUSTOMER.java
- Verified the generated class had proper CUSTOMER_TITLE (8 bytes) and CUSTOMER_NAME (52 bytes) fields

The generated class included:
```java
protected static final StringField CUSTOMER_TITLE = factory.getStringField(8);
protected static final StringField CUSTOMER_NAME = factory.getStringField(52);
```

With proper getter/setter methods and correct field offsets calculated by the tool.