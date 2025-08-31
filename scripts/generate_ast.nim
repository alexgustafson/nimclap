import os, strutils, strformat, osproc

proc generateAstUsingCompiler(filename: string): string =
  ## Use nim compiler to generate AST
  if not fileExists(filename):
    return fmt"Error: File '{filename}' does not exist"
  
  # Create a temporary file with the macro wrapper
  let tempFile = getTempDir() / "temp_ast_gen.nim"
  let code = readFile(filename)
  
  let wrapperCode = """
import std/macros

macro showAst(code: untyped): untyped =
  echo treeRepr(code)
  result = newEmptyNode()

showAst:
""" & indent(code, 2)
  
  writeFile(tempFile, wrapperCode)
  
  # Compile and run the temporary file
  let (output, exitCode) = execCmdEx(fmt"nim c -r --hints:off {tempFile}")
  
  # Clean up
  try:
    removeFile(tempFile)
    removeFile(tempFile.changeFileExt("exe"))
  except:
    discard  # Ignore cleanup errors
  
  if exitCode != 0:
    return fmt"Error compiling file:\n{output}"
  
  result = output

when isMainModule:
  let args = commandLineParams()
  
  if args.len == 0:
    echo "Usage: generate_ast <nim_file> [output_file]"
    echo "  nim_file    - Path to the Nim file to analyze"
    echo "  output_file - Output file for AST (optional, defaults to <nim_file>.ast.txt)"
    quit(1)
  
  let inputFile = args[0]
  let outputFile = if args.len > 1: args[1] else: inputFile.changeFileExt("") & ".ast.txt"
  
  if not fileExists(inputFile):
    echo fmt"Error: Input file '{inputFile}' does not exist"
    quit(1)
  
  echo fmt"Generating AST for: {inputFile}"
  
  let astContent = generateAstUsingCompiler(inputFile)
  
  if astContent.len == 0:
    echo "Warning: No AST output generated. The file might be empty or have syntax errors."
  
  try:
    writeFile(outputFile, astContent)
    echo fmt"AST written to: {outputFile}"
    echo fmt"Output size: {astContent.len} bytes"
  except IOError as e:
    echo fmt"Error writing to file '{outputFile}': {e.msg}"
    quit(1)