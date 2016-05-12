#!/bin/sh
# OpenXT git repo setup file.

die() {
	echo "$1" 1>&2
	exit 1
}

#######################################################################
# checkout_git_branch                                                 #
# param1: Path to the git repo                                        #
# param2: Preferred branch to checkout.  Fallback will be to master.  #
#                                                                     #
# Checks out the branch specified in param2 for the repo located at   #
# the file path in param1.  If the branch is not part of the git repo #
# the master branch is checked out instead.                           #
#######################################################################
checkout_git_branch() {
	local path="$1"
	local branch="$2"

	cd $path
	git checkout "$branch" 2>/dev/null|| git checkout -b "$branch" origin/$branch 2>/dev/null || { echo "The value $branch does not exist as a branch or HEAD position. Falling back to the master branch."; git checkout master 2>/dev/null; }
	cd $OLDPWD
}

#######################################################################
# fetch_git_repo                                                      #
# param1: Path (absolute) to place the repo                           #
# param2: Git url to fetch                                            #
#                                                                     #
# Fetches the repo specified by param2 into the directory specified   #
# by param1.                                                          #
#######################################################################
fetch_git_repo() {
	local path="$1"
	local repo="$2"

	echo "Fetching $repo..."
	set +e
	git clone -n $repo "$path" || die "Clone of git repo failed: $repo"
	set -e
}

process_git_repo() {
	local path="$1"
	local repo="$2"
	local branch="$3"

	if [ ! -d $path ]; then
		# The path does not exist.  Proceed.
		fetch_git_repo $path $repo $branch
		checkout_git_branch $path $branch
	fi
}

OE_OPENXT_DIR=`pwd`
REPOS=$OE_OPENXT_DIR/repos
OE_PARENT_DIR=$(dirname $OE_OPENXT_DIR)

# Load our config
[ -f "$OE_PARENT_DIR/.config" ] && . "$OE_PARENT_DIR/.config"

[ -f "$OE_OPENXT_DIR/local.settings" ] && . "$OE_OPENXT_DIR/local.settings"

mkdir -p $REPOS || die "Could not create local build dir"

# Pull down the OpenXT repos
process_git_repo $REPOS/meta-openxt $OPENXT_REPO $OPENXT_TAG
process_git_repo $REPOS/bitbake $BITBAKE_REPO $BB_BRANCH
process_git_repo $REPOS/openembedded-core $OE_CORE_REPO $OE_BRANCH
process_git_repo $REPOS/meta-openembedded $META_OE_REPO $OE_BRANCH
if [ ! -z ${META_JAVA_TAG+x} ]; then
	process_git_repo $REPOS/meta-java $META_JAVA_REPO $META_JAVA_TAG
else
	process_git_repo $REPOS/meta-java $META_JAVA_REPO $OE_BRANCH
fi
if [ ! -z ${META_SELINUX_TAG+x} ]; then
	process_git_repo $REPOS/meta-selinux $META_SELINUX_REPO $META_SELINUX_TAG
else
	process_git_repo $REPOS/meta-selinux $META_SELINUX_REPO $OE_BRANCH
fi

if [ ! -e $OE_OPENXT_DIR/conf/local.conf ]; then
  ln -s $OE_OPENXT_DIR/conf/local.conf-dist \
      $OE_OPENXT_DIR/conf/local.conf
fi

BBPATH=$OE_OPENXT_DIR/oe/openxt:$REPOS/openembedded:$OE_OPENXT_DIR/oe-addons
if [ ! -z "$EXTRA_DIR" ]; then
  BBPATH=$REPOS/$EXTRA_DIR:$BBPATH
fi

cat > oeenv <<EOF 
OE_OPENXT_DIR=$OE_OPENXT_DIR
PATH=$OE_OPENXT_DIR/repos/bitbake/bin:\$PATH
BBPATH=$BBPATH
BB_ENV_EXTRAWHITE="OE_OPENXT_DIR MACHINE GIT_AUTHOR_NAME EMAIL"

export OE_OPENXT_DIR PATH BBPATH BB_ENV_EXTRAWHITE
EOF
