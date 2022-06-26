from os import `/`,
  createDir, removeDir, parentDir,
  copyDir, findExe, extractFilename,
  changeFileExt

import strformat
import strutils
from osproc import execCmd


const
  projectDir      = currentSourcePath().parentDir().parentDir()
  nimclapDir      = projectDir/"src"/"nimclap"
  clapSourceDir   = "clap"/"include"/"clap"
  nimclapHeadersDir  = nimclapDir/"clap"
  clapSourceFiles = [
    nimclapHeadersDir/"audio-buffer.h",
    nimclapHeadersDir/"clap.h",
    nimclapHeadersDir/"color.h",
    nimclapHeadersDir/"entry.h",
    nimclapHeadersDir/"events.h",
    nimclapHeadersDir/"fixedpoint.h",
    nimclapHeadersDir/"id.h",
    nimclapHeadersDir/"plugin.h",
    nimclapHeadersDir/"string-sizes.h",
  ]
  c2nimheader = """
#ifdef C2NIM
#  nep1
# define CLAP_CONSTEXPR
#endif
"""


proc genDirStructure =
  removeDir(nimclapDir)
  createDir(nimclapDir)
  copyDir(clapSourceDir, nimclapHeadersDir)


proc preprocessHeaderFiles() =

  echo "\nPreprocessing Header Files"

  for filepath in clapSourceFiles:
    let filename = filepath.extractFilename.changeFileExt("")

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
        words = line.splitWhitespace

      i.inc
      rs.add line & "\n"

    writeFile(nimclapHeadersDir/fmt"{filename}_modified.h", rs)


proc convertToNim() =

  echo "\nExecuting c2nim"

  for filepath in clapSourceFiles:
    let filename = filepath.extractFilename.changeFileExt("")
    let outparam = fmt" --out={nimclapHeadersDir}/{filename}.nim"
    let c2nimcmd = findExe("c2nim") & fmt" {outparam} " & nimclapHeadersDir/fmt"{filename}_modified.h"
    echo c2nimcmd & "\n"
    assert execCmd(c2nimcmd) == 0


proc main =
  genDirStructure()
  preprocessHeaderFiles()
  convertToNim()


when isMainModule:
  main()