#!/bin/bash
#
#########################
#
# sudo-choho
# Copyright 2025 Red Hat, Inc.
#
# Author: Kimberly Lazarski
#
# Part of Kimberly's sudo-ninja toolkit
#
# Description: Sudo espionage!
#
# This tool is useful for, among other things,
# Analyzing and reporting the current state of
# sudoer files.
#
#########################
#
# Setting formatting tags
otagBold="\e[1m";
ctag="\e[0m";
otagRed='\e[0;31m'
otagRevRed='\e[0;101m'
otagUline="\e[4m"
otagItal="\e[3m"
#########################
# Clear variables so we don't inherit settings from sourced runs:

unset optVerbose fileInput dirTarget optFilePrefix optOutputFile dirWorking strStep fileLog;
# Initialize these variables for unary expressions:
eval {optNoMerge,optMonitor,optNocomment,optSplit,optOverwrite,optRecombine,optFlatten,optLog}=0
#echo {$optNocomment,$optSplit,$optOverwrite,$optQuiet,$optVerbose,$optRecombine}

#########################
#Set some sane defaults
optQuiet="-s"
cmdLog="true"
set +x
dtStart="$(date +"%s")";
dtStart8601="$(date --date="@${dtStart}" +"%Y-%m-%d_%H:%M:%S.%s")"
echo "${dtStart8601}: sudo-chop started."

# Ensure utilities we rely upon are present
for cmdTest in sed awk grep visudo tr ;
do
  if ! which ${cmdTest} > /dev/null 2>&1;
  then
    echo -e "${otagBold}${otagRed}${cmdTest}${ctag}${otagRed} is not present; please install it then re-run this script.${ctag}";
    echo "identifying package: dnf provides */${cmdTest}"
    dnf provides "*/${cmdTest}"
    exit 1
  fi;
done;

fnHelp() {

echo -e "

    ${otagBold} -h | --help${ctag}
        helpful words and stuff (this screen)

    ${otagBold} -s | --input ${ctag}${otagItal}[filename]${ctag}
        Input file you want to process

    ${otagBold} -d | --workingDirectory${ctag}
        working directory (not implemented yet)

    ${otagBold}  -e | --expiration${ctag}
        Expiration tags driven by EXP MM/DD/YY or EXP MM/DD/YYYY
        non-8601 date format driven by client's preexisting data
        Will implement 8601-friendly method later

    ${otagBold} -m | --monitor${ctag}
        Monitor tail of ls -lhtr of target directory.
        WARNING! This is VERY slow! Use ONLY for debugging!

    ${otagBold} -M | --nomerge${ctag}
        Don't merge the comments back in - this is good for
        further processing of the split files before recombining.

    ${otagBold} -N | --nuke${ctag}
        Nuke from orbit to be sure

    ${otagBold} -n | --nocomment${ctag}
        Strip out all comments

    ${otagBold} -o | --outputfile ${ctag}${otagItal}[filename]${ctag}
        outputfile (for recombined sudoers file)

    ${otagBold} -p | --prefix ${ctag}${otagItal}[PREfix]${ctag}
        PREfix for the split files which are numbered in order the rules are
        found in --input file

    ${otagBold} -r | --recombine${ctag}
        NO DISASSEMBLE! NUMBER FIVE IS ALIVE!

    ${otagBold}-R | --report | --log ${ctag}${otagItal}[Log Filename]${ctag}
        Specifying logging will capture most output and log most actions
        to the specified filename.

    ${otagBold} -s | --split${ctag}
        disassemble

    ${otagBold} -t | --targetdir ${ctag}${otagItal}[dirname]${ctag}
        target directory to place split files

    ${otagBold} -v | --verbose${ctag}
        words and stuff for debugging

    ${otagBold} -vv | --verbose11${ctag}
        extra words and stuff (Word vomit!)

    ${otagBold} -vvv | --plaid${ctag}
        tl;dr
"
}

function fnSpinner() {
  if [ -z "${gfxSpin}" ]
  then
    gfxSpin="/"
  fi

  echo -en "${otagBold}${strStep}    ${gfxSpin} ${ctag}\r"
  case "${gfxSpin}" in
    "/" ) gfxSpin="-"
      ;;
    "-" ) gfxSpin="\\"
      ;;
    "\\" ) gfxSpin="|"
      ;;
    "|" ) gfxSpin="/"
      ;;
    "/" ) gfxSpin="-"
      ;;
    "-" ) gfxSpin="\\"
      ;;
    "\\" ) gfxSpin="|"
      ;;
    "|" ) gfxSpin="/"
      ;;
  esac;
}
dirTarget="${1}"
fileSpec="${2}"

for curFile in $(find "${dirTarget}" -name "${fileSpec}");
do
  if [ $(grep -c "EXP" "${curFile}") -gt 1 ] ;
  then echo -e "#######-----------------------------------------#######\n#\n# ${curFile} has $(grep -c "EXP" "${curFile}") expiration dates:\n" ;
    cat "${curFile}";
    echo -e "\n#\n#\n#";
  fi
done
echo -e "#######-----------------------------------------#######"

# optFilePrefix="foo" ;
# dirTarget="./" ;
# curFile="rules-east-second/sudo24651.tmp-merged" ;
# sed -E 's/^([#].*EXP\s+[0-9].*)$/EOR\o0\n\1/g' ${curFile} | csplit --suffix-format="%02d.tmp-merged" --suppress-matched --prefix="${dirTarget}/${optFilePrefix}" - '/EOR/' '{*}'


exit 0

sed -En '/^#.*/p' "${curFile}-rule" > "${curFile}" ; sed -E '/^#.*/d; s/^(.*)\s+\\.*$/\1 /g; s/^[[:blank:]]+//g; s/[[:blank:]]+/ /g;' "${curFile}" | tr -d '\n' >> "${curFile}-rule" ; echo >> "${curFile}-rule";
