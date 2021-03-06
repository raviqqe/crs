# mod_git.sh
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
vcs_checkout() {
  if [ -d "${VCSROOT}/.git" ]
  then
    return 1
  else
    git clone "$URL" $VCSROOT
  fi
}

## vcs_update
vcs_update() {
  (
    cd $VCSROOT
    git pull
  )
}

## vcs_add <path>...
# - <path>'s format is <subsetname><fullpath>, such as linux/etc/rc.conf
vcs_add() {
  (
    cd $VCSROOT
    git add "$@"
  )
}

## vcs_remove <path>...
vcs_remove() {
  git rm -r "$@"
}

## vcs_commit
vcs_commit() {
  (
    cd $VCSROOT
    git add *
    git commit -m "$MESSAGE"
    git push origin master
  )
}
