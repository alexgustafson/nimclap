##  Define CLAP_EXPORT

when defined(_MSVC_LANG):
  const
    CLAP_CPLUSPLUS* = _MSVC_LANG
elif defined(__cplusplus):
  discard
## !!!Ignored construct:  # defined ( __cplusplus ) && __cplusplus >= 201103L [NewLine] # [NewLine] # [NewLine] # [NewLine] # [NewLine] # [NewLine] # defined ( __cplusplus ) && __cplusplus >= 201703L [NewLine] # CLAP_HAS_CXX17 [NewLine] # nodiscard [NewLine] # [NewLine] # [NewLine] # [NewLine] # defined ( __cplusplus ) && __cplusplus >= 202002L [NewLine] # CLAP_HAS_CXX20 [NewLine] # [NewLine]
## Error: identifier expected, but got: [NewLine]!!!
