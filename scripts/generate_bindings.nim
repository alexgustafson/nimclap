import os, re, strutils, strformat
import tweaks
from osproc import execCmd
import std/tables

const
    projectDir = currentSourcePath().parentDir().parentDir()
    cHeadersDir = projectDir / "clap" / "include" / "clap"
    nimClapDir = projectDir / "src" / "nimclap"
    nimClapHeadersDir = nimClapDir / "clap"
    skipHeaderFiles = @["empty"]
    c2nimheader = """
#ifdef C2NIM
# suffix _t
# define CLAP_CONSTEXPR
# define CLAP_NODISCARD
# def CLAP_EXPORT
# def CLAP_ABI

#endif

#ifndef C2NIM
#  define CLAP_EXPORT __attribute__((visibility("default")))
#endif

"""


iterator nimHeaderFiles: string =
    for file in walkDirRec(nimClapHeadersDir):
        if file.match re"(?!.*_prepared)(.*\.h)":
            if not skipHeaderFiles.contains(file):
                yield file


proc prepareNimDirStructure() =

    echo "\npreparing nimclap directory structure"

    # Create the base nimclap directory if it doesn't exist
    if not dirExists(nimClapDir):
        createDir(nimClapDir)

    # Walk through the C headers directory and copy only .h files
    for cFile in walkDirRec(cHeadersDir):
        if cFile.endsWith(".h"):
            # Calculate relative path from cHeadersDir
            let relativePath = cFile.relativePath(cHeadersDir)
            let targetPath = nimClapHeadersDir / relativePath
            let targetDir = targetPath.parentDir()
            
            # Create subdirectories if they don't exist
            if not dirExists(targetDir):
                createDir(targetDir)
            
            # Copy the header file (will overwrite if exists)
            copyFile(cFile, targetPath)
            
            # Rename files with hyphens to underscores
            if "-" in targetPath.extractFilename():
                let newName = targetPath.parentDir() / targetPath.extractFilename().replace("-", "_")
                moveFile(targetPath, newName)


proc preprocessHeaderFiles() = 
    echo "\npreprocessing header files"

    for file in nimHeaderFiles():
        let filename = file.extractFilename().changeFileExt("")
        let pathToFile = file.parentDir()

        let 
            headerFile = readFile file
            headerFileLines = splitLines headerFile

        var
            rs: string

        
        rs.add c2nimheader & "\n"

        for line in headerFileLines:

            var newLine = line.replace("\ufeff", "")

            if "#include" in newLine.splitWhitespace:
                newLine = newLine.replace("-", "")

            rs.add newLine & "\n"

        writeFile(pathToFile / filename & "_prepared.h", rs)


proc convertUpperCaseToCamelCase(s: string): string =
  ## Convert UPPER_CASE_STRING to camelCase
  if s.len == 0:
    return s
  
  let parts = s.split('_')
  if parts.len == 0:
    return s
  
  # First part is lowercase
  result = parts[0].toLowerAscii()
  
  # Rest are capitalized
  for i in 1..<parts.len:
    if parts[i].len > 0:
      result &= parts[i][0].toUpperAscii() & parts[i][1..^1].toLowerAscii()


proc removeEnumPrefix(enumValue: string, enumName: string): string =
    ## Remove enum name prefix from enum values
    ## e.g., TRANSPORT_HAS_TEMPO with enum transportFlags -> hasTempo
    var value = enumValue
    
    # Try to remove common prefixes
    let enumNameUpper = enumName.toUpperAscii()
    let underscorePrefix = enumNameUpper & "_"
    
    # Remove enum name prefix if present
    if value.startsWith(underscorePrefix):
        value = value[underscorePrefix.len..^1]
    elif value.startsWith(enumNameUpper):
        value = value[enumNameUpper.len..^1]
    
    # Also try removing just the first part if it matches
    let parts = enumValue.split('_')
    if parts.len > 1:
        let firstPart = parts[0]
        # Check if first part is related to enum name
        if firstPart.toUpperAscii() in enumNameUpper or 
           enumNameUpper.contains(firstPart.toUpperAscii()):
            value = parts[1..^1].join("_")
    
    # Convert to camelCase
    result = convertUpperCaseToCamelCase(value)

proc processNimConstants(content: string): string =
    ## Process Nim file content to convert names to camelCase/PascalCase
    result = ""
    var currentEnumType = ""
    var inConst = false
    var inEnum = false
    
    for line in content.splitLines():
        var processedLine = line
        
        # Check if we're entering or leaving a const block
        if line.strip() == "const" or line.strip().startsWith("const "):
            inConst = true
        elif inConst and line.strip() != "" and not line.startsWith("  ") and not line.startsWith("\t"):
            # We've left the const block (no indentation)
            inConst = false
        
        # Check for enum type definitions to track enum context
        if line.contains("= enum") and line.contains("*"):
            inEnum = true
            # Extract enum name
            let asteriskPos = line.find("*")
            if asteriskPos > 0:
                let beforeAsterisk = line[0..<asteriskPos].strip()
                let words = beforeAsterisk.split()
                if words.len > 0:
                    currentEnumType = words[^1]
            
            # Add {.pure.} pragma to enum definitions
            if not line.contains("{.pure.}"):
                let enumPos = line.find("= enum")
                if enumPos > 0:
                    processedLine = line[0..<enumPos] & "{.pure.} = enum" & line[enumPos+6..^1]
        elif inEnum and line.strip() == "":
            inEnum = false
            currentEnumType = ""

        # Process enum values
        if inEnum and currentEnumType != "" and line.contains(" = ") and not line.contains("type"):
            let equalPos = line.find(" = ")
            if equalPos > 0:
                let beforeEqual = line[0..<equalPos]
                let afterEqual = line[equalPos..^1]
                
                # Extract the enum value name
                let trimmed = beforeEqual.strip()
                if trimmed.len > 0:
                    # Remove enum prefix and convert to camelCase
                    let newName = removeEnumPrefix(trimmed, currentEnumType)
                    let indent = beforeEqual[0..<(beforeEqual.len - trimmed.len)]
                    processedLine = indent & newName & afterEqual
        
        # Process constants in const blocks (similar to enum handling)
        elif inConst and line.contains("* =") and not line.strip().startsWith("##"):
            let equalPos = line.find(" = ")
            let asteriskPos = line.find("*")
            
            if asteriskPos > 0 and equalPos > asteriskPos:
                # Get the actual name part
                var nameStart = asteriskPos - 1
                while nameStart > 0 and line[nameStart] != ' ':
                    nameStart -= 1
                if line[nameStart] == ' ':
                    nameStart += 1
                    
                let oldName = line[nameStart..<asteriskPos]
                let newName = convertUpperCaseToCamelCase(oldName)
                
                # Also fix references in the value part
                var valuePart = line[equalPos..^1]
                # Replace references to other constants that might have been renamed
                # This is a simple approach - might need more comprehensive replacement
                
                processedLine = line[0..<nameStart] & newName & line[asteriskPos..<equalPos] & valuePart
        
        # Process let/var variables (outside const blocks)
        elif not inConst and (line.strip().startsWith("let ") or line.strip().startsWith("var ")) and line.contains("*"):
            let equalPos = line.find(" = ")
            let asteriskPos = line.find("*")
            
            if asteriskPos > 0 and (equalPos < 0 or equalPos > asteriskPos):
                # Get the actual name part
                var nameStart = asteriskPos - 1
                while nameStart > 0 and line[nameStart] != ' ':
                    nameStart -= 1
                if line[nameStart] == ' ':
                    nameStart += 1
                    
                let oldName = line[nameStart..<asteriskPos]
                let newName = convertUpperCaseToCamelCase(oldName)
                
                if equalPos > 0:
                    processedLine = line[0..<nameStart] & newName & line[asteriskPos..^1]
                else:
                    processedLine = line[0..<nameStart] & newName & line[asteriskPos..^1]
        
        # Fix template/proc references
        processedLine = processedLine.replace("version_Major", "versionMajor")
        processedLine = processedLine.replace("version_Minor", "versionMinor")
        processedLine = processedLine.replace("version_Revision", "versionRevision")
        processedLine = processedLine.replace("version_Init", "versionInit")
        processedLine = processedLine.replace("version_Lt", "versionLt")
        processedLine = processedLine.replace("version_Eq", "versionEq")
        processedLine = processedLine.replace("version_Ge", "versionGe")
        
        # Fix type references (ensure PascalCase for types)
        # Common short type names that should be PascalCase
        processedLine = processedLine.replace(": id", ": Id")
        processedLine = processedLine.replace("*: id", "*: Id")
        processedLine = processedLine.replace("let INVALID_ID*: id", "let invalidId*: Id")
        processedLine = processedLine.replace("let INVALID_ID*: Id", "let invalidId*: Id")
        
        result &= processedLine & "\n"
    
    # Remove trailing newline if present
    if result.endsWith("\n"):
        result = result[0..^2]

proc convertToNim =
    echo "\nconverting header files to nim"

    for file in nimHeaderFiles():
        let filename = file.extractFilename().changeFileExt("")
        let nimFilename = filename.replace("_", "")
        let pathToFile = file.parentDir()
        let oParam = fmt " --out={pathToFile}/{nimFilename}.nim"

        let c2nimCmd = findExe("c2nim") & fmt " --nep1 --prefix=\"clap_\" --prefix=\"CLAP_\" --dynlib --cdecl {oParam} {pathToFile}/{filename}_prepared.h"

        assert execCmd(c2nimCmd) == 0

        if nimfilename == "std":
            writeFile(pathToFile/fmt"{nimfilename}.nim", privateStd)
        elif filename == "macros":
            writeFile(pathToFile/fmt"{nimfilename}.nim", privateMacros)

        var content = readFile(pathToFile/fmt"{nimfilename}.nim")

        if additional_imports.hasKey(nimfilename):
            content = additional_imports[nimfilename] & content

        # Save c2nim raw output for debugging
        writeFile(pathToFile/fmt"{nimfilename}_c2nim_raw.nim", content)
        
        # Write initial content for nph formatting
        writeFile(pathToFile/fmt"{nimfilename}.nim", content)
        
        # Format with nph first
        let nphCmd = findExe("nph")
        if nphCmd != "":
            let formatCmd = nphCmd & " " & pathToFile/fmt"{nimfilename}.nim"
            discard execCmd(formatCmd)
            # Re-read the formatted content
            content = readFile(pathToFile/fmt"{nimfilename}.nim")
            # Save nph formatted version
            writeFile(pathToFile/fmt"{nimfilename}_nph.nim", content)

        # Process constants to convert them to camelCase
        content = processNimConstants(content)

        for replace_line in replace_strings:
            if contains(content, replace_line[0]):
                content = content.replace(replace_line[0], replace_line[1])
        
        # Write the final content
        writeFile(pathToFile/fmt"{nimfilename}.nim", content)



proc removeStageFiles =
    echo "\nremoving c header files"

    for file in nimHeaderFiles():
        let filename = file.extractFilename().changeFileExt("")
        let pathToFile = file.parentDir()
        removeFile(pathToFile / filename & "_prepared.h")
        removeFile(pathToFile / filename & ".h")
        removeFile(pathToFile / filename.replace("_", "") & "_c2nim_raw.nim")
        removeFile(pathToFile / filename.replace("_", "") & "_nph.nim")


when isMainModule:
    prepareNimDirStructure()
    preprocessHeaderFiles()
    convertToNim()
    removeStageFiles()
