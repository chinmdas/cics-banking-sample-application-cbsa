//GENALL   JOB (FB3),'GENERATE ALL ADATA',CLASS=A,MSGCLASS=H,
//         NOTIFY=&SYSUID,MSGLEVEL=(1,1)
//*
//* Copyright IBM Corp. 2023
//*
//* JCL to generate ADATA files for ALL copybooks in IN0050.CBSA.DSECT
//*
//* This JCL uses IEBGENER to read the PDS directory and then
//* generates a separate ADATA file for each member.
//*
//* APPROACH: Use a PROC with symbolic parameters to process each member
//*
//* ================================================================
//* STEP 1: Define a PROC for generating ADATA for one copybook
//* ================================================================
//*
//GENPROC PROC MEMBER=DUMMY
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
//* ADATA Output - One file per copybook
//SYSADATA DD DSN=IN0050.CBSA.ADATA(&MEMBER),DISP=SHR
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
//* Inline COBOL Source with COPY Statement
//SYSIN    DD *
       PROCESS ADATA
       IDENTIFICATION DIVISION.
       PROGRAM-ID. &MEMBER.CPY.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY &MEMBER..
       PROCEDURE DIVISION.
           STOP RUN.
/*
//        PEND
//*
//* ================================================================
//* STEP 2: Execute PROC for each copybook member
//* ================================================================
//*
//* NOTE: You must manually add an EXEC statement for each member
//* in your IN0050.CBSA.DSECT PDS, or use automation (see below)
//*
//CUST01  EXEC PROC=GENPROC,MEMBER=CUSTOMER
//ACCT01  EXEC PROC=GENPROC,MEMBER=ACCOUNT
//PROC01  EXEC PROC=GENPROC,MEMBER=PROCTRAN
//CREA01  EXEC PROC=GENPROC,MEMBER=CREACC
//CREC01  EXEC PROC=GENPROC,MEMBER=CRECUST
//DELA01  EXEC PROC=GENPROC,MEMBER=DELACC
//DELC01  EXEC PROC=GENPROC,MEMBER=DELCUS
//INQA01  EXEC PROC=GENPROC,MEMBER=INQACC
//INQC01  EXEC PROC=GENPROC,MEMBER=INQCUST
//UPDA01  EXEC PROC=GENPROC,MEMBER=UPDACC
//UPDC01  EXEC PROC=GENPROC,MEMBER=UPDCUST
//ABND01  EXEC PROC=GENPROC,MEMBER=ABNDINFO
//ACCDB01 EXEC PROC=GENPROC,MEMBER=ACCDB2
//ACCT01  EXEC PROC=GENPROC,MEMBER=ACCTCTRL
//BANK01  EXEC PROC=GENPROC,MEMBER=BANKMAP
//BNK101  EXEC PROC=GENPROC,MEMBER=BNK1DDM
//CONT01  EXEC PROC=GENPROC,MEMBER=CONTDB2
//CNTR01  EXEC PROC=GENPROC,MEMBER=CONTROLI
//CUST01  EXEC PROC=GENPROC,MEMBER=CUSTCTRL
//CUSM01  EXEC PROC=GENPROC,MEMBER=CUSTMAP
//DELA02  EXEC PROC=GENPROC,MEMBER=DELACCZ
//GETC01  EXEC PROC=GENPROC,MEMBER=GETCOMPY
//GETS01  EXEC PROC=GENPROC,MEMBER=GETSCODE
//INQA02  EXEC PROC=GENPROC,MEMBER=INQACCCU
//INQA03  EXEC PROC=GENPROC,MEMBER=INQACCCZ
//INQA04  EXEC PROC=GENPROC,MEMBER=INQACCZ
//INQC02  EXEC PROC=GENPROC,MEMBER=INQCUSTZ
//NEWA01  EXEC PROC=GENPROC,MEMBER=NEWACCNO
//NEWC01  EXEC PROC=GENPROC,MEMBER=NEWCUSNO
//PAYD01  EXEC PROC=GENPROC,MEMBER=PAYDBCR
//PROC02  EXEC PROC=GENPROC,MEMBER=PROCDB2
//PROI01  EXEC PROC=GENPROC,MEMBER=PROCISRT
//RESP01  EXEC PROC=GENPROC,MEMBER=RESPSTR
//SORT01  EXEC PROC=GENPROC,MEMBER=SORTCODE
//STCU01  EXEC PROC=GENPROC,MEMBER=STCUSTNO
//WAZI01  EXEC PROC=GENPROC,MEMBER=WAZI
//XFRF01  EXEC PROC=GENPROC,MEMBER=XFRFUN
//*
//* ================================================================
//* AUTOMATION ALTERNATIVE: Use REXX or Shell Script
//* ================================================================
//*
//* For true automation, create a REXX script that:
//* 1. Reads all member names from IN0050.CBSA.DSECT
//* 2. Dynamically generates this JCL with EXEC statements
//* 3. Submits the generated JCL
//*
//* Example REXX (run on z/OS):
//*
//* /* REXX */
//* dsn = 'IN0050.CBSA.DSECT'
//* x = OUTTRAP('members.')
//* "LISTDS '"dsn"' MEMBERS"
//* x = OUTTRAP('OFF')
//* 
//* do i = 7 to members.0  /* Skip header lines */
//*   member = STRIP(members.i)
//*   if member <> '' then do
//*     say '//STEP'RIGHT(i,3,'0') 'EXEC PROC=GENPROC,MEMBER='member
//*   end
//* end
//*
//* ================================================================
//* RESULT:
//* ================================================================
//*
//* After successful execution, you will have ADATA files in
//* IN0050.CBSA.ADATA for each copybook:
//*   - IN0050.CBSA.ADATA(CUSTOMER)
//*   - IN0050.CBSA.ADATA(ACCOUNT)
//*   - IN0050.CBSA.ADATA(PROCTRAN)
//*   - ... and so on for all copybooks
//*
//* You can then download all ADATA files and run RecordClassGenerator
//* for each one to generate the corresponding Java classes.
//*