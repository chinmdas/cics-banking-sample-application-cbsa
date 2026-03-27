//MULTCOPY JOB (FB3),'MULTIPLE ADATA',CLASS=A,MSGCLASS=H,
//         NOTIFY=&SYSUID,MSGLEVEL=(1,1)
//*
//* Copyright IBM Corp. 2023
//*
//* JCL to compile multiple COBOL copybooks in a single step
//* and generate one ADATA file containing all copybook metadata
//*
//* Reference: IBM Record Generator for Java Documentation
//* https://www.ibm.com/docs/en/record-generator/3.0.0?topic=cobol-creating-adata-files-enterprise-zos-compiler
//*
//* This approach generates a SINGLE ADATA file containing metadata
//* for ALL copybooks. You then use the symbol= parameter in
//* RecordClassGenerator to extract specific record definitions.
//*
//GENADATA EXEC PGM=IGYCRCTL,REGION=0M,
//            PARM=(NODYNAM,LIB,RENT,LIST,MAP,XREF,
//   'APOST,ADATA,NOCOMPILE(W)')
//*
//* COBOL Compiler and CICS Translator Libraries
//STEPLIB  DD DSN=PP.COBOL390.V640.SIGYCOMP,DISP=SHR
//         DD DISP=SHR,DSN=ANTZ.CICS.TS.DEV.INTEGRAT.SDFHLOAD
//*
//* Copybook Libraries (searched in order)
//SYSLIB   DD DISP=SHR,DSN=IN0050.CBSA.DSECT
//         DD DISP=SHR,DSN=PP.ADLE370.ZOS301.SCEESAMP
//         DD DISP=SHR,DSN=ANTZ.CICS.TS.DEV.INTEGRAT.SDFHCOB
//*
//* Compilation Output
//SYSPRINT DD SYSOUT=*
//*
//* ADATA Output - Single file containing all copybook metadata
//SYSADATA DD DSN=IN0050.CBSA.ADATA(MULTIPLE),DISP=SHR
//*
//* Work Files for Compiler
//SYSUT1   DD UNIT=SYSALLDA,SPACE=(TRK,(350,100))
//SYSUT2   DD UNIT=SYSALLDA,SPACE=(TRK,(350,100))
//SYSUT3   DD UNIT=SYSALLDA,SPACE=(TRK,(350,100))
//SYSUT4   DD UNIT=SYSALLDA,SPACE=(TRK,(350,100))
//SYSUT5   DD UNIT=SYSALLDA,SPACE=(TRK,(350,100))
//SYSUT6   DD UNIT=SYSALLDA,SPACE=(TRK,(350,100))
//SYSUT7   DD UNIT=SYSALLDA,SPACE=(TRK,(350,100))
//SYSUT8   DD UNIT=SYSALLDA,SPACE=(TRK,(350,100))
//SYSUT9   DD UNIT=SYSALLDA,SPACE=(TRK,(350,100))
//SYSUT10  DD UNIT=SYSALLDA,SPACE=(TRK,(350,100))
//SYSUT11  DD UNIT=SYSALLDA,SPACE=(TRK,(350,100))
//SYSUT12  DD UNIT=SYSALLDA,SPACE=(TRK,(350,100))
//SYSUT13  DD UNIT=SYSALLDA,SPACE=(TRK,(350,100))
//SYSUT14  DD UNIT=SYSALLDA,SPACE=(TRK,(350,100))
//SYSUT15  DD UNIT=SYSALLDA,SPACE=(TRK,(350,100))
//SYSMDECK DD UNIT=SYSALLDA,SPACE=(TRK,(350,100))
//*
//* Inline COBOL Source with Multiple COPY Statements
//SYSIN    DD *
       PROCESS ADATA
       IDENTIFICATION DIVISION.
       PROGRAM-ID. MULTICOPY.
      *****************************************************************
      * This program includes multiple copybooks to generate         *
      * a single ADATA file containing metadata for all of them.     *
      *                                                               *
      * The NOCOMPILE(W) compiler option means this program will     *
      * not generate object code - only ADATA metadata.              *
      *****************************************************************
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      *
      * Include all copybooks that need Java class generation
      *
       01  CUSTOMER-DATA.
           COPY CUSTOMER.
      *
       01  ACCOUNT-DATA.
           COPY ACCOUNT.
      *
       01  PROCTRAN-DATA.
           COPY PROCTRAN.
      *
       PROCEDURE DIVISION.
           STOP RUN.
/*
//*
//* ================================================================
//* USAGE NOTES:
//* ================================================================
//*
//* 1. This JCL generates ONE ADATA file: IN0050.CBSA.ADATA(MULTIPLE)
//*
//* 2. The ADATA file contains metadata for ALL three copybooks:
//*    - CUSTOMER
//*    - ACCOUNT
//*    - PROCTRAN
//*
//* 3. To generate Java classes, download MULTIPLE.adata and run
//*    RecordClassGenerator THREE times, specifying different symbols:
//*
//*    # Generate CUSTOMER.java
//*    java -cp ibm-recgen.jar:ibm.jzos.jar \
//*      com.ibm.recordgen.cobol.RecordClassGenerator \
//*      adatafile=MULTIPLE.adata \
//*      package=com.ibm.cics.cip.bankliberty.datainterfaces \
//*      class=CUSTOMER \
//*      symbol=CUSTOMER-RECORD \
//*      outputdir=src/webui/src/main/java
//*
//*    # Generate ACCOUNT.java
//*    java -cp ibm-recgen.jar:ibm.jzos.jar \
//*      com.ibm.recordgen.cobol.RecordClassGenerator \
//*      adatafile=MULTIPLE.adata \
//*      package=com.ibm.cics.cip.bankliberty.datainterfaces \
//*      class=ACCOUNT \
//*      symbol=ACCOUNT-RECORD \
//*      outputdir=src/webui/src/main/java
//*
//*    # Generate PROCTRAN.java
//*    java -cp ibm-recgen.jar:ibm.jzos.jar \
//*      com.ibm.recordgen.cobol.RecordClassGenerator \
//*      adatafile=MULTIPLE.adata \
//*      package=com.ibm.cics.cip.bankliberty.datainterfaces \
//*      class=PROCTRAN \
//*      symbol=PROCTRAN-RECORD \
//*      outputdir=src/webui/src/main/java
//*
//* 4. The symbol= parameter tells RecordClassGenerator which
//*    record definition to extract from the ADATA file.
//*
//* 5. ADVANTAGES of this approach:
//*    - Single JCL submission
//*    - Faster execution (one compilation)
//*    - One ADATA file to manage
//*
//* 6. DISADVANTAGES of this approach:
//*    - If one copybook changes, must regenerate entire ADATA
//*    - All copybooks must compile successfully together
//*    - Harder to debug individual copybook issues
//*
//* 7. IBM RECOMMENDATION:
//*    Use separate ADATA files (one per copybook) for better
//*    maintainability unless copybooks are tightly coupled.
//*
//* ================================================================