#!/bin/bash
#
#########################
#
# sudo-chop
# Copyright 2025 Red Hat, Inc.
#
# Author: Kimberly Lazarski
#
# Part of Kimberly's sudo-ninja toolkit
#
#########################
#
# sudo-katana
#
# Copyright 2025 Red Hat, Inc.
#
# Author: Kimberly Lazarski
#
# Part of Kimberly's sudo-ninja toolkit
#
# Description: Sudo sword!
#
# This tool is useful for, among other things,
# Slicing, dicing, and flattening monolithic sudoer files.
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
#
# Clear variables so we don't inherit settings from sourced runs:

unset optVerbose fileInput dirTemp optFilePrefix optOutputFile dirWorking strStep fileLog;
# Initialize these variables for unary expressions:
eval {optNoMerge,optMonitor,optNocomment,optSplit,optOverwrite,optRecombine,optFlatten,optLog,optDebug}=0
#echo {$optNocomment,$optSplit,$optOverwrite,$optQuiet,$optVerbose,$optRecombine}

#########################
#
# Set some sane defaults
#
# Unless [ -v | --verbose ] is enabled, "quiet" mode is used for commands
# and nonessential echo commands are substituted with do-nothing "true"
#
cmdEcho="true"
cmdWordVomit="true"
optQuiet="--quiet"
optQuiet="-s"
cmdLog="true"
cmdDate='date +%Y-%m-%d_%H:%M:%S'
set +x
dtStart="$(date +"%s")";
dtStart8601="$(date --date="@${dtStart}" +"%Y-%m-%d_%H:%M:%S.%s")"
echo "${dtStart8601}: sudo-katana started."
cmdLine="${0} ${@}"
cmdDbgRead=true;
cmdDbgSleep=true;
cmdDbgEcho=true;
#
##############################
# Ensure utilities we rely upon are present
#
for cmdTest in sed grep visudo tr gawk;
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

    ${otagBold} -D | --debug
        Debug mode which turns on sleeps, pause breaks waiting for keypress
        to continue, allowing for review and analysis of intermediate files

    ${otagBold} -e | --expire${ctag}
        Expiration tags driven by EXP MM/DD/YY or EXP MM/DD/YYYY
        non-8601 date format driven by client's preexisting data. Utility
        converts all dates to ISO8601 format for internal processing. We do
        recommend switching to YYYY-MM-DD format for future EXP tags!

    ${otagBold} -f | --flatten${ctag}
        This flattens multi-line aliases, rules, etc. into single, flat lines
        for easier processing and pruning of inactive/deleted users, hosts,
        groups, and orphaned aliases in cases where all member tokens have been
        removed.

    ${otagBold} -l | --log | --report ${ctag}${otagItal}[Log Filename]${ctag}
        Specifying logging will capture most output and log most actions
        to the specified filename. ${otagItal}Partially implemented${ctag}

    ${otagBold} -m | --monitor${ctag}
        Monitor tail of ls -lhtr of target directory when appropriate.
        WARNING! This is VERY slow! Use ONLY for debugging!
        (not fully implemented/not tested yet)

    ${otagBold} -M | --nomerge${ctag}
        Don't merge the comments back in - this is good for
        further processing of the split files before recombining.

    ${otagBold} -n | --nocomment${ctag}
        Strip out all comments

    ${otagBold} -o | --outputfile ${ctag}${otagItal}[filename]${ctag}
        outputfile (for recombined sudoers file)

    ${otagBold} -O | --overwrite${ctag}
        Overwrite output file

    ${otagBold} -p | --prefix ${ctag}${otagItal}[PREfix]${ctag}
        PREfix for the split files which are numbered in order the rules are
        found in --input file. This is for the temp files created in tempdir.

    ${otagBold} -r | --recombine${ctag}
        NO DISASSEMBLE! NUMBER FIVE IS ALIVE!
        Merge files back together into a monolithic sudoers file (file path
        specified by ${otagItal}--outputfile${ctag}).

    ${otagBold} -s | --split${ctag}
        disassemble nosudoers into individual files for each comment+rules
        section for easier processing and flattening of rules

    ${otagBold} -t | --tempdir ${ctag}${otagItal}[dirname]${ctag}
        temp directory to place working files  (should ${otagItal}not${ctag} be /tmp!)

    ${otagBold} -v | --verbose${ctag}
        words and stuff for debugging

    ${otagBold} -vv | --verbose11${ctag}
        extra words and stuff (Word vomit!)

    ${otagBold} -vvv | --plaid${ctag}
        tl;dr (read this output you'll get a headache)
        Lots and lots of debug output. Too muh. dahling, gobble gobble gobble,

"
}

function fnSpinner() {

# Check if we're running verbose mode.
# if we are, don't run the spinner!

  if [ -n ${optVerbose} ];
  then
    if [ -z "${gfxSpin}" ]
    then
      gfxSpin="/"
    fi

    echo -en "${otagBold} ${strStep}    ${gfxSpin} ${ctag}\r"
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
  fi

}

function fnSplitSudoers() {

  ${cmdEcho} "Line ${LINENO}: Entered ${FUNCNAME[0]}"
  ${cmdWordVomit}  "Line ${LINENO} : ${FUNCNAME[0]} : \${dirTemp} ${dirTemp}, \${optFilePrefix},${optFilePrefix}";
  if [ $(find "${dirTemp}" -name "${optFilePrefix}*" | wc -l) -eq 0 ] ;
  then
    ${cmdWordVomit} "Line ${LINENO} : ${FUNCNAME[0]} : ";
    ${cmdEcho} "Proceding with nosudoers split; Please wait...";
#     sed -E '/^[\r\n]?[[:blank:]]*?$/d ; s/\\\s+$/\\/g; s/^([^#].*[^\]\s?$)$/\1\nEOR\o0/g' "${fileInput}" | csplit ${optQuiet} --suffix-format="%02d.tmp" --suppress-matched --prefix="${dirTemp}/${optFilePrefix}" - '/EOR/' '{*}';
#     sed -E '/^[\r\n]?[[:blank:]]*?$/d ; s/\\[\s]+?$/\\/g; s/^([^#].*[^\])[\s]+?$/\1\nEOR\o0/g' "${fileInput}" | csplit ${optQuiet} --suffix-format="%02d.tmp" --suppress-matched --prefix="${dirTemp}/${optFilePrefix}" - '/EOR/' '{*}';
    sed -E '/^[\r\n]?[[:blank:]]*?$/d ; s/\\\s+$/\\/g; s/^([^#].*[^\]\s?$)$/\1\nEOR\o0/g' "${fileInput}" | csplit ${optQuiet} --suffix-format="%02d.tmp" --suppress-matched --prefix="${dirTemp}/${optFilePrefix}" - '/EOR/' '{*}';

    ${cmdEcho} "Initial file split complete; now processing comments and rules:";
    echo;
    for curFile in $(find "${dirTemp}" -name "${optFilePrefix}*.tmp" | sort -V);
    do
      [ ${optMonitor} -eq 1 ] && printf "\033c" && ls -lhtr "${dirTemp}" | tail -n 5 || fnSpinner
      ${cmdWordVomit} -e "\nLine ${LINENO} : ${FUNCNAME[0]} : "
      ${cmdWordVomit} "Current file: ${curFile}";
      if  [ "${optNocomment}" -ne 1 ];
      then
        if [ "$(sed -En '/^(\s+)?#/p' "${curFile}" | wc -c )" -gt 0 ];
        then
          sed -En '/^(\s+)?#/p' "${curFile}" > "${curFile}-comment";
        fi
      fi
      sed -En '/^(\s+)?#/!p' "${curFile}" > "${curFile}-rule";

      rm ${optVerbose} "${curFile}";
      ${cmdWordVomit} "Line ${LINENO} : ${FUNCNAME[0]}";
      sed -En '/^#.*/p' "${curFile}-rule" > "${curFile}" ; sed -E '/^#.*/d; s/^(.*)\s+\\.*$/\1 /g; s/^[[:blank:]]+//g; s/[[:blank:]]+/ /g;' "${curFile}" | tr -d '\n' >> "${curFile}-rule" ; echo >> "${curFile}-rule";

      rm ${optVerbose} "${curFile}";
      ${cmdWordVomit} "Line ${LINENO} : ${FUNCNAME[0]} : ";
    done;
    ${cmdWordVomit} "Line ${LINENO} : ${FUNCNAME[0]} : ";
  else
    echo "There are file conflicts matching file path ${dirTemp}/${optFilePrefix}*; please either archive or delete them or change the target path.";
    exit 1;
  fi;

}


function fnFlattenRules() {
  unset curFile;
  echo;
  for curFile in $(find "${dirTemp}" -name "${optFilePrefix}*.tmp-rule" | sort -V);
  do
    [ ${optMonitor} -eq 1 ] && printf "\033c" && ls -lhtr "${dirTemp}" | tail -n ${LINES} || fnSpinner
    ${cmdWordVomit} -e "\nLine: ${LINENO} : ${FUNCNAME[0]} : flattening rule in [${curFile}].";
    sed -E '/^#.*/p' "${curFile}" | sed -E '/^#.*/d; s/^([^\]*)\\[\s]+?$/\1 /g; s/^[[:blank:]]+//g; s/[[:blank:]]+/ /g;'  | tr -d '\n' >> "${curFile}-rule" ;
    echo >> "${curFile}-rule";
    mv ${optVerbose} "${curFile}-rule" "${curFile}";
  done;

}

function fnSplitExpirations () {

  local LINES=5;
  local intRenumber=1;
  for curFile in $(find "${dirTemp}" -iname "*.tmp-merged" | sort -V );
  do
    [ ${optMonitor} -eq 1 ] && printf "\033c" && ls -lhtr "${dirTemp}" | tail -n ${LINES} || fnSpinner;
    if [ $(grep -c 'EXP' "${curFile}") -le 1 ] ;
    then
      ${cmdWordVomit} "Zero or only one expiration tag in ${curFile}, processing...\n";
      mv ${optVerbose} "${curFile}" "${dirTemp}/${optFilePrefix}${intRenumber}.remerged";
      ((intRenumber++));
    else
      echo -e "\n\nMore than two EXP tags found in ${curFile}, processing...\n";
      IFS='\0';
      sed -E 's/^(.*)([[:alnum:]][[:space:]]+[[:digit:]]{2}[\/-]|[[:alnum:]][[:space:]]+[[:digit:]]{1}[\/-])([[:digit:]]{2}|[[:digit:]]{1})([\/-][[:digit:]]{2}|[\/-][[:digit:]]{4})(.*)$/EOR\o0\n\1\2\3\4/g' "${curFile}" | csplit ${optQuiet} --suffix-format="%02d.tmp-correction" --suppress-matched --prefix="${dirTemp}/${optFilePrefix}" - '/EOR/' '{*}';
      unset IFS;
      for fileCorrection in $(find "${dirTemp}" -name "${optFilePrefix}*.tmp-correction" | sort -V);
      do
        ${cmdWordVomit} "$(${cmdDate}) Multiple expiration tags in ${curFile}. Correcting."; sleep .3;
        [ ${optMonitor} -eq 1 ] && printf "\033c" && ls -lhtr "${dirTemp}" | tail -n ${LINES} || fnSpinner;
        mv ${optVerbose} "${fileCorrection}" "${dirTemp}/${optFilePrefix}${intRenumber}.remerged";
        ((intRenumber++));
      done;
      rm ${optVerbose} "${curFile}"
    fi
  done;

  for curFile in $(find "${dirTemp}" -name "${optFilePrefix}*.remerged" | sort -V);
  do
    mv ${optVerbose} "${curFile}" "${dirTemp}/$(basename --suffix "remerged" "${curFile}")tmp-merged";
  done;

}

function fnRmExpiredAccounts() {

  declare arrExpiredRules;
  local dtToday="$(date +"%Y-%m-%d")";
  local intCounter=0;

  # Search and collect expired files (EXP date = (today - 1 day) )
  for curFile in $(find "${dirTemp}" -name "*.tmp-merged" | sort -V);
  do
    strStep="Scanning ${curFile} for expired rules... ";
    fnSpinner

    if $(grep -E "#.*EXP" "${curFile}" >/dev/null);
    then
      curExpDate=$(sed -En '/^#.*(EXP.*)$/s/.*(EXP.*)$/\1/p;s/(.*\/)([0-9]{2}$)/\120\2/g' "${curFile}" |sed 's,/,-,g'  | sed -E 's/\(.*$//g; s/(-)([0-9]{2})$/\120\2/g ; s/([0-9]{1,2})-([0-9]{1,2})-([0-9]{4})/\3-\1-\2/g; s/-([0-9])-/-0\1-/g; s/-([0-9])$/-0\1/g; s/([Mm][Aa][Yy])-([0-9]{2})-([0-9]{4})/\3-05-\2/g ; s/^EXP //g');

      if [[ "${curExpDate}" < "${dtToday}" ]];
      then
        ((intCounter+=1));
        arrExpiredRules+=("${curFile}");
      fi;

    fi;
  done

  # Check if any files were found
  if [[ ${intCounter} -eq 0 ]]; then
    strStep="No expired rules files were found."
    ${cmdLog} "${strStep}" >> "${fileLog}";
    echo -e "\n\n${strStep}\n\n"
    return 0
  fi

  if [ -n "${fileLog}" ]ls ;
  then
    strStep="The following ${intCounter} rules files will be deleted:"
    ${cmdLog} "${strStep}" >> "${fileLog}" ; ${cmdEcho} "${strStep}"
    for curFile in ${arrExpiredRules[@]}
    do
      strStep="[${curFile}], expiration date $(sed -En '/^#.*(EXP.*)$/s/.*(EXP.*)$/\1/p;s/(.*\/)([0-9]{2}$)/\120\2/g' "${curFile}" |sed 's,/,-,g'  | sed -E 's/\(.*$//g; s/(-)([0-9]{2})$/\120\2/g ; s/([0-9]{1,2})-([0-9]{1,2})-([0-9]{4})/\3-\1-\2/g; s/-([0-9])-/-0\1-/g; s/-([0-9])$/-0\1/g; s/([Mm][Aa][Yy])-([0-9]{2})-([0-9]{4})/\3-05-\2/g ; s/^EXP //g')."
      echo -e "\n -------------------------------------------------------------------------------\n${strStep}\n" | tee -a "${fileLog}"
      cat "${curFile}" >> "${fileLog}"
    done;
  fi;

  for curFile in ${arrExpiredRules[@]};
  do
    strStep="Deleting expired rules file ${curFile}... "
    echo "${strStep}" "${fileLog}"
    rm -v "${curFile}"
  done

}

function fnRecombine() {

  LINES=10;

  ${cmdWordVomit} "Line ${LINENO} : Entered  ${FUNCNAME[0]}"
  unset curFile;
  echo;
  if [ -f "${optOutputFile}" ];
  then
    if [ "${optOverwrite}" -eq 1 ];
    then
      ${cmdWordVomit} "Line ${LINENO} : ${FUNCNAME[0]} : \${optOutputFile} _ ${optOutputFile}";
      > "${optOutputFile}";
    fi;
    ${cmdWordVomit} -n "Line: ${LINENO} : ${FUNCNAME[0]} : ";
  elif [[ -z "${optOutputFile}" ]];
  then
    ${cmdWordVomit} -n "Line: ${LINENO} : ${FUNCNAME[0]} : ";
    echo -e "${otagRed}!!! ACHTUNG! Output filename not specified!!! Your command line:${ctag}";
    echo -e "\n\t${cmdLine}\n";
    exit 1;
  fi;

  ${cmdEcho} "Line ${LINENO} : ${FUNCNAME}"
  if [ $(find "${dirTemp}" -name "${optFilePrefix}*.tmp-merged" | wc -l ) -gt 1 ]
  then
    ${cmdEcho} "Checking for ${dirTemp}/${optFilePrefix}*.tmp-merged files..."
    ${cmdWordVomit} "Line: ${LINENO} : ${FUNCNAME[0]} : looking for merged files";
    for curFile in $(find "${dirTemp}" -name "${optFilePrefix}*.tmp-merged" | sort -V);
    do
        [ ${optMonitor} -eq 1 ] && printf "\033c" && ls -lhtr "${dirTemp}" | tail -n ${LINES} || fnSpinner
        ${cmdWordVomit} "-e \nLine ${LINENO}: ${FUNCNAME[0]} : merging ${curFile} to ${optOutputFile}";
        cat "${curFile}" >> "${optOutputFile}";
        echo >> "${optOutputFile}";
    done


  else
    ${cmdWordVomit} "Line: ${LINENO} : ${FUNCNAME[0]} : ";
    for curFile in $(find "${dirTemp}" -name "${optFilePrefix}*.tmp-comment" -o -name "${optFilePrefix}*.tmp-rule" | sort -V);
    do
      [[ ${optMonitor} == 1 ]] && printf "\033c" && ls -lhtr "${dirTemp}" | tail -n ${LINES} || fnSpinner
      if [[ "${curFile}" == *".tmp-comment" ]] && [ ${optNocomment} -ne 1 ];
      then
        ${cmdWordVomit} -e "Line ${LINENO}: ${FUNCNAME[0]} : cat ${curFile} >> ${optOutputFile}"
        cat "${curFile}" >> "${optOutputFile}";
      elif [[ "${curFile}" == *".tmp-rule" ]];
      then
        ${cmdWordVomit} "Line ${LINENO}: ${FUNCNAME[0]} : cat ${curFile} >> ${optOutputFile}";
        cat "${curFile}" >> "${optOutputFile}";
      fi;
    done

  fi
}


function fnMergeComments() {

  ${cmdWordVomit} "Line ${LINENO} : Entered  ${FUNCNAME[0]}"

  for curFile in $(find "${dirTemp}" -maxdepth 1 -type f -name "${optFilePrefix}*"| sed -E 's/\.[^.]*$//g'| sort -Vu)
  do
    [ ${optMonitor} -eq 1 ] && printf "\033c" && ls -lhtr "${dirTemp}" | tail -n ${LINES} || fnSpinner
    if [ -f "${curFile}.tmp-comment" ];
    then
      fileMerge="${curFile}.tmp-merged";
      cat "${curFile}.tmp-comment" > "${fileMerge}" && rm "${curFile}.tmp-comment";
    fi;
    if [ -f "${curFile}.tmp-rule" ];
    then
      cat "${curFile}.tmp-rule" >> "${fileMerge}"  && rm "${curFile}.tmp-rule";
    fi;
  done;

}

# END FUNCTION DEFINITIONS
#

##############################
#
# Did user ask us to do anything? If not, let's blow this joint!

if [[ -z "$@" ]];
then
  echo -e "${otagRed}You supplied no command arguments; unable to proceed.${ctag}";
  echo "Your command line:";
  echo -e "\n\t${cmdLine}\n";
  fnHelp;
  exit 1;
fi;

#
###############################
# Since user gave us stuff to do, let's process arguments. Party on!
while [ "$1" != "" ] ;
do
  case $1 in
    -h | --help )   fnHelp;
                    exit 0;
                    ;;
    -s | --input )  shift;
                    fileInput="${1}";
                    ;;
    -d | --workingDirectory ) shift;
                    dirWorking="${1}";
                    ;;
    -D | --debug ) optDebug=1;
                    cmdDbgRead=read;
                    cmdDbgSleep=sleep;
                    cmdDbgEcho=echo;
                   ;;
    -e | --expire)  optExpire="1";
                    ;;
    -f | --flatten ) optFlatten=1;
                    ;;
    -l | --log ) shift;
                    fileLog="${1}"
                    cmdLog="echo"
                    cmdTee="tee -a"
                    optLog="1"
                    ;;
    -m | --monitor ) optMonitor=1;
                    ;;
    -M | --nomerge ) optNoMerge=1;
                    ;;
    -n | --nocomment ) optNocomment=1;
                    ;;
    -o | --outputfile ) shift;
                    optOutputFile="${1}";
                    ;;
    -O | --overwrite )   optOverwrite=1;
                    ;;
    -p | --prefix ) shift;
                    optFilePrefix="${1}";
                    ;;
    -r | --recombine ) optRecombine=1;
                    ;;
    -R | --report | --log ) shift;
                    fileLog="${1}"
                    cmdLog="echo"
                    optLog="1"
                    ;;
    -s | --split )  optSplit=1;
                    ;;
    -t | --tempdir ) shift;
                    dirTemp="${1}";
                    ;;
    -v | --verbose ) optVerbose="-v";
                    cmdEcho="echo";
                    unset optQuiet;
                    ;;
    -vv | --verbose11 ) optVerbose="-v"
                    cmdEcho="echo";
                    cmdWordVomit="echo";
                    unset optQuiet;
                    ;;
    -vv | --verbose11 ) optVerbose="-v"
                    cmdEcho="echo";
                    cmdWordVomit="echo";
                    unset optQuiet;
                    ;;
    -vvv | --plaid ) set -x;
                    optVerbose="-v";
                    cmdEcho="echo";
                    cmdWordVomit="echo";
                    unset optQuiet;
                    ;;
    * )
                    echo -e "${otagRed} \n\tI couldn't understand your command. Please note if you specified an argument with spaces ";
                    echo -e "\t or extended ASCII, you will need to escape those characters and/or use quotes around the path.${ctag}\n";
                    fnHelp;
                    exit 1
                    ;;
  esac ;
  shift ;
done;

${cmdDbgEcho} -e "\n\nAbout to start the flatten step!"
${cmdDbgEcho} -e "[ optDebug==${optDebug}, optExpire==${optExpire}, optFilePrefix==${optFilePrefix}, optFlatten==${optFlatten}, optLog==${optLog}, optMonitor==${optMonitor}, optNocomment==${optNocomment}, optNoMerge==${optNoMerge}, optOutputFile==${optOutputFile}, optOverwrite==${optOverwrite}, optRecombine==${optRecombine} ]"
${cmdDbgRead} -n 1 -s -r -p "Press any key to continue..."

${cmdWordVomit} -e "\nLine ${LINENO}; optSplit = ${optSplit}"

${cmdWordVomit} -e "\nLine ${LINENO}: Checking for input filename" ;
if [ ${optSplit} -eq 1 ];
then
  ${cmdWordVomit} -n "Line ${LINENO} : ${FUNCNAME[0]} : \${fileInput}=[${fileInput}]";
  if [ -n "${dirTemp}" ] ;
  then
    ${cmdWordVomit} -n "Line ${LINENO} : ${FUNCNAME[0]} : \${fileInput}=[${fileInput}]";
    # If target directory doesn't exist, create it
    if [ -n "${dirTemp}" ] && [ ! -d "${dirTemp}" ];
    then
      ${cmdEcho} "${dirTemp} does not exist; creating it now:";
      mkdir ${optVerbose} "${dirTemp}";
      if [ ! $? == 0 ];
      then
        echo "Error while trying to create ${dirTemp}"
        exit 1
      fi
    fi;
    if [ -z "${fileInput}" ];
    then
      ${cmdWordVomit} -n "Line ${LINENO} : ${FUNCNAME[0]}";
      if [ "${optRecombine}" -eq 1 ] && [ -n "${optFilePrefix}" ] && [ -d "${dirTemp}" ] && [ "$(find "${dirTemp}" -name "${optFilePrefix}*.*" | wc -l)" -ge 1 ] ;
      then
        echo "Line ${LINENO} : No --input argument present, but --recombine, --tempdir, and --prefix specified. Attempting to recombine preexisting split files."
        ${cmdEcho} "Line ${LINENO} :optRecombine==${optRecombine} : optFilePrefix==${optFilePrefix} : \${dirTemp}=${dirTemp} : $(find "${dirTemp}" -name "${optFilePrefix}*.*" | wc -l) files found"

      else
        echo -e "\nLine ${LINENO} :Please supply an ${otagRed}--input [filename]${ctag}"
        echo -e "\nYour command line:";
        echo -e "\n\t ${cmdLine}\n";
        exit 1;
      fi
    else
      if [ ! -f "${fileInput}" ];
      then
      ${cmdWordVomit} -e "\nLine ${LINENO} : \${fileInput} ${fileInput}"
        echo "${fileInput} is not accessible.";
        exit 1;
      elif [ -z "${optFilePrefix}" ];
      then
        echo "Line ${LINENO} :${otagRed}Please include a ${ctag}${otagBold}--prefix${ctag}${otagItal} [prefix]${ctag} argument on your command.${ctag}";
        echo "\nYour command line:";
        echo -e "\n\t ${cmdLine}\n";
        exit 1;
      else
        ${cmdWordVomit} -e "\nLine ${LINENO}"
        strStep="Splitting ${fileInput} to ${dirTemp}/${optFilePrefix}*"
        ${cmdWordVomit} -e "\n${LINENO} : entering fnSplitSudoers"
        fnSplitSudoers;
      fi
    fi
  else
    echo "Please specify a --tempdir and make sure the directory exists."
    exit 1
  fi
fi

${cmdEcho} -e "\n${LINENO} : $(${cmdDate}) : Flatten routine is next"

if [ ${optFlatten} -eq 1 ];
then
  # If target directory doesn't exist, bail
  if [ -n "${dirTemp}" ] && [ ! -d "${dirTemp}" ];
  then
    ${cmdEcho} "${dirTemp} does not exist; please check your ${otagItal}--target [filepath]${ctag} and try again."
    exit 1
  fi

  strStep="Flattening ${fileInput} ";
  echo -e "\n${LINENO} : $(${cmdDate}) : ${strStep}...";

${cmdDbgEcho} -e "\n\nAbout to start the flatten step!"
${cmdDbgRead} -n 1 -s -r -p "Press any key to continue..."

  strStep="Flattening rules ${dirTemp}/${optFilePrefix}*.tmp-rule";
  fnFlattenRules;
  ${cmdEcho} -e "\n${LINENO} : Finished flattening rules...";
fi;

${cmdDbgEcho} -e "\n\nDone with the flatten step!"
${cmdDbgRead} -n 1 -s -r -p "Press any key to continue..."

echo
${cmdEcho} -e "${LINENO} : Merging is next\n"

if [ ${optNocomment} -eq 0 ] || [ ${optNoMerge} -eq 0 ] ;
then
  strStep="Line: ${LINENO} : Merging comments back with rules ";
  echo -e "\n${LINENO} : $(${cmdDate}) : ${strStep}...";
  fnMergeComments;
  if [ "${optExpire}" -eq 1 ];
  then
    strStep="Regrouping rules with expiration tags";
    fnSplitExpirations;
  fi;
  ${cmdEcho} "${LINENO} : Finished Merging comments back with rules...";
fi;


if [ ${optExpire} -eq 1 ];
then
  strStep="Line: ${LINENO} : Removing expired rules...";
  fnRmExpiredAccounts
fi

${cmdEcho} -e "\n\n${LINENO} : Recombine routine is next; optRecombine == ${optRecombine}\n";
${cmdDbgEcho} -e "\n\nAbout to start the recombine step!"
${cmdDbgRead} -n 1 -s -r -p "Press any key to continue..."

if [ "${optRecombine}" -eq 1 ];
then
  echo
  strStep="Recombining ${fileInput} to ${optOutputFile}..."
  ${cmdWordVomit} -n "Line ${LINENO} : Calling fnRecombine : ";
  ${cmdEcho} -e "\n${LINENO} : $(${cmdDate}) : ${strStep}...";
  fnRecombine;
  ${cmdEcho} "${LINENO} : Finished recombining ${dirTemp}/${optFilePrefix}* into ${optOutputFile}";
  echo
fi

echo -e "\nIt is done."

dtFinish="$(date +"%s")";
dtDuration=$(( ${dtFinish} - ${dtStart} ))
dtDurationMinutes=$(( ${dtDuration} / 60 ))
dtDurationSeconds=$(( ${dtDuration} % 60 ))
dtFinish8601="$(date --date="@${dtFinish}" +"%Y-%m-%d_%H:%M:%S.%s")"
echo "sudo-katana started at ${dtStart8601} and completed at ${dtFinish8601},taking ${dtDurationMinutes}m:${dtDurationSeconds}s."

exit 0
