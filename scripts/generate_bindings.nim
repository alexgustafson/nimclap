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


proc removeAndCreateDirStructure() =

    echo "\ncreating nimclap directory structure"

    removeDir(nimClapDir)
    createDir(nimClapDir)
    copyDir(cHeadersDir, nimClapHeadersDir) 

    for file in nimHeaderFiles():
        let filename = file.extractFilename()
        let filePath = file.parentDir()

        moveFile(file, filepath / filename.replace("-", "_"))


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



proc convertToNim =
    echo "\nconverting header files to nim"

    for file in nimHeaderFiles():
        let filename = file.extractFilename().changeFileExt("")
        let nimFilename = filename.replace("_", "")
        let pathToFile = file.parentDir()
        let oParam = fmt " --out={pathToFile}/{nimFilename}.nim"

        let c2nimCmd = findExe("c2nim") & fmt " --dynlib --cdecl {oParam} {pathToFile}/{filename}_prepared.h"

        assert execCmd(c2nimCmd) == 0

        var content = readFile(pathToFile/fmt"{nimfilename}.nim")

        if additional_imports.hasKey(nimfilename):
            content = additional_imports[nimfilename] & content

        for replace_line in replace_strings:
            if contains(content, replace_line[0]):
                content = content.replace(replace_line[0], replace_line[1])

        writeFile(pathToFile/fmt"{nimfilename}.nim", content)


proc removeCHeaderFiles =
    echo "\nremoving c header files"

    for file in nimHeaderFiles():
        let filename = file.extractFilename().changeFileExt("")
        let pathToFile = file.parentDir()

        removeFile(pathToFile / filename & "_prepared.h")
        removeFile(pathToFile / filename & ".h")



when isMainModule:
    removeAndCreateDirStructure()
    preprocessHeaderFiles()
    convertToNim()
    removeCHeaderFiles()
