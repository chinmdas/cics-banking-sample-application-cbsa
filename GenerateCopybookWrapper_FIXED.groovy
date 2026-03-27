@groovy.transform.BaseScript com.ibm.dbb.groovy.ScriptLoader baseScript
import com.ibm.dbb.repository.*
import com.ibm.dbb.dependency.*
import com.ibm.dbb.build.*
import groovy.transform.*

/**
 * GenerateCopybookWrapper - DBB Custom Task
 * 
 * This task generates Java wrapper classes from COBOL copybooks using
 * IBM Record Generator for Java.
 * 
 * IMPORTANT: This class extends com.ibm.dbb.groovy.ScriptLoader to comply
 * with DBB requirements (BGZZB0048E).
 */

@Field BuildProperties props = BuildProperties.getInstance()
@Field def buildUtils = loadScript(new File("${props.zAppBuildDir}/utilities/BuildUtilities.groovy"))

// Task name for DBB framework
def taskName = 'generateWrapper'

println("*** Executing custom task: ${taskName}")

/**
 * Main execution logic for generating copybook wrappers
 */
def execute(Map args) {
    // Get the file being processed
    def file = args.file
    def member = CopyToPDS.createMemberName(file)
    
    println("   Processing copybook: ${member}")
    
    // Define properties
    def copybookPDS = props.getProperty('copybookPDS') ?: 'CBSA.DSECT'
    def adataPDS = props.getProperty('adataPDS') ?: 'CBSA.ADATA'
    def javaOutputDir = props.getProperty('javaOutputDir') ?: '/u/java/generated'
    def javaPackage = props.getProperty('javaPackage') ?: 'com.ibm.cics.cip.bankliberty.datainterfaces'
    
    // Step 1: Generate ADATA file using COBOL compiler
    println("   Step 1: Generating ADATA file for ${member}")
    def rc = generateADATA(member, copybookPDS, adataPDS)
    
    if (rc != 0) {
        println("   ERROR: Failed to generate ADATA file (RC=${rc})")
        return rc
    }
    
    // Step 2: Generate Java class using IBM Record Generator
    println("   Step 2: Generating Java class for ${member}")
    rc = generateJavaClass(member, adataPDS, javaOutputDir, javaPackage)
    
    if (rc != 0) {
        println("   ERROR: Failed to generate Java class (RC=${rc})")
        return rc
    }
    
    println("   SUCCESS: Generated wrapper for ${member}")
    return 0
}

/**
 * Generate ADATA file from COBOL copybook
 */
def generateADATA(String member, String copybookPDS, String adataPDS) {
    def compile = new MVSExec().file(new File("dummy.cbl")).pgm("IGYCRCTL")
    
    // Compiler parameters
    compile.parm("NODYNAM,LIB,RENT,LIST,MAP,XREF,APOST,ADATA,NOCOMPILE(W)")
    
    // DD statements
    compile.dd(new DDStatement().name("STEPLIB").dsn(props.COBOL_COMPILER).options("shr"))
    compile.dd(new DDStatement().name("SYSLIB").dsn(copybookPDS).options("shr"))
    compile.dd(new DDStatement().name("SYSPRINT").options("sysout=*"))
    compile.dd(new DDStatement().name("SYSADATA").dsn("${adataPDS}(${member})").options("shr"))
    
    // Add SYSUT DD statements
    (1..15).each { i ->
        compile.dd(new DDStatement().name("SYSUT${i}").options("unit=sysallda,space=(trk,(350,100))"))
    }
    compile.dd(new DDStatement().name("SYSMDECK").options("unit=sysallda,space=(trk,(350,100))"))
    
    // SYSIN with COPY statement
    def sysin = """       PROCESS ADATA
       IDENTIFICATION DIVISION.
       PROGRAM-ID. ${member}CPY.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY ${member}.
       PROCEDURE DIVISION.
           STOP RUN.
"""
    compile.dd(new DDStatement().name("SYSIN").instreamData(sysin))
    
    // Execute
    compile.execute()
    
    return compile.maxRC()
}

/**
 * Generate Java class using IBM Record Generator
 */
def generateJavaClass(String member, String adataPDS, String javaOutputDir, String javaPackage) {
    // Download ADATA file to USS
    def ussAdataFile = "/tmp/${member}.adata"
    def copyCmd = "cp \"//'${adataPDS}(${member})'\" ${ussAdataFile}"
    
    def sh = new ShellExec().command(copyCmd)
    sh.execute()
    
    if (sh.maxRC() != 0) {
        println("   ERROR: Failed to copy ADATA file to USS")
        return sh.maxRC()
    }
    
    // Run IBM Record Generator
    def recordGenJar = props.getProperty('recordGenJar') ?: '/usr/lpp/IBM/recgen/lib/RecordGenerator.jar'
    def jzosJar = props.getProperty('jzosJar') ?: '/usr/lpp/IBM/jzos/lib/ibmjzos.jar'
    
    def javaCmd = """java -cp ${recordGenJar}:${jzosJar} \\
        com.ibm.recordgen.RecordClassGenerator \\
        adatafile=${ussAdataFile} \\
        package=${javaPackage} \\
        class=${member} \\
        symbol=${member}-RECORD \\
        outputdir=${javaOutputDir}"""
    
    sh = new ShellExec().command(javaCmd)
    sh.execute()
    
    // Cleanup
    new ShellExec().command("rm -f ${ussAdataFile}").execute()
    
    return sh.maxRC()
}

// Execute the task if called directly
if (args) {
    return execute(args)
}

// Made with Bob
