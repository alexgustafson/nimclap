from os import `/`,
  createDir, removeDir, parentDir,
  copyDir, findExe, extractFilename,
  changeFileExt, removeFile, walkFiles,
  moveFile, walkDirRec
import re
import strformat
import strutils
import sequtils
from osproc import execCmd




const
  projectDir      = currentSourcePath().parentDir().parentDir()
  nimclapDir      = projectDir/"src"/"nimclap"
  clapSourceDir   = "clap"/"include"/"clap"
  nimclapHeadersDir: string = nimclapDir/"clap"
  skipHeaderFiles = @[
    nimclapHeadersDir/"private"/"macros.h"
  ]

  c2nimheader = """
#ifdef C2NIM
#  nep1
# define CLAP_CONSTEXPR
#endif
"""



iterator  clapHeaderFiles: string {.closure.} =
  for file in walkDirRec nimclapHeadersDir:
    if file.match re"(?!.*_modified)(.*\.h)":
      if not skipHeaderFiles.contains(file):
        yield file


proc genDirStructure =
  removeDir(nimclapDir)
  createDir(nimclapDir)
  copyDir(clapSourceDir, nimclapHeadersDir)

  for file in clapHeaderFiles:
    let filename = file.extractFilename()
    let filepath = file.parentDir()

    moveFile(file, filepath/filename.replace("-", "_"))


proc preprocessHeaderFiles() =

  echo "\nPreprocessing Header Files"

  for filepath in clapHeaderFiles:
    let filename = filepath.extractFilename.changeFileExt("")
    let pathToFile = filepath.parentDir()

    let
      headerFile = readFile(filepath)
      headerFileLines = headerFile.splitLines

    var
      rs: string

    rs.add c2nimheader & "\n"

    var i = 0
    while i < headerFileLines.len:
      let
        line = headerFileLines[i]
        # words = line.splitWhitespace

      i.inc
      rs.add line & "\n"

    writeFile(pathToFile/fmt"{filename}_modified.h", rs)


proc convertToNim() =

  echo "\nExecuting c2nim"

  for filepath in clapHeaderFiles:
    let filename = filepath.extractFilename.changeFileExt("")
    let nimfilename = filename.replace("-", "_")
    let pathToFile = filepath.parentDir()
    let outparam = fmt" --out={pathToFile}/{nimfilename}.nim"
    let c2nimcmd = findExe("c2nim") & fmt" {outparam} " & pathToFile/fmt"{filename}_modified.h"
    echo c2nimcmd & "\n"
    assert execCmd(c2nimcmd) == 0

    removeFile(pathToFile/fmt"{filename}_modified.h")
    removeFile(pathToFile/fmt"{filename}.h")


proc main =
  genDirStructure()
  preprocessHeaderFiles()
  convertToNim()


when isMainModule:
  main()