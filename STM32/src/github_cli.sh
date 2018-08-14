#!/bin/bash - 
#===============================================================================
#
#          FILE: github_cli.sh
# 
#         USAGE: ./github_cli.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: See usage()
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Frederic Pillon (), frederic.pillon@st.com
#  ORGANIZATION: MCU Embedded Software
#     COPYRIGHT: Copyright (c) 2018, Frederic Pillon
#       CREATED: 08/14/2018 08:07:43
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

VERSION="0.1"
GITHUB_ACCOUNT="stm32duino"
REPO_NAME="arm-none-eabi-gcc"
LATEST_RELEASE=1


###############################################################################
## Help function
usage()
{
    echo "############################################################"
    echo "##"
    echo "##  `basename $0`"
    echo "##"
    echo "############################################################"
    echo "##"
    echo "## `basename $0`"
    echo "## [-l] [-h] [-v] [-a <github account>] [-r <repo name>]"
    echo "##"
    echo "## Mandatory options:"
    echo "##"
    echo "## None"
    echo "##"
    echo "## Optionnal:"
	echo "##"
    echo "## -a <github account>: github account name. Default: '$GITHUB_ACCOUNT'"
    echo "## -r <repo name>: repository name. Default: '$REPO_NAME'"
    echo "## -l: get latest release"
    echo "## -v: print version"
    echo "##"
    echo "############################################################"
    exit 0
}

get_latest_release() {
  # Get latest release from GitHub api
  curl --silent "https://api.github.com/repos/${GITHUB_ACCOUNT}/${REPO_NAME}/releases/latest" |
    grep '"tag_name":' |                                            # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/'                                    # Pluck JSON value
}


# parse command line arguments
# options may be followed by one colon to indicate they have a required arg
options=`getopt -o a:hlr:v -- "$@"`

if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi

eval set -- "$options"

while true ; do
    case "$1" in
    -a) GITHUB_ACCOUNT=$2
        shift 2;;
    -h|-\?) usage
        shift;;
    -l) LATEST_RELEASE=1
        shift;;
    -r) REPO_NAME=$2
        shift 2;;
    -v) echo "`basename $0`: $VERSION"
        exit 0
        shift;;
    --) shift;
        break;;
    *) break;;
    esac
done

if [ $LATEST_RELEASE -eq 1 ]; then
    get_latest_release
fi
