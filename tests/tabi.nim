## ABI drift gate for `nimble test`.
##
## Fails when the checked-out CLAP submodule headers no longer match the
## reviewed baseline recorded in tests/clap_abi.baseline. When that happens,
## run `nimble check_abi` to see exactly which headers changed and which Nim
## bindings need to be updated, then `nimble bless_abi` once reconciled.

import abi_tracker

when isMainModule:
  if not abiInSync():
    discard report()
    quit(1)
  echo "CLAP ABI in sync with reviewed baseline."
