#/bin/bash
#
#########################
#
# sudo-taijutsu
# Copyright 2025 Red Hat, Inc.
#
# Author: Kimberly Lazarski
#
# Part of Kimberly's sudo-ninja toolkit
#
# This utility can identify invalid users (against a reference account list)
# and delete rules and surgically remove invalid users from user aliases.
#
# The utility will be able to validate individual rules via
# visudo --check --file as part of its process (not implemented yet).
#
#########################
#
#Setting formatting tags
otagBold="\e[1m";
ctag="\e[0m";
otagRed='\e[0;31m'
otagRevRed='\e[0;101m'
otagUline="\e[4m"
otagItal="\e[3m"
chrTab='\t'
#########################
#
# This is a customizable word filter, to filter out words that our initial
# attempt at deleting non-account words from the sudoers file missed, since
# it's impossible to arrive at a one-size-fits-all without a massive increase
# in lines of code (for which bash isn't terribly efficient)

patCustomFilter='2c912219|_CISSYS|-cert-db|ALL|zoom[[:alnum:]-]+|word6|word7|etc'
patCustomFilter2='pattern1|pattern2'
#
#########################
# Clear variables so we don't inherit settings from sourced runs:

unset optVerbose optCommit
eval {optDelete,optVerbose,intCounter,optReport}=0
unset optVerbose fileInput dirTarget optFilePrefix optOutputFile dirWorking strStep fileLog;
# Initialize these variables for unary expressions:
eval {optCleanAliases,optCleanComments,optMonitor,optCsvQuoted,Split,optOverwrite,optRecombine,optFlatten,optLog}=0

#########################
#Set some sane defaults
optQuiet="-s"
cmdLog="true"
set +x
dtStart="$(date +"%s")";
dtStart8601="$(date --date="@${dtStart}" +"%Y-%m-%d_%H:%M:%S.%s")"
echo "${dtStart8601}: sudo-chop started."
cmdEcho="true"
cmdTee="true"
cmdAbbreviate="cat"
cmdLine="${0} ${@}"


function fnSpinner() {
  if [ -z $gfxSpin ]
  then
    gfxSpin="/"
  fi

  printf "\r\033[2K"
  printf " %-90.90b %-2.2s \r" "${strStep}"    "${gfxSpin} "
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

function fnGetUserList() {

arrAccountList=$( sed -E ' /#(.*[^=].*|.*\s?[[:alnum:]_-]+\s?,\^C[[:alnum:]_-]+\[,]?)$/d  ; /^(Defaults.*|#\s?)$/d  ; s/(\/(usr)|)\/bin\/su -\s+?([[:alnum:]_-]+?|)\s+?/ /g  ; s/NOPASSWD\:[[:alnum:] /_-]+/ /g  ; s/\/(usr|bin|etc|opt|tmp)\/[[:alnum:] \/_-]*(systemctl|pcs|[[:alnum:]]\.sh)[[:alnum:][:space:]\/_-]+/ /g  ; s/\/[[:alnum:]\*\/_-]+/ /g  ; s/ALL.*=[[:space:]]\(?[[:alnum:]]+?\)?/ /g  ; s/ALL.*=/ /g  ; s/^[[:alpha:]]+_Alias[[:space:]]+[[:alnum:]_-]+[[:space:]]+=/ /g  ; s/[[:space:],]+-[-]?[[:alnum:]_-]+//g  ; s/[[:space:],]+|\![[:alnum:]_-]+|=[[:space:]]+?=[[:space:]]+/ /g  ; s/([ ,]|^)(start|stop|restart|status|checkconfig|reload|omsagent|cybAgent|list|apache|nginx|nagios|docadmin|zoomadmin|faulty|procmon|artifactory|ZOOMADMIN|oracle|procwww|daemon|mail|_CISSYS)[[:space:]]/ /g  ; s/ +(\.[[:alnum:]_]+)+/ /g  ; s/ [[:alnum:]]{1,5} / /g  ; s/(\*|DEFAULT.*exit 0)/ /g  ; /^[[:space:]]+?$/d  ; s/\([[:alpha:]]*\)/ /g  ; s/ \.[0-9]+\.[0-9]+[[alpha:]]+ / /g  ; s/[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/ /g  ; s/ ([.?!,;:"'"'"'()\[\]\{\}\\\\_-]+) /\1/g  ; s/ \\\\ / /g  ; s/([ ,]|^)\.[[:alnum:]]+[[:space:]]/ /g  ; s/( |^)[[A-Z][0-9]_]+( |$)/ /g  ; s/[[:alnum:]_-]+\s(install|remove)\s(http[s]?[\\]?:|[[:alnum:]_-]+)/[\s\\]/g  ; s/[[:alnum:]_-]+\\:/ /g  ; s/\sREQ[[:alnum:]_-]+\s/ /g  ; s/\s(start|stop|status|restart|crs|@[[:alnum:]\.]+|[_]?CMD[S]?|[_]?[[:alnum:]]+_CMD[S]?)\s/ /g  ; s/AGS[[:alnum:]_]+(USERS|HOSTS)//g  ; s/\\/ /g  ; /^(\s+)?$/d  ; s/=.*$//g  ; s/[ ][0-9]+(\s|$)//g  ; ' "${fileSudoers}" | tr ' ' '\n' | sed -E '/^$/d  ; s/\..*$//g ; /^_[[:alnum:]_]+?CM[N]?D[S]?$/d ; /^[[:punct:]]+[[:alnum:]]?$/d ; /:[[:alnum:]_-]+/d' | sed -E "s/^(${patCustomFilter})$/ /g" | sort -Vu )
#; for i in ${arrAccountList} ; do echo "Account: ${i}" ; done

}

fnIsUserActive() {


  strStep="Line ${LINENO}\t: ${FUNCNAME} : Checking ${fileActiveUsers} for ${curUsername}"
  ${cmdEcho} "${strStep}"
  fnSpinner
  if grep -i "${curUsername}" "${fileActiveUsers}" -s > /dev/null;
  then
    ${cmdEcho} -e "${curUsername} is an active user in ${fileSudoers}." | ${cmdTee} "${fileLog}"
    arrUserValid+=("${curUsername}")
  else
    ${cmdEcho} -e "${curUsername} is not an active account and should be deleted from ${fileSudoers}."  | ${cmdTee} "${fileLog}"
    arrUserInvalid+=("${curUsername}")
  fi


#   gawk -v IGNORECASE=1 -v myvar="${curUsername}" -v FPAT='[^,]*|\"([^\"]|\"\")*\"' '
#   BEGIN {
#     notfound = 1
#   }
#   {
#     for (i = 1; i <= NF; i++) {
#       field_content = $i
#       if (substr(field_content, 1, 1) == "\"") {
#         field_content = substr(field_content, 2, length(field_content) - 2)
#       }
#
#       if (field_content ~ myvar) {fi
#         #print $2
#         notfound = 0
#         exit # Exit immediately after finding the first match
#       }
#     }
#   }
#   END {
#     if (notfound == 1) {
#       exit 1
#     } else {
#       exit 0
#     }
#   }' "${fileActiveUsers}"
#   ${cmdEcho} "$Line ${LINENO} : Finished Checking ${fileActiveUsers} for ${curUsername}"
}


fnDeleteRules() {

#   if [ ${optCleanComments} -eq 1 ]
  while read curUsername;
  do
    if ! fnIsUserActive
    then
      if [ ${optDelete} == 1 ];
      then
        strStep="Line${chrTab}${LINENO} : ${FUNCNAME} : Scanning ${fileSudoers} for ${curUsername} in sudoer rules"
        fnSpinner
        strStep="${LINENO}){ : ${FUNCNAME} : Removing ${curUsername}'s rules from ${fileSudoers}"
        ${cmdEcho} "${strStep}"
        sed -E ${optCommit} "/${patRule}/Id" "${fileSudoers}"
      fi
      if [ ${optCleanAliases} -eq 1 ]
      then
        strStep="Line${chrTab}${LINENO} : ${FUNCNAME} : Scanning ${fileSudoers} for ${curUsername} in aliases"
        fnSpinner
        sed -E ${optCommit} "/${patAlias}/{ s/(${curUsername}[[:space:]]+?,)//Ig}" "${fileSudoers}"
      fi
      ((intCounter++))
    fi
  done  < <( if [ ${optCleanComments} -eq 1 ]
  then
    patRule='^#[^#][[:space:]]?^(|Defaults|[[:alpha:]]+_Alias|%|$)[[:space:]]?${curUsername}.*$' ;
    PatAlias="^([#][[:space:]]?)[[:alpha:]]+_Alias[[:space:]]+[[:alnum:]_-]+[[:space:]]+?="
  else patRule='^[[:space:]]?^(|Defaults|[[:alpha:]]+_Alias|%|$)[[:space:]]?${curUsername}.*$' ;
    patAlias='^[^#][[:alpha:]]+_Alias[[:space:]]+[[:alnum:]_-]+[[:space:]]+?=' ; \
  fi ;
  awk -v pattern="(${patRule}|${patAlias})"  '$0 ~ pattern {print $1}' "${fileSudoers}" "${fileSudoers}"  | sort -Vu)
    #patAlias='^[^#][[:alpha:]]+_Alias[[:space:]]+[[:alnum:]_-]+[[:space:]]+?=' ;
#  awk -v pattern="(${patRule}|${patAlias})"  '$0 ~ pattern {print $1}' "${fileSudoers}" "${fileSudoers}" | sed -E '/^#[#[:punct:]]/d' | sort -Vu)

  # regex NOT substring: ^((?!error).)*$
#(awk -v pattern="^#([[:space:]]?|Defaults|[[:alpha:]]+_Alias|%|$)"  '$0 ~ pattern {print $1}' "${fileSudoers}" | sort -Vu)

}

function fnRemoveRules() {

  if [ ${optCleanComments} -eq 1 ]
  then
    patRule='^[#]?(Defaults|[[:alpha:]]+_Alias|%|$)'
  else
    patRule='^(Defaults|[[:alpha:]]+_Alias|%|$)'
  fi

  if [ ! -z ${dirMoveTarget} || ${optDelete} -eq 1 ]
  then
    while read curUsername;
    do
      strStep="Line ${LINENO} : ${FUNCNAME} : Scanning for ${curUsername}"
      fnSpinner
      if ! fnIsUserActive
      then
        while read curFile;
        do
          fileContainsUser=$(grep -isl "${curUsername}" "${curFile}");
          if [ ! -z ${fileContainsUser} ]
          then
            if [ ! -d "${dirTarget}/${dirMoveTarget}" ]
            then
              echo "Directory ${dirTarget}/${dirMoveTarget} does not exist; attempting to create it now."
              if ! mkdir ${optVerbose}  "${dirTarget}/${dirMoveTarget}"
              then
                echo "Unable to create ${dirTarget}/${dirMoveTarget} at ${LINENO} in ${FUNCNAME}. Bailing out. "
                exit 1
              fi
            else
              mv ${optVerbose} "${curFile}" "${dirTarget}/${dirMoveTarget}"
            fi
            unset fileContainsUser;
          fi
        done < <(find ${dirTarget} -maxdepth 1 -type f -name "*.tmp-rule");
      fi
    done  < <(awk '$0 !~ /^(#|Defaults|[[:alpha:]]+_Alias|$)/ {print $1}' "${fileSudoers}" | sort -Vu)
  fi
}

fnHelp() {
echo -e "
    ${otagBold}-h | --help${ctag}
        Display this screen

    ${otagBold}-a | --active${ctag}
       The file containing the list of words for the search spec (words to find)

       This is the filename of the accounts CSV file.

       Be sure to generate your CSV encapsulating the fields in
       double quotes!

       Format:  \"filename,field\"

       Example: \"--accounts AD_Users.csv,2\"

       NOTE: The field selector is not implemented yet; it is hard-coded
       for now.

    ${otagBold}-D | --delete${ctag}
       Instead of processing the --split --filespec ${otagItal}[filespec*.tmp-rule]${ctag}
       files and ${otagBold}--move${ctag} ${otagItal}[directory]${ctag} them to a subdirectory,
       delete them directly from --sudoersfile

    ${otagBold}-f | --filespec ${ctag}${otagItal}[filespec]${ctag}
       This is the filespec of the numbered sudoers files you wish to
       analyze and process.

       This assumes that you've --split the sudoers file for processing35735
       using sudoers-util.

       Example: --filespec

    ${otagBold}-q | --quoted${ctag}
       Use this option if the CSV fields contain commas;
       this will cause the utility to expect quoted fields.
       (NOT YET IMPLEMENTED)

    ${otagBold}-r | --rulesdirectory ${ctag}${otagItal}[directory]${ctag}
       This is the directory path where inactive rule files are
       located. This assumes that you've --split the sudoers file.

    ${otagBold}-R | --report | --log ${ctag}${otagItal}[Log Filename]${ctag}
       Specifying logging will capture most output and log most actions
       to the specified filename.

    ${otagBold}-m | --move ${ctag}${otagItal}[directory]${ctag}
       This is the directory path where inactive rule files should
       be relocated to. This assumes that you've --split.
       This will be created a subdirectory of ${ctag}${otagItal}--rulesdirectory${ctag}.

    ${otagBold}-c | --cleancomments${ctag}
       Process comments as well

    ${otagBold}-s | --sudoersfile ) shift${ctag}
       This is the complete flattened and recombined sudoers file to review

       Example: ${otagBold}--filespec${ctag} ${otagItal}[sudoersfile]${ctag}

    ${otagBold}-v | --verbose ) optVerbose="-v"${ctag}
       Word vomit (helpful for debugging)

    ${otagRed}NOTE: If filenames include spaces or extended ASCII characters, DO
    fully escape the filenames with quotes or \\!!${ctag}
"
}



##############################
#
# Did user ask us to do anything? If not, let's blow this joint!

if [[ -z "$@" ]];
then
  echo -e "${otagRed}You supplied no command arguments; unable to proceed.${ctag}";
  echo "Your command line:";
  echo -e "\t$cmdLine\n";
  fnHelp;
  exit 1;
fi;
###############################
# Since user gave us stuff to do, let's process arguments. Party on!
while [ "$1" != "" ] ;
do
  case $1 in
    -h | --help )     fnHelp;
                      exit 0;
                      ;;
    -a | --active )   shift;
                      fileActiveUsers="$1";
                      ;;
    -A | --abbreviate ) cmdAbbreviate="tail -n 20"
                      ;;
    -C | --cleanaliases ) optCleanAliases="1";
                      ;;
    -c | --cleancomments ) optCleanComments="1";
                      ;;
         --commit )   optCommit="-i"
                      ;;
    -D | --delete )   optDelete="1";
                      ;;
    -f | --filespec ) shift;
                      strFilespec="$1"
                      ;;
    -L | --log ) shift;
                      fileLog="${1}"
                      cmdLog="echo"
                      cmdTee="tee -a"
                      optLog="1"
                      ;;
    -m | --move )     shift;
                      dirMoveTarget="$1"
                      ;;
    -q | --quoted )   optCsvQuoted="1"
                      ;;
    -r | --report ) optReport="1"
                      ;;
    -s | --sudoersfile ) shift;
                      fileSudoers="$1";
                      ;;
    -v | --verbose )  optVerbose="-v";
                      cmdEcho="echo"
                      ;;
    -r | --rulesdirectory ) shift;
                      dirTarget="$1";
                      ;;
    * )
                    echo -e "${otagRed} \n\tI couldn't understand your command. Please note if you specified an argument with spaces ";
                    echo -e "\t or extended ASCII, you will need to escape those characters and/or use quotes a"%*s" round the path.\n${ctag}";
                    echo "Your command line:";
                    echo -e "\t$cmdLine\n";
                    fnHelp;
                    exit 1
                    ;;
  esac ;
  shift ;
done;

if [ "${optReport}" -eq 1 ];
then
  if [ -f  ${fileSudoers} ] && [ -f ${fileActiveUsers} ];
  then
    echo -e "You asked me to report on active and invalid accounts:\n" | ${cmdTee} "${fileLog}"
    if [[ ! "${cmdAbbreviate}" == "cat" ]];
    then
      echo -e "\tNote: Output is abbreviated by tail -n 20";
    fi;
    echo -e "\tNote: Applying custom word filter: ${patCustomFilter}\n"
    fnGetUserList
    unset arrUserValid arrUserInvalid
    for curUsername in ${arrAccountList};
    do
      fnIsUserActive;
    done;
    echo "A total of ${#arrUserInvalid[@]} invalid accounts were found between users, groups, and hosts:" | ${cmdTee} "${fileLog}"
    for item in ${arrUserInvalid[@]}
    do
      echo "${item}"
    done | ${cmdAbbreviate};
    echo "A total of ${#arrUserValid[@]} valid accounts were found between users, groups, and hosts:" | ${cmdTee} "${fileLog}"
    for item in ${arrUserValid[@]}
    do
      echo "${item}"
    done | ${cmdAbbreviate};
    exit 0;
  fi;
fi;



if [ ${optDelete} == 1 ];
then
  ${cmdEcho} -en "You asked us to delete inactive users "
  if [ ! -z  ${fileSudoers} ]
  then
    ${cmdEcho} -en "from ${fileSudoers} }"

    ${cmdEcho} "You requested that we compare ${dirTarget} rules against ${fileSudoers}."
    if [ ! -z ${fileActiveUsers} ]
    then
      fnDeleteRules
    fi
  fi
fi

if [ ! -z ${dirMoveTarget} ] ;
then
  ${cmdEcho} "You requested that we move inactive sudoer rules to ${dirTarget}/${dirMoveTarget}."
  if [ ! -z  ${fileSudoers} ]"%*s" "%*s"
  then
    ${cmdEcho} "You requested that we compare ${dirTarget} rules against ${fileSudoers}."
    if [ ! -z ${fileActiveUsers} ]
    then
      ${cmdEcho} "You requested that we compare the users in ${dirTarget}/${dirMoveTarget} and ${fileSudoers} to verify they are in fileActiveUsers."
      if [ ! -z ${strFilespec} ]
      then
        fnRemoveRules
      fi
    fi
  fi
fi
echo -e "\n${intCounter} deleted/inactive users actioned."
