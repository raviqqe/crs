crs - combat ready status / configuration-file redistribution system
================================================================================
crs backs up and restores files and directories with vcs


License
--------------------------------------------------------------------------------
This software is in public domain.  See LICENSE file.


Installation
--------------------------------------------------------------------------------
make install

Uninstallation
--------------------------------------------------------------------------------
make uninstall


Files
--------------------------------------------------------------------------------
/usr/bin/crs - main shell script
/etc/crs.conf - crs configuration file
/var/crs - directory of repository copy


Concept
--------------------------------------------------------------------------------
crs just backs up and restores files and directories with vcs.
crs doesn't cover full operation of repository.
it should be done with each vcs command.
users should be familiar with the vcs command they use, such as svn and git.

Design
--------------------------------------------------------------------------------
[definition of terms]
subsets
  - means groups of files and directories to be backed up
  - it is also the name of the directory where the files and directories in the
    subset will be backed up and stored

[definition of abstract arguments]
<path>
  - relative path to files or directories from the directory of repository copy
  - for example when the directory of repository copy is '/var/crs' and there is
    '/var/crs/default/etc' directory the relative path is 'default/etc'.


[command usage]
crs [<option>...] <subcommand> [<option>...] [<argument>...]
- in the current implementation, all outputs of crs command are redirected to
  stderr because they doesn't have good information which other programs use.

options:
  -v
    - makes it verbose
  -q
    - makes it quiet
  -c <conffile>
    - set configuration file to <conffile>
  -m <message>
    - set <message> as commitment message
    - this option should be here because commmitment will be done in the
      subcommands, backup and remove.

subcommands:
  backup
    - backs up files and directories listed in the configuration file
    - checkout or update of the repository copy is done always before backup
    - commitment is done automatically always after backup
  restore [<path>...]
    - restores files or directories of <path>
  list <path>...
  remove <path>...
    - checkout or update of the repository copy is done always before
      removement
    - commitment is done automatically always after removement
  wrap <command>
    - executes <command> and backs up files and directories listed in the
      configutration file before and after that.
  <vcscommand> <argument>...
    - executes <vcscommand> in the directory of vcs repository copy.

[vcs module shell script]
vcs_checkout
  - checks out the repository 
vcs_update
  - updates the repository copy
vcs_add
  - makes all files and directories in the repository copy directory under
    version control
vcs_remove
  - removes files and directories in the repository copy directory
vcs_commit
  - commits all changes of files and directories in the repository copy
    directory to the remote repository


todo list
--------------------------------------------------------------------------------
- manual backup backs up files and directories as arguments
- merge subcommand
- sub directory for each user in the system?
- use awk to parse configuration file?
- permission problem
  permission should be treated and set properly.
  if there is the file or directory in the root filesystem which will be
  restored, that does not matter.
  However, if it's not, incorrect permission can be set because crs set it 
  three candedates of solution are below.
  1. vcs's function to preserve permission of files and directories
    - its availability is dependent on if vcs supports it or not.
    - uid and gid depend on the os and can be different in each system even if
      they have the same username or groupname.
  2. set the restored file's permission as the one of its parent directory
     recursively
    - this may be the correctest and properest way to set permission.
    - recursive operation can work well even when the parent directory of the
      restored file doesnt exist and then is created by crs.
