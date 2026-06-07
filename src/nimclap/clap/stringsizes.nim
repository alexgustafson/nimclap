const
  nameSize* = 256
    ## String capacity for names that can be displayed to the user.
  pathSize* = 1024
    ## String capacity for describing a path, like a parameter in a module
    ## hierarchy or path within a set of nested track groups.
    ##
    ## This is not suited for describing a file path on the disk, as NTFS allows
    ## up to 32K long paths.
