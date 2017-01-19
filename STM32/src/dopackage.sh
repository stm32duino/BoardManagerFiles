#!/bin/bash -
#===============================================================================
#
#          FILE: dopackage.sh
#
#         USAGE: ./dopackage.sh [OPTIONS]
#
#   DESCRIPTION: Create package(s) and update json file for using with Arduino
#                Board Manager
#
#       OPTIONS: [-c <core name>] [-h] [-j <json file> ] [-p <packager name>]
#                [-s] [-t <tools directory>] [-u <url>] [-v <package version>]
#  REQUIREMENTS: jq (1.3)
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: FPI
#  ORGANIZATION: STMicroelectronics
#     COPYRIGHT: -
#       CREATED: 12/06/16 13:57
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

CURDIR=`pwd`
TOPDIR=${CURDIR}/..
PKGDIR=${TOPDIR}/packages
TOOLSDIR=${TOPDIR}/tools

pkgername="STM32"
keptSource=0

corename=""
toolsname="STM32Tools"
toolsver=""
pkgname=""
pkgver=`date +%Y.%-m.%-d`
jsonFile="${TOPDIR}/package_stm_index.json"
tmpjsonFile="tmp.json"
url="https://github.com/stm32duino/BoardManagerFiles/raw/master/STM32"
toolsurl="${url}/tools"
coreurl="${url}/packages"
sum=0
size=0

###############################################################################
## Help function
usage()
{
    echo ""
	echo "Usage: `basename $0` [-c <core name>] [-h] [-j <json file> ]"
    echo -e "\t\t\t[-p <packager name>] [-s] [-t <tools directory>]"
    echo -e "\t\t\t[-u <url>] [-v <package version>]"
    echo ""
    echo "Create package(s) and update json file for using with Arduino Board Manager"
    echo "(by default all directory from `pwd $0` will be packaged)"
    echo ""
    echo "Before use the script, clone or symlink the core(s) repo(s) to package"
    echo "to the same directory than '`basename $0`'."
    echo "Directory name will be used as package name:"
    echo ""
    echo "  ln -s <path to the STM32F1 core repo> STM32F1"
    echo "  git clone https://github.com/stm32duino/Arduino_Core_STM32L4.git STM32L4"
    echo ""
    echo "To package the STM32 tools:"
    echo "  git clone https://github.com/stm32duino/Arduino_Tools.git STM32Tools"
    echo "or"
    echo "  ln -s <path to the STM32 tools repo> STM32Tools"
    echo ""
    echo " Optional:"
    echo "   -c <core name>: generate package for core name from `pwd $0`"
    echo "   -h: print this help"
    echo "   -j: json file to update (default: $jsonFile)"
    echo "   -p <packager name>: packager name (default: $pkgername)"
    echo "   -s: keep source"
    echo "   -t <tools name>: tools name (default: $toolsname)"
    echo -e "\tIf dir exists with this name it will be packaged."
    echo -e "\telse use latest version if exists."
    echo "   -u <url>: url to use (default: $url)"
    echo "   -v <package version>: specify package version (default: $pkgver)"
    echo ""
    echo "Examples:"
    echo -e "  ./dopackage.sh  -d STM32F1\t# Create package without source for STM32F1 core: STM32F1-$pkgver.tar.bz2"
    echo -e "  ./dopackage.sh  -s -d STM32L4\t# Create package for STM32L4 core: STM32L4-$pkgver.tar.bz2"
    echo -e "  ./dopackage.sh  -a\t\t# Create all packages"
    echo ""
    exit 0
}

# $1 jq status
# $2 error message
# $3 error num
jqHandler()
{
  if [ $1 -ne 0 ]; then
    echo -e "$2"
    exit $3
  fi
}

sumSizeOf()
{
  sum=`sha256sum $1| cut -d' ' -f1`
  size=`stat --printf="%s" $1`
}

# $1 tools name
# $2 archive file name
generateToolsPackage()
{
  # Add git info to know where it comes from
  cd $1
  git show HEAD --pretty=short --no-patch > package_version.txt
  cd $CURDIR
  destdir=${TOOLSDIR}
  # do the package
  echo -n "Generating tools package $2..."

  tar --transform="s|STM32Tools|STM32Tools/tools|" --exclude=".git" --exclude=".gitignore" -jhcf ${destdir}/$2 $1
  if [ $? -ne 0 ]; then
    echo "failed to create archive $2"
    rm -rf $1/package_version.txt
    exit 2
  fi

  cd $CURDIR
  rm -rf $1/package_version.txt
  echo "done"
}

# $1 tools name
# $2 archive file name
addJsonTools()
{
  echo -n "Adding $1 tools version ${toolsver}..."
  jq '(.packages[].tools) |= .+ [{name: "'$1'",
          version: "'${toolsver}'",
          systems:
          [{ host: "i686-linux-gnu",
             url: "'${toolsurl}/$2'",
             archiveFileName: "'$2'",
             checksum: "SHA-256:'${sum}'",
			 size: "'${size}'"},
           { host: "x86_64-pc-linux-gnu",
             url: "'${toolsurl}/$2'",
             archiveFileName: "'$2'",
             checksum: "SHA-256:'${sum}'",
			 size: "'${size}'"},
           { host: "i686-mingw32",
             url: "'${toolsurl}/$2'",
             archiveFileName: "'$2'",
             checksum: "SHA-256:'${sum}'",
			 size: "'${size}'"},
           { host: "i386-apple-darwin11",
             url: "'${toolsurl}/$2'",
             archiveFileName: "'$2'",
             checksum: "SHA-256:'${sum}'",
			 size: "'${size}'"}]
         }]
     '  $jsonFile > $tmpjsonFile
  jqHandler $? "Failed to add new tools $1 to $jsonFile" 5
  mv $tmpjsonFile $jsonFile
  echo "done"
}

# $1 tools name
# $2 archive file name
updateJsonTools()
{
  local res=""
  sumSizeOf "${TOOLSDIR}/$2"

  # Check if version already in the json.
  res=`jq '.packages[] | select(.name == "'${pkgername}'").tools[] |
      select(.name == "'$1'") | select ( .version == "'${toolsver}'")
     ' $jsonFile`
  jqHandler $? "Failed to check tools version in $jsonFile" 3

  if [ "$res" == "" ]; then
    # version doesn't exist
    addJsonTools $1 $2
  else
    # update the existing one
    echo -n "Updating $1 tools version ${toolsver}..."
    jq '(.packages[] | select(.name == "'${pkgername}'") .tools[] |
        select(.name == "'$1'") | select ( .version == "'${toolsver}'")
        ).systems[] |= with_entries(.value =
        if ([.key] | contains(["url"])) then "'${toolsurl}/$2'"
        else if ([.key] | contains(["archiveFileName"])) then "'$2'"
             else if ([.key] | contains(["checksum"])) then "SHA-256:'${sum}'"
                  else if ([.key] | contains(["size"])) then "'${size}'"
                       else .value
                       end
                  end
             end
        end)' $jsonFile > $tmpjsonFile
    jqHandler $? "Failed to update tools version ${toolsver} in $jsonFile" 4
    mv $tmpjsonFile $jsonFile
    echo "done"
  fi
}

# $1 core name
# $2 archive file name
generateCorePackage()
{
  # Add git info to know where it comes from
  cd $1
  git show HEAD --pretty=short --no-patch > package_version.txt
  cd $CURDIR
  destdir=${PKGDIR}
  # do the package
  if [ $keptSource == 0 ]; then
    echo -n "Generating package $2 without source..."
    if [ -d tmp ]; then
		rm -rf tmp
	fi
    mkdir tmp
    cp -aL $1 ./tmp/

    cd tmp
	if [ -e $1/system ]; then
      find $1/system -not -name "*.h" -type f -delete
      find $1/system -depth -type d -empty -delete
	fi
  else
    echo -n "Generate package $2..."
  fi

  tar --exclude=".git" --exclude=".gitignore" -jhcf ${destdir}/$2 $1
  if [ $? -ne 0 ]; then
    echo "failed to create archive $2"
    rm -rf $1/package_version.txt
    rm -rf tmp
    exit 6
  fi

  cd $CURDIR
  rm -rf $1/package_version.txt
  rm -rf tmp
  echo "done"
}

# $1 core name
updateJsonBoardName()
{
  local tmp=$IFS
  IFS=$'\n'
  echo "$1 contains the following boards:"
  jq 'del(.[].boards[])' $tmpjsonFile > l$tmpjsonFile
  mv l$tmpjsonFile $tmpjsonFile

  for i in $(grep "\.name" $1/boards.txt | cut -d'=' -f2); do
    echo "$i"
	jq '.[].boards |= .+ [{name: "'$i'"}]
       ' $tmpjsonFile > l$tmpjsonFile
    jqHandler $? "Failed to add board name for $1" 17
    mv l$tmpjsonFile $tmpjsonFile
  done
  IFS=$tmp
}

# $1 source path
# $2 archive file name
# $3 architecture
addJsonCore()
{
  jq -n '.+ [{ name: "'$1' Boards",
               architecture: "'$3'",
               version: "'${pkgver}'",
		       category: "Contributed",
               url: "'${coreurl}/$2'",
               archiveFileName: "'$2'",
               checksum: "SHA-256:'${sum}'",
               size: "'${size}'",
			   toolsDependencies:[],
               boards:[]
			}]
        ' > l$tmpjsonFile
  jqHandler $? "Failed to create new core for $2" 15
  # check if the tools version is known
  if [ "$toolsver" != "" ]; then
    jq '.[].toolsDependencies |= .+ [{ packager: "'${pkgername}'",
                                       name: "'${toolsname}'",
                                       version: "'${toolsver}'"}]
       ' l$tmpjsonFile > $tmpjsonFile
    jqHandler $? "Failed to update core tools info" 16
  else
    mv l$tmpjsonFile $tmpjsonFile
  fi
}

# $1 core name
# $2 archive file name
# $3 last core version used
updateJsonCore()
{
  echo -n "[" > $tmpjsonFile
  # extract latest version
  jq '.packages[] | select(.name == "'${pkgername}'").platforms[]
                  | select(.architecture == "'${arch}'")
                  | select(.version == '${lcoreversion}')
     ' $jsonFile >> $tmpjsonFile
  jqHandler $? "Failed to extract last core version $3 from $jsonFile" 12
  echo -n "]" >> $tmpjsonFile

  # update info
  jq ' .[].version= "'${pkgver}'"
     | .[].archiveFileName= "'$2'"
     | .[].url= "'${coreurl}/$2'"
     | .[].checksum= "SHA-256:'${sum}'"
     | .[].size= "'${size}'"
	 ' $tmpjsonFile > l$tmpjsonFile
  jqHandler $? "Failed to update core info" 13
  # check if the tools version is known
  if [ "$toolsver" != "" ]; then
    jq '(.[].toolsDependencies[]| select(.name == "'${toolsname}'").version)="'${toolsver}'"
       ' l$tmpjsonFile > $tmpjsonFile
    jqHandler $? "Failed to update core tools info" 14
  else
    mv l$tmpjsonFile $tmpjsonFile
  fi
}

# $1 core name
# $2 archive file name
updateJsonPlatform()
{
  # considering arch always lower case
  local arch=`echo "$1" | tr '[:upper:]' '[:lower:]'`
  local lcoreversion=""
  local res=""
  sumSizeOf "${PKGDIR}/$2"

  # Check if version already in the json.
  res=`jq '.packages[] | select(.name == "'${pkgername}'").platforms[] |
      select(.architecture == "'$arch'") | select ( .version == "'${pkgver}'")
     ' $jsonFile`
  jqHandler $? "Failed to check core version in $jsonFile" 7

  if [ "$res" == "" ]; then
    # version doesn't exist
    # Searching last version used for the core
    jq '.packages[] | select(.name == "'${pkgername}'").platforms[]
                    | select(.architecture == "'${arch}'").version
       ' $jsonFile > version.txt
    jqHandler $? "Failed to search version of $1 in $jsonFile" 8
    lcoreversion=`sort -nru -t'.' -k1 -k3 -k3  version.txt | head -n1`
    rm -f version.txt

    if [ "$lcoreversion" != "" ]; then
      # extract and update core info
      echo "Adding new version for $1..."
      updateJsonCore $1 $2 $lcoreversion
    else
      # no older version. Add new one with a default template
      # which need to be filled properly by user
      echo "Adding new arch $arch..."
	  addJsonCore $1 $2 $arch
      echo "###################################################"
	  echo "# Manual update/check should be required"
	  echo "# in the json file for the architecture $arch"
      echo "# ex: tools dependencies"
  	  echo "###################################################"
    fi
    updateJsonBoardName $1

    # Add core info to the json file
    res=`jq '.' $tmpjsonFile`
    jq '(.packages[].platforms) |= .+ '"$res"' ' $jsonFile > $tmpjsonFile
    jqHandler $? "Failed to update $1 in $jsonFile" 9
    mv $tmpjsonFile $jsonFile
    echo "done"
  else
    # update the existing one
    echo -n "Updating $1 core version ${pkgver}..."
    jq '(.packages[] | select(.name == "'${pkgername}'").platforms[]
                     | select(.architecture == "'$arch'")
                     | select (.version == "'${pkgver}'")
        ) |= with_entries(.value =
        if ([.key] | contains(["url"])) then "'${coreurl}/$2'"
        else if ([.key] | contains(["archiveFileName"])) then "'$2'"
             else if ([.key] | contains(["checksum"])) then "SHA-256:'${sum}'"
                  else if ([.key] | contains(["size"])) then "'${size}'"
                       else .value
                       end
                  end
             end
        end)' $jsonFile > l$tmpjsonFile
    jqHandler $? "Failed to update core version ${pkgver} in $jsonFile" 10
    # check if the tools version is known
    if [ "$toolsver" != "" ]; then
     jq '(.packages[] | select(.name == "'${pkgername}'").platforms[]
	                  | select(.architecture == "'$arch'")
                      | select ( .version == "'${pkgver}'").toolsDependencies[]
                      | select(.name == "'$toolsname'")
         ) |= with_entries(.value =
         if ([.key] | contains(["version"])) then "'$toolsver'" else .value end)
        ' l$tmpjsonFile > $tmpjsonFile
        jqHandler $? "Failed to update core tools info" 11
    else
      mv l$tmpjsonFile $tmpjsonFile
    fi
    mv $tmpjsonFile $jsonFile
    echo "done"
  fi
}

main(){
    echo "stub"
}
###############################################################################
# FUNCTION MAIN
###############################################################################
# parse command line arguments
# options may be followed by one colon to indicate they have a required arg
options=`getopt -o c:hj:p:st:u:v: -- "$@"`

if [ $? != 0 ] ; then usage; exit 1 ; fi

eval set -- "$options"

while true ; do
	case "$1" in
    -c) corename=${2%/};
        shift 2;;
    -h|-\?) usage
        shift;;
    -j) jsonFile=$2;
        shift;;
    -p) pkgername=$2;
        shift 2;;
    -s) keptSource=1;
        shift;;
    -t) toolsname=${2%/};
        shift 2;;
    -u) url=$2;
        toolsurl="${url}/tools";
        coreurl="${url}/packages";
        shift 2;;
    -v) pkgver=$2
        shift 2;;
    --) shift;
        break;;
    *) break;;
    esac
done

# Check if jq is available
jq --version 2>/dev/null
jqHandler $? "jq is required to update the json file.\nPlease, install it." 1

# Check if json file exists
if [ "$jsonFile" == "" ] || [ ! -e $jsonFile ]; then
  echo "json file is not valid!"
  usage
fi

# First manage tools part
if [ -e $toolsname ]; then
  # Create package
  pkgname=${toolsname}-${pkgver}.tar.bz2
  toolsver=${pkgver}
  generateToolsPackage $toolsname $pkgname
  updateJsonTools $toolsname $pkgname
fi

# package one dir
if [ "$corename" != "" ] && [ -e $corename ]; then
  pkgname=${corename}-${pkgver}.tar.bz2
  generateCorePackage $corename $pkgname
  updateJsonPlatform $corename $pkgname
else
# package all dir
  for i in $(find  -L -maxdepth 2 -path "./${toolsname}" -prune -o -name boards.txt -printf "%h\n" | sed 's|./||'); do
  pkgname=${i}-${pkgver}.tar.bz2
  generateCorePackage $i $pkgname
  updateJsonPlatform $i $pkgname
  done
fi

exit 0
