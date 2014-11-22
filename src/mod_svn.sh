# mod_svn.sh
#
# this file is also a reference implementation of these vcs functions 
#
# functions:
#  vcs_checkout
#  vcs_update
#  vcs_add
#  vcs_remove
#  vcs_commit
#  

##########################
# vcs specific functions #
##########################

## vcs_checkout
# - checkout subcommand must be executed only if the vcs directory is not checked out
# - vcs_checkout returns 1 when it did not check out repository copy
vcs_checkout() {
  if [ -d "${VCSROOT}/.svn" ]
  then
    return 1
  else
    svn checkout "$URL" $VCSROOT
  fi
}

## vcs_update
vcs_update() {
  svn update $VCSROOT
}

## vcs_add <path>...
# - <path>'s format is <subsetname><fullpath>, such as linux/etc/rc.conf
vcs_add() {
  (
    cd $VCSROOT
    svn add "$@"
  )
}

## vcs_remove $path
vcs_remove() {
  svn delete "$@"
}

## vcs_commit
vcs_commit() {
  svn commit -m "$MESSAGE" $VCSROOT
}
