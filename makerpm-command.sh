#this is the command that would be used to build makerpm's own rpm
makerpm --copyright="GPL (or Artistic)" --runtests --noname-prefix \
    `ls makerpm-[0-9]*.tar.gz | tail -1`
#     copyright is difficult to guess / tests good / not a module, a script 
#   / latest tarball
