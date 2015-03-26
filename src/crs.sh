#!/bin/sh

# crs - combat ready status
# back up and restore files easily

# characters not available in configuration file
# ; (lines which include =)
# %, = (path name)
# /, = (subset name)


## global variables
NAME='crs'
VERBOSE=0
QUIET=0
DFLTSUBSET='default'
VALIDVCSC='svn git'
URL=
VCSC=
MESSAGE="commitment from `hostname`-`uname`"
: ${PATH:='/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'}
CONFFILE="/usr/local/etc/${NAME}.conf"
VCSROOT="/usr/local/var/${NAME}"
LIBXPATH="/usr/local/libexec/${NAME}"
readonly NAME PATH VCSROOT LIBXPATH


#####################
# message functions #
#####################

# print usual message
printout() {
  test $QUIET -eq 0 &&
    echo "${NAME}:" "$@" >&2
}

# print error message to stderr
printerr() {
  echo "${NAME}: error:" "$@" >&2
}

# print error message and exit
fail() {
  printerr "$@"
  exit 1
}

# verbose option
verbose() {
  test $VERBOSE -eq 1 &&
    printout "$@"
}

##################
# misc utilities #
##################

# check_filename <filename>
check_filename() {
  test -z "`echo "$1" | grep '^/'`" &&
    fail "paths of files backed up must be full paths: $1"
  test "$1" = '/' -o "$1" = '/var' -o "$1" = "$VCSROOT" &&
    fail "$VCSROOT cannot be backed up"
  test -n "`echo "$1" | grep '%'`" &&
    fail "paths of files backed up cannot contain any percentage sign %: $1"
}

# check_subsetname <subsetname>
check_subsetname() {
  test -n "`echo "$1" | grep '/'`" &&
    fail "names of subsets cannot contain any slash /: $1"
}

# create_dir <directory>
# required by: copy_one_file()
create_dir() {
  test -n "$2" &&
    fail "create_dir(): invalid argument: $2"
  test "$1" = '.' -o "$1" = "$VCSROOT" &&
    fail "create_dir(): invalid argument: $1"

  pdir=`dirname "$1"`
  test -d "$pdir" ||
    create_dir "$pdir"
  mkdir "$1"
  vcs_add "$1"
}

# copy_one_file <file> <dest>
# required by: copy_files(), merge()
# both absolute and relative paths are available
copy_one_file() {
  new=$2'/'`basename $1`
  test -f "$new" -o -d "$new" &&
    exist=1 || exist=0
  test -d "$2" ||
    create_dir "$2"
  cp -R "$1" "$2"
  test $exist -eq 0 &&
    vcs_add "$new"
}


###############
# subcommands #
###############

## backup [[-s <subset>] <path>...]
# copy files to vcs repository directory

# copy_files <subset> <file>...
copy_files() {
  subset=$1
  shift
  (
    cd $VCSROOT
    for leaf in `eval find "$@"`
    do
      test -d "$leaf" -a -n "`ls -A $leaf`" && continue
      dest=`dirname "$subset$leaf"`
      copy_one_file "$leaf" "$dest"
    done
  )
}

backup() {
  vcs_checkout || vcs_update ||
    fail "cannot checkout the repository, $URL"
  printout 'starting backup...'

  if [ -z "$*" ]
  then
    # create a temporary configuration file,
    # which includes just the list of files and directories to be backed up
    tmpconf='/tmp/'"`basename ${CONFFILE}`"".$$.tmp"
    : > $tmpconf
    cat $CONFFILE | sed -e 's/^#.*$//g' -e 's/[[:blank:]]#.*$//g' | grep -v -e '=' -e '^[[:blank:]]*$' |
    while read line
    do
      # the following command parses variables but does not do any wildcard
      eval echo \""$line"\" >> $tmpconf
    done

    linenum=0
    exec 3< $tmpconf # open temporary configuration file as file descriptor 3
    while read file subset rest <&3
    do
      linenum=`expr $linenum + 1`
      check_subsetname "$subset"

      copy_files "${subset:-$DFLTSUBSET}" "$file"
    done
    exec 3<&- # close temporary configuration file
    rm $tmpconf
  else
    while getopts s: option
    do
      case "$option" in
        s)
          subset=$OPTARG
          ;;
        *)
          fail "invalid option: -$option"
          ;;
      esac
    done
    shift `expr "$OPTIND" - 1`
    test -z "$*" &&
      fail "usage: $NAME backup [[-s <subset>] <path>...]"

    copy_files "${subset:-$DFLTSUBSET}" "$@"
  fi

  vcs_commit
  printout 'backup completed!'
}

## restore [<path>...]
# exist_dir <fullpathtodir>
exist_dir() {
  if [ -d "$1" ]
  then
    ugid=`stat -f %u:%g "$1"`
    perm=`stat -f %p "$1" | sed 's/.*\(...\)/\1/'`
  else
    exist_dir `dirname "$1"`
    mkdir "$1"
    chown "$ugid" "$1"
    chmod "$perm" "$1"
  fi
}

restore() {
  vcs_checkout || vcs_update ||
    fail "cannot check out the repository, $URL"
  printout 'starting restoration...'
  if [ -z "$*" ]
  then
    set "$DFLTSUBSET"
  fi
  for path
  do
    echo "$path" | grep '^/' > /dev/null &&
      fail "the first characters of arguments as paths must not be slash /"

    printout "restoring $path"
    echo "$path" | grep '/[^/]' > /dev/null ||
      path="${path}/*"
    for leaf in `find ${VCSROOT}/${path}` # parse wildcards in $path here
    do
      test -d "$leaf" -a -n "`ls -A "$leaf"`" && continue
      real="`echo "$leaf" | sed "s%^${VCSROOT}/[^/]*%%g"`"
      dest="`dirname "$real"`"
      verbose "copying $leaf to $dest"
      if [ -f "$real" -o -d "$real" ]
      then
        cp -R "$leaf" "$dest"
      else
        ugid=
        perm=
        exist_dir "$dest"
        cp -R "$leaf" "$dest"
        chown -R "$ugid" "$real"
        chmod -R "$perm" "$real"
      fi
    done
  done
  printout 'restoration completed!'
}

## remove <path>...
remove() {
  vcs_update
  (
    cd $VCSROOT
    for path
    do
      test -n "`echo "$path" | grep '^/'`" &&
        fail "invalid path as argument: $path"
      for file in $path
      do
        if [ -f "$file" -o -d "$file" ]
        then
          vcs_remove "$file"
        else
          printerr "no such file or directory: $file"
        fi
      done
    done
  ) || exit 1
  vcs_commit
}

## merge <path>... <subset>
merge() {
  printout 'starting merger...'
  eval subset=\$$#
  check_subsetname "$subset"

  (
    cd $VCSROOT
    for path
    do
      test "$path" = "$subset" && continue
      printout "copying $path to $subset"

      test -n "`echo "$path" | grep '/[^/]'`" ||
        path="${path}/*"
      test -n "`echo "$path" | grep '%'`" &&
        fail "paths of files backed up cannot contain any percentage sign %: $path"
      test -n "`echo "$path" | grep '^/'`" &&
        fail "invalid path: $path"

      for leaf in `find $path`
      do
        test -d "$leaf" -a -n "`ls -A $leaf`" && continue
        dest=$subset`echo "$leaf" | sed 's%^[^/]*%%'`
        dest=`dirname "$dest"`
        verbose "copying $leaf to $dest"
        copy_one_file "$leaf" "$dest"
      done
    done
  )

  vcs_commit
  printout 'merger completed!'
}

## list [<path>...]
list() {
  (
    cd $VCSROOT
    eval ls "$@"
  )
}

## wrap <command> <argument>...
wrap() {
  before=1
  after=1
  while getopts ba option
  do
    case "$option" in
      b)
        before=0
        ;;
      a)
        after=0
        ;;
      *)
        fail "invalid option: -$option"
        ;;
    esac
  done
  shift `expr "$OPTIND" - 1`
  test -z "$*" &&
    fail "usage: $NAME wrap [<options>...] [<argument>...]"

  test $before -eq 1 && {
    MESSAGE="$MESSAGE before $1"
    vcs_commit
  }
  eval "$@"
  test $after -eq 1 && {
    MESSAGE="$MESSAGE after $1"
    vcs_commit
  }
}

## cd_vcsc <argument>...
cd_vcsc() {
  (
    cd $VCSROOT
    eval $VCSC "$@" # eval to parse wildcards
  )
}


#############
# main dish #
#############

# parse options and arguments
while getopts vc:m: option
do
  case $option in
    v)
      VERBOSE=1
      ;;
    q)
      QUIET=1
      ;;
    c)
      # set configuration file
      test -f "$OPTARG" ||
        fail "configuration file, $OPTARG does not exist"
      CONFFILE=$OPTARG
      ;;
    m)
      # set commitment message
      test -z "$OPTARG" &&
        fail 'commitment message is not set'
      MESSAGE=$OPTARG
      ;;
    *)
      fail "invalid option: -$option"
      ;;
  esac
done
shift `expr "$OPTIND" - 1`
test -z "$*" &&
  fail "usage: $NAME [<option>...] <subcommand> [<argument>...]"

## parse the configuration file
# check if configuration file exists
test -f "$CONFFILE" ||
  fail "configuration file, $CONFFILE does not exist"

# set the $url, $vcs, and other variables
eval "`cat $CONFFILE | grep '='`"
  # even if the result of grep is multi-line or includes commments the above would succeed
if [ -z "$url" ]
then
  printerr "the 'url' variable is not set in $CONFFILE"
  printerr 'set url variable like the below'
  fail "url=svn://example.com/$NAME"
fi
URL=$url

if [ -n "$vcs" -a -n "`echo "$VALIDVCSC" | grep "$vcs"`" ]
then
  VCSC=$vcs
else
  printerr "the 'vcs' variable is not set or invalid in $CONFFILE"
  fail "available vcs commands are 'svn' and 'git'"
fi

## check if vcs directory exists
test -d $VCSROOT ||
  fail "vcs repository copy, $VCSROOT does not exist"

## load modules
tmp=${LIBXPATH}'/mod_'${VCSC}'.sh'
if [ -f $tmp ]
then
  . $tmp
else
  fail "no such module: $tmp"
fi

## parse subcommands
case $1 in
  backup | bu | withdraw | wd)
    shift
    backup "$@"
    ;;
  restore | rs | deploy | dp)
    shift
    restore "$@"
    ;;
  ls | list)
    shift
    list "$@"
    ;;
  rm | remove)
    shift
    test -z "$*" &&
      fail "usage: $NAME remove <path>..."
    remove "$@"
    ;;
  merge | mg)
    shift
    test -z "$*" &&
      fail "usage: $NAME merge <path>... <subset>"
    merge "$@"
    ;;
  ${VCSC})
    shift
    cd_vcsc "$@"
    ;;
  wrap | wr)
    shift
    wrap "$@"
    ;;
  checkout | co)
    test -n "$2" &&
      fail "invalid argument: $2"
    vcs_checkout ||
      printout "repository copy is already checked out"
    ;;
  update | up)
    test -n "$2" &&
      fail "invalid argument: $2"
    vcs_update
    ;;
  commit | ci)
    test -n "$2" &&
      fail "invalid argument: $2"
    vcs_commit
    ;;
  *)
    fail "no such subcommand: $1"
    ;;
esac

exit 0
