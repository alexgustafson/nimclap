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

            # Move inline comments to separate lines for better c2nim handling
            let trimmedLine = newLine.strip()
            if trimmedLine.len > 0 and not trimmedLine.startsWith("//") and not trimmedLine.startsWith("/*") and not trimmedLine.startsWith("*"):
                # Look for inline comments (// or /* style)
                let commentPos = max(newLine.find("//"), newLine.find("/*"))
                if commentPos > 0:  # Found inline comment (not at start)
                    let codePart = newLine[0..<commentPos].strip()
                    let commentPart = newLine[commentPos..^1].strip()
                    let indentation = newLine[0..<(newLine.len - trimmedLine.len)]
                    
                    # Special handling for enum values and similar patterns
                    if codePart.contains("=") or codePart.endsWith(",") or codePart.endsWith(";"):
                        # For enum values, typedefs, etc., put comment before the line
                        rs.add indentation & "// " & commentPart[2..^1].strip() & "\n"
                        rs.add indentation & codePart & "\n"
                    else:
                        # For other cases, keep as separate comment line
                        rs.add indentation & commentPart & "\n"
                        rs.add indentation & codePart & "\n"
                else:
                    rs.add newLine & "\n"
            else:
                rs.add newLine & "\n"

        writeFile(pathToFile / filename & "_prepared.h", rs)



proc convertToNim =
    echo "\nconverting header files to nim"

    for file in nimHeaderFiles():
        let filename = file.extractFilename().changeFileExt("")
        let nimFilename = filename.replace("_", "")
        let pathToFile = file.parentDir()
        let oParam = fmt " --out={pathToFile}/{nimFilename}.nim"

        let c2nimCmd = findExe("c2nim") & fmt " --dynlib --cdecl {oParam} {pathToFile}/{filename}_prepared.h"

        assert execCmd(c2nimCmd) == 0

        if nimfilename == "std":
            writeFile(pathToFile/fmt"{nimfilename}.nim", privateStd)
        elif filename == "macros":
            writeFile(pathToFile/fmt"{nimfilename}.nim", privateMacros)

        var content = readFile(pathToFile/fmt"{nimfilename}.nim")

        if additional_imports.hasKey(nimfilename):
            content = additional_imports[nimfilename] & content

        for replace_line in replace_strings:
            if contains(content, replace_line[0]):
                content = content.replace(replace_line[0], replace_line[1])

        # Write the generated content to the file
        writeFile(pathToFile/fmt"{nimfilename}.nim", content)


proc removeCHeaderFiles =
    echo "\nremoving c header files"

    for file in nimHeaderFiles():
        let filename = file.extractFilename().changeFileExt("")
        let pathToFile = file.parentDir()

        removeFile(pathToFile / filename & "_prepared.h")
        removeFile(pathToFile / filename & ".h")



when isMainModule:
    prepareNimDirStructure()
    preprocessHeaderFiles()
    convertToNim()
    removeCHeaderFiles()
