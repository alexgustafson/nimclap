## CLAP ABI tracker
## =================
##
## The Nim bindings under ``src/nimclap/clap`` are hand-maintained. Their
## comments have been translated once from the upstream CLAP C headers and only
## need to be revisited when the upstream ABI/headers actually change.
##
## This module leverages git to detect those changes. The upstream headers live
## in the ``clap/`` git submodule, pinned to a specific commit. The commit that
## the current bindings were last reviewed against - together with a content
## hash (git blob id) for every header - is recorded in
## ``tests/clap_abi.baseline``.
##
## Workflow:
##   * ``nimble update_clap``  - pull the latest CLAP headers, then report drift.
##   * ``nimble check_abi``    - report which headers changed since the baseline
##                               (and which Nim files therefore need review).
##   * ``nimble bless_abi``    - once the bindings have been updated to match the
##                               current submodule commit, record it as the new
##                               reviewed baseline.
##
## ``nimble check_abi`` is purely informational: it prints the report and always
## exits cleanly. The fail-on-drift gate lives in ``tests/tabi.nim`` (run by
## ``nimble test``), which exits non-zero when the headers no longer match the
## reviewed baseline.

import std/[os, osproc, strutils, tables, algorithm]

const
  headersPrefix = "include/clap/"

let
  projectDir* = currentSourcePath().parentDir().parentDir()
  clapDir* = projectDir / "clap"
  baselineFile* = projectDir / "tests" / "clap_abi.baseline"

type
  Snapshot* = object
    commit*: string                 ## clap submodule commit (may be "" if unknown)
    version*: string                ## human readable CLAP version, e.g. "1.2.6"
    blobs*: OrderedTable[string, string]  ## header path (relative to clap repo) -> git blob id

  ChangeKind* = enum
    ckAdded, ckRemoved, ckChanged

  Change* = object
    kind*: ChangeKind
    path*: string                   ## header path relative to the clap repo

proc git(args: openArray[string]): tuple[output: string, code: int] =
  ## Run ``git -C clap <args>`` and capture stdout (stderr merged).
  let full = @["-C", clapDir] & @args
  let res = execProcess("git", args = full, options = {poStdErrToStdOut, poUsePath})
  # execProcess does not surface the exit code, so probe separately when needed.
  result.output = res
  result.code = 0

proc gitCode(args: openArray[string]): int =
  ## Run git and return only the exit code (output discarded).
  let full = @["-C", clapDir] & @args
  let p = startProcess("git", args = full, options = {poStdErrToStdOut, poUsePath})
  result = p.waitForExit()
  p.close()

proc nimBindingFor*(headerPath: string): string =
  ## Map an upstream header path (``include/clap/ext/foo-bar.h``) to the Nim
  ## binding that mirrors it (``src/nimclap/clap/ext/foobar.nim``).
  var rel = headerPath
  if rel.startsWith(headersPrefix):
    rel = rel[headersPrefix.len .. ^1]
  rel = rel.replace("-", "")
  if rel.endsWith(".h"):
    rel = rel[0 ..< rel.len - 2] & ".nim"
  result = "src/nimclap/clap/" & rel

proc readClapVersion(): string =
  ## Parse CLAP_VERSION_{MAJOR,MINOR,REVISION} from the submodule's version.h.
  let vh = clapDir / "include" / "clap" / "version.h"
  if not fileExists(vh):
    return "unknown"
  var major, minor, rev = "?"
  for line in lines(vh):
    let s = line.strip()
    if s.startsWith("#define CLAP_VERSION_MAJOR"):
      major = s.splitWhitespace()[^1]
    elif s.startsWith("#define CLAP_VERSION_MINOR"):
      minor = s.splitWhitespace()[^1]
    elif s.startsWith("#define CLAP_VERSION_REVISION"):
      rev = s.splitWhitespace()[^1]
  result = major & "." & minor & "." & rev

proc currentSnapshot*(): Snapshot =
  ## Build a snapshot of the currently checked-out CLAP submodule headers.
  if not dirExists(clapDir / "include"):
    raise newException(IOError,
      "CLAP submodule not checked out at '" & clapDir & "'.\n" &
      "Run: git submodule update --init clap")
  result.blobs = initOrderedTable[string, string]()
  result.commit = git(["rev-parse", "HEAD"]).output.strip()
  result.version = readClapVersion()
  let lsTree = git(["ls-tree", "-r", "HEAD", "--", headersPrefix.strip(chars = {'/'})]).output
  for line in lsTree.splitLines():
    if line.len == 0:
      continue
    # format: "<mode> blob <sha>\t<path>"
    let tabIdx = line.find('\t')
    if tabIdx < 0:
      continue
    let meta = line[0 ..< tabIdx].splitWhitespace()
    let path = line[tabIdx + 1 .. ^1].strip()
    if meta.len >= 3 and meta[1] == "blob":
      result.blobs[path] = meta[2]
  result.blobs.sort(proc(a, b: (string, string)): int = cmp(a[0], b[0]))

proc parseBaseline*(): Snapshot =
  ## Read the reviewed baseline snapshot. Returns an empty snapshot (no blobs)
  ## when the baseline file does not yet exist.
  result.blobs = initOrderedTable[string, string]()
  if not fileExists(baselineFile):
    return
  for line in lines(baselineFile):
    let s = line.strip()
    if s.len == 0 or s.startsWith("#"):
      continue
    if s.startsWith("commit "):
      result.commit = s.splitWhitespace()[^1]
    elif s.startsWith("version "):
      result.version = s.splitWhitespace()[^1]
    else:
      # "<blobsha>\t<path>"
      let tabIdx = line.find('\t')
      if tabIdx > 0:
        let sha = line[0 ..< tabIdx].strip()
        let path = line[tabIdx + 1 .. ^1].strip()
        result.blobs[path] = sha

proc writeBaseline*(snap: Snapshot) =
  var s = ""
  s.add "# CLAP ABI baseline - generated, do not edit by hand.\n"
  s.add "# Update with `nimble bless_abi` after reconciling the bindings.\n"
  s.add "version " & snap.version & "\n"
  s.add "commit " & snap.commit & "\n"
  s.add "# <git-blob-id>\\t<header path relative to clap repo>\n"
  for path, sha in snap.blobs.pairs:
    s.add sha & "\t" & path & "\n"
  writeFile(baselineFile, s)

proc diff*(baseline, current: Snapshot): seq[Change] =
  ## Compute per-header differences between two snapshots based on git blob ids.
  for path, sha in current.blobs.pairs:
    if path notin baseline.blobs:
      result.add Change(kind: ckAdded, path: path)
    elif baseline.blobs[path] != sha:
      result.add Change(kind: ckChanged, path: path)
  for path in baseline.blobs.keys:
    if path notin current.blobs:
      result.add Change(kind: ckRemoved, path: path)
  result.sort(proc(a, b: Change): int = cmp(a.path, b.path))

proc baselineCommitAvailable(commit: string): bool =
  ## Whether the recorded baseline commit's objects exist locally (needed to
  ## render a textual diff).
  if commit.len == 0:
    return false
  gitCode(["cat-file", "-e", commit & "^{commit}"]) == 0

proc abiInSync*(): bool =
  ## True when the current submodule headers match the reviewed baseline.
  let baseline = parseBaseline()
  if baseline.blobs.len == 0:
    return false
  diff(baseline, currentSnapshot()).len == 0

proc report*(): int {.discardable.} =
  ## Print a human readable drift report. Returns a process exit code.
  let baseline = parseBaseline()
  let current = currentSnapshot()

  echo "CLAP ABI tracker"
  echo "  clap submodule : ", clapDir
  echo "  current        : ", current.version, "  (", current.commit[0 ..< min(12, current.commit.len)], ")"

  if baseline.blobs.len == 0:
    echo ""
    echo "  No baseline recorded yet."
    echo "  Run `nimble bless_abi` once the bindings match the current headers."
    return 1

  echo "  reviewed       : ", baseline.version, "  (", baseline.commit[0 ..< min(12, baseline.commit.len)], ")"

  let changes = diff(baseline, current)
  if changes.len == 0:
    echo ""
    echo "  In sync - all ", current.blobs.len, " headers match the reviewed baseline."
    return 0

  echo ""
  echo "  ", changes.len, " header(s) changed since the last reviewed baseline:"
  echo ""
  for c in changes:
    let tag = case c.kind
      of ckAdded:   "ADDED   "
      of ckRemoved: "REMOVED "
      of ckChanged: "CHANGED "
    echo "  ", tag, c.path
    if c.kind != ckRemoved:
      echo "          -> review/update ", nimBindingFor(c.path)
    else:
      echo "          -> consider removing  ", nimBindingFor(c.path)

  # Best-effort textual diff so the reviewer can see exactly what changed.
  if baseline.commit.len > 0 and baseline.commit != current.commit:
    echo ""
    if baselineCommitAvailable(baseline.commit):
      echo "  --- diff ", baseline.commit[0 ..< 12], "..", current.commit[0 ..< 12], " (", headersPrefix, ") ---"
      echo git(["--no-pager", "diff", baseline.commit & ".." & current.commit,
                "--", headersPrefix.strip(chars = {'/'})]).output
    else:
      echo "  (Textual diff unavailable: baseline commit ", baseline.commit[0 ..< 12],
           " is not present locally.)"
      echo "  Fetch it with: git -C clap fetch origin ", baseline.commit

  echo ""
  echo "  After updating the affected bindings above, run `nimble bless_abi`."
  return 1

proc bless(): int =
  let snap = currentSnapshot()
  writeBaseline(snap)
  echo "Recorded reviewed baseline:"
  echo "  version ", snap.version
  echo "  commit  ", snap.commit
  echo "  headers ", snap.blobs.len
  echo "  file    ", baselineFile
  return 0

when isMainModule:
  let cmd = if paramCount() >= 1: paramStr(1) else: "check"
  case cmd
  of "check":
    # Informational: print the drift report and always exit cleanly.
    # The fail-on-drift gate lives in tests/tabi.nim (run by `nimble test`).
    discard report()
  of "bless":
    discard bless()
  else:
    echo "usage: abi_tracker [check|bless]"
    quit(2)
