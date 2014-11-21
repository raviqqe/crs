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
    git clone "$url" $VCSROOT
  fi
}

## vcs_update
vcs_update() {
  git pull $VCSROOT
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
  git rm "$@"
}

## vcs_commit
vcs_commit() {
  git commit -m "$MESSAGE" $VCSROOT
  git push origin master
}
