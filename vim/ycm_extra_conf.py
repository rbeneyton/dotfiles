import os
import ycm_core

def DirectoryOfThisScript():
  return os.path.dirname( os.path.abspath( __file__ ) )

def FlagsForFile( filename ):
  suf = filename.split('.')[-1]
  if suf == 'blk' or suf == 'c' or suf == 'h':
      fname = '.syntastic_c_config'
  if suf == 'blkk' or suf == 'cpp':
      fname = '.syntastic_cpp_config'

  with open(DirectoryOfThisScript() + '/' + fname, 'r') as f:
      flags = f.read().split()

  return {
    'flags': flags,
    'do_cache': True
  }
