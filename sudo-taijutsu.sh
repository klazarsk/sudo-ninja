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
otagRed='\e[0;31m';
otagRevRed='\e[0;101m';
otagUline="\e[4m";
otagItal="\e[3m";
chrTab='\t';
#########################
#
# Clear variables so we don't inherit settings from sourced runs:

unset optVerbose optCommit;
eval {optDelete,optVerbose,optReport,optQuiet}=0
unset optVerbose fileInput dirTemp optFilePrefix optOutputFile dirWorking strStep fileLog arrUserInvalid arrUserValid;
# Initialize these variables for unary expressions:
eval optCleanComments,optMonitor,optCsvQuoted,Split,optOverwrite,optRecombine,optFlatten,optLog}=0;

#########################
#Set some sane defaults
optSilent="-s";
cmdLog="true";
set +x;
dtStart="$(date +"%s")";
dtStart8601="$(date --date="@${dtStart}" +"%Y-%m-%d_%H:%M:%S")";
cmdEcho="true";
cmdTee="true";
cmdAbbreviate="cat";
cmdLine="${0} ${@}";
intScreenWidth=$(( $(tput cols) - 18 ));
dtBackupSuffix="$(date +"%Y-%m-%d_%H%M%S")";
cmdDbgEcho="true";
cmdDbgRead="true";
cmdDbgSleep="true";
# cmdDbgEcho=true;
##########
#
# Notes, snippets
#
# add a --configfile feature so multiple configurations can be possible
#
#
#
##########

function fnSpinner() {
# Check if we're running verbose mode.
# if we are, don't run the spinner!

  if [ -z ${optVerbose} ];
  then
    if [ -z "${gfxSpin}" ];
    then
      gfxSpin="/";
    fi;
    echo -en "\x1b[2K\r${otagBold} ${strStep}    ${gfxSpin} ${ctag}\r";
    case "${gfxSpin}" in
      "/" ) gfxSpin="-";
        ;;
      "-" ) gfxSpin="\\";
        ;;
      "\\" ) gfxSpin="|";
        ;;
      "|" ) gfxSpin="/";
        ;;
      "/" ) gfxSpin="-";
        ;;
      "-" ) gfxSpin="\\";
        ;;
      "\\" ) gfxSpin="|";
        ;;
      "|" ) gfxSpin="/";
        ;;
    esac;
  else
    return 0;
  fi;
}

function fnGetUserList() {

arrAccountList=$( sed -E ' /#(.*[^=].*|.*\s?[[:alnum:]_-]+\s?,\^C[[:alnum:]_-]+\[,]?)$/d ; /^(Defaults.*|#\s?)$/d  ; s/(\/(usr)|)\/bin\/su -\s+?([[:alnum:]_-]+?|)\s+?/ /g ; s/NOPASSWD\:[[:alnum:] /_-]+/ /g ; s/\/(usr|bin|etc|opt|tmp)\/[[:alnum:] \/_-]*(systemctl|pcs|[[:alnum:]]\.sh)[[:alnum:][:space:]\/_-]+/ /g ; s/\/[[:alnum:]\*\/_-]+/ /g ; s/ALL.*=[[:space:]]\(?[[:alnum:]]+?\)?/ /g ; s/ALL.*=/ /g ; s/^[[:alpha:]]+_Alias[[:space:]]+[[:alnum:]_-]+[[:space:]]+=/ /g  ; s/[[:space:],]+-[-]?[[:alnum:]_-]+//g  ; s/[[:space:],]+|\![[:alnum:]_-]+|=[[:space:]]+?=[[:space:]]+/ /g ; s/([ ,]|^)(start|stop|restart|status|checkconfig|reload|omsagent|cybAgent|list|apache|nginx|nagios|docadmin|zoomadmin|faulty|procmon|artifactory|ZOOMADMIN|oracle|procwww|daemon|mail|_CISSYS)[[:space:]]/ /g ; s/ +(\.[[:alnum:]_]+)+/ /g ; s/ [[:alnum:]]{1,5} / /g  ; s/(\*|DEFAULT.*exit 0)/ /g ; /^[[:space:]]+?$/d ; s/\([[:alpha:]]*\)/ /g ; s/ \.[0-9]+\.[0-9]+[[alpha:]]+ / /g ; s/[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/ /g ; s/ ([.?!,;:"'"'"'()\[\]\{\}\\\\_-]+) /\1/g ; s/ \\\\ / /g ; s/([ ,]|^)\.[[:alnum:]]+[[:space:]]/ /g ; s/( |^)[[A-Z][0-9]_]+( |$)/ /g ; s/[[:alnum:]_-]+\s(install|remove)\s(http[s]?[\\]?:|[[:alnum:]_-]+)/[\s\\]/g  ; s/[[:alnum:]_-]+\\:/ /g ; s/\sREQ[[:alnum:]_-]+\s/ /g ; s/\s(start|stop|status|restart|crs|@[[:alnum:]\.]+|[_]?CMD[S]?|[_]?[[:alnum:]]+_CMD[S]?)\s/ /g  ; s/AGS[[:alnum:]_]+(USERS|HOSTS)//g ; s/\\/ /g ; /^(\s+)?$/d ; s/=.*$//g ; s/[ ][0-9]+(\s|$)//g ; ' "${fileSudoers}" | tr ' ' '\n' | sed -E '/^$/d  ; s/\..*$//g ; /^_[[:alnum:]_]+?CM[N]?D[S]?$/d ; /^[[:punct:]]+[[:alnum:]]?$/d ; /:[[:alnum:]_-]+/d' | sed -E "s/^(${patCustomFilter})$/ /g" | sed -E "s/^(${patCustomFilter2})$/ /g"| sort -Vu );

}


fnDeleteRules() {

  unset IFS POSIXLY_CORRECT;
  ${cmdEcho} "Line ${LINENO} : Entered ${FUNCNAME} to delete ${#arrUserInvalid[@]} users.";

  # Create a temporary file to hold the proposed changes
  local tmpSudoers=$(mktemp);
  cp "${fileSudoers}" "${tmpSudoers}";

  ${cmdDbgEcho} -e "\n\nLine ${LINENO} : About to start the user deletion step! (see ${tmpSudoers} and ${fileSudoers})";
  ${cmdDbgRead} -n 1 -s -r -p "Press any key to continue...";
  if [ -n "${1}" ];
  then
    echo "You elected to delete a single user.";
    unset arrUserInvalid;
    local arrUserInvalid="${1}";
    echo "The user you want to delete is: ${arrUserInvalid[@]}.";
  fi

  for curUsername in "${arrUserInvalid[@]}";
  do
    strStep="Line: ${LINENO} : ${FUNCNAME} : Removing ${curUsername}'s rules from ${fileSudoers}"
    fnSpinner;
    ${cmdEcho} -e "\n${strStep}\n" | ${cmdTee} "${fileLog}";

    ${cmdEcho} -e "\n\nLine ${LINENO} : User deletion routine is next\n";

    # Apply the sed commands to the temporary file
    sed -i -E "/^[^=]*\b${curUsername}\b[^=]*=/Id" "${tmpSudoers}";
    sed -i -E "s/(=.*)\b${curUsername}\b(\s*)?(.*\$)?/\1\3/g" "${tmpSudoers}";
  done


  ${cmdEcho} -e "\n\nLine ${LINENO} : Rule deletion cleanup routine is next; optRecombine == ${optRecombine}\n";
  ${cmdDbgEcho} -e "\n\nLine ${LINENO} : About to start the rule deletion cleanup step! (see ${tmpSudoers} and ${fileSudoers})";
  ${cmdDbgRead} -n 1 -s -r -p "any key to continue...";

  # Apply the cleanup sed commands to the temporary file
  sed -i -E 's/(\s*,\s*)+/, /g ; s/,[\s]+?$//g; s/=[\s]?,/=/g; s/ +/ /g; /^$/d' "${tmpSudoers}";
  sed -i -E 's/=\s,//g' "${tmpSudoers}";
  sed -i -E '/^#/!s/,[[:blank:]]?*$//'  "${tmpSudoers}";


  # Now let's delete aliases that have been orphaned, but report them first
  if [ ${optOrphaned} -eq 1 ];
  then
    ${cmdDbgEcho} -e "\n\nLine ${LINENO} : About to start the orphaned alias deletion step! (see ${tmpSudoers} and ${fileSudoers})";
    ${cmdDbgRead} -n 1 -s -r -p "Line ${LINENO} : Press any key to continue...";
    echo -e "\nThe following orphaned aliases will be deleted from ${fileSudoers} (Preview)";
    sed -i -E '/^#/! { /=[^[:alnum:]]*$/d }' "${tmpSudoers}";
  fi

  # Display the proposed changes using diff for items in ${arrUserInvalid[@]}
  if [ ${optQuiet} -ne 1 ];
  then
    echo -e "\n--- Proposed Changes to ${fileSudoers} (in diff format)---";
    if diff -u "${fileSudoers}" "${tmpSudoers}";
    then
      echo "No changes detected.";
    fi
  fi

  # Apply changes only if --commit is specified
  if [ -n "${optCommit}" ] ; then
    echo -e "\n--- Applying changes to ${fileSudoers} ---";
    echo -e "\n-------------------------------------------------------------------------\nThe following changes were made to ${fileSudoers}; during the fnDeleteRules step.\n" >> "${fileLog}";
    echo -e "Explain the diff and how to read it.";
    diff -u "${fileSudoers}" "${tmpSudoers}" >> "${fileLog}";
    echo -e "\n-------------------------------------------------------------------------------\n" >> "${fileLog}";
    mv -v "${tmpSudoers}" "${fileSudoers}";
    echo "Changes applied to ${fileSudoers}.";
  else
    echo -e "\n--- Dry run complete. No changes were written. ---";
    rm "${tmpSudoers}" # Clean up the temporary file
  fi
}


fnDeleteComments() {

  if [ ${optQuiet} -ne 1 ];
  then  if [ ${optQuiet} -ne 1 ];
  then
    echo "The following comments will be deleted:";
    sed -En '/^#/{/([[:digit:]]{1,2}[\/-][[:digit:]]{1,2}[\/-]([[:digit:]]{4}|[[:digit:]]{2}))|([J][Aa][Nn]|[Ff][Ee][Bb]|[Mm][Aa][Rr]|[Aa][Pp]Rr]|[Mm][Aa][Yy]|[Jj][Uu][Nn]|[Jj][Uu][Ll]|[Aa][Uu][Gg]|[Ss][Ee][Pp]|[Oo][Cc][Tt]|[Nn][Oo][Vv]|[Dd][Ee][Cc])[[:alpha:]]+?\b(\s?[\/-]?[0-9]{1,2}[ ,\/-]\s?[0-9]{2,4})/!p}' "${fileSudoers}";
  fi;
    echo -e "\n\nThe following comments will be deleted:" | ${cmdTee} "${fileLog}";
    sed -En '/^#/{/([[:digit:]]{1,2}[\/-][[:digit:]]{1,2}[\/-]([[:digit:]]{4}|[[:digit:]]{2}))|([J][Aa][Nn]|[Ff][Ee][Bb]|[Mm][Aa][Rr]|[Aa][Pp]Rr]|[Mm][Aa][Yy]|[Jj][Uu][Nn]|[Jj][Uu][Ll]|[Aa][Uu][Gg]|[Ss][Ee][Pp]|[Oo][Cc][Tt]|[Nn][Oo][Vv]|[Dd][Ee][Cc])[[:alpha:]]+?\b(\s?[\/-]?[0-9]{1,2}[ ,\/-]\s?[0-9]{2,4})/!p}' "${fileSudoers}" | ${cmdTee} "${fileLog}";
  fi;

  # Strip all comments which do not include a date
  if [ ${optCommit} -eq 1 ] ;
  then
    sed -i -E '/^#/{/([[:digit:]]{1,2}[\/-][[:digit:]]{1,2}[\/-]([[:digit:]]{4}|[[:digit:]]{2}))|([J][Aa][Nn]|[Ff][Ee][Bb]|[Mm][Aa][Rr]|[Aa][Pp]Rr]|[Mm][Aa][Yy]|[Jj][Uu][Nn]|[Jj][Uu][Ll]|[Aa][Uu][Gg]|[Ss][Ee][Pp]|[Oo][Cc][Tt]|[Nn][Oo][Vv]|[Dd][Ee][Cc])[[:alpha:]]+?\b(\s?[\/-]?[0-9]{1,2}[ ,\/-]\s?[0-9]{2,4})/!d}' "${fileSudoers};";
  fi;

}

fnIsUserActive() {


  strStep="Line ${LINENO} : ${FUNCNAME} : Checking ${fileActiveUsers} for ${curUsername}";
  ${cmdEcho} "${strStep}";
  fnSpinner;
  if grep -i "${curUsername}" "${fileActiveUsers}" -s > /dev/null;
  then
    arrUserValid+=("${curUsername}");
  else
    arrUserInvalid+=("${curUsername}");
  fi;

}



fnHelp() {
echo -e "

${otagBold}Command line:${ctag} ${cmdLine}

    ${otagBold}-h | --help${ctag}

      Display this screen

    ${otagBold}-a | --active${ctag} ${otagItal}ActiveDirectoryUserList${ctag}

      The file containing the list of words for the search spec (words to find)

      For now, this is a single, monolithic list of accounts to be preserved; to
      create the file, concactenate a list of user account names, hostnames,
      and group names from your Active Directory or LDAP directory, and concat-
      enate them together to create one monolithic list.

    ${otagBold}-c | --cleancomments${ctag}

      Process comments as well

    ${otagBold}-C | --config ) [configfile]${ctag}

      Load a custom config file containing patCustomFilter and patCustomFilter2
      variable assignments. If this option is not specified, then


      These should contain regular expressions, with each
      expression pipe ( | ) delimited. Example:

      patCustomFilter='apache|root|oracle|mysql|sysadmin|dmadmin|docadmin|nagios|noc|patternfoo|patternbar|pattern-etc';
      patCustomFilter2='pattern1|pattern2|etc';


    ${otagBold}-b | --batchdelete${ctag}

      Batch delete accounts that are not present in the `--active` account list,
      unless they're present in the patCustomFilter variables for preservation
      regardless of whether they are in the user list from your federated
      authentication list. This will work directly against --sudoersfile.

    ${otagBold}-d | --deleteuser${ctag} ${otagItal}username${ctag}

      To manually specify a single user; this is useful for scripting and one-
      off user deletions (good for day-to-day maintenance when only a small
      handful of users is deleted).

    ${otagBold} -D | --debug

        Debug mode which turns on sleeps, pause breaks waiting for keypress
        to continue, allowing for review and analysis of intermediate files

    ${otagBold}-f | --filespec ${ctag}${otagItal}[filespec]${ctag}
      This is the filespec of the numbered sudoers files you wish to
      analyze and process.

      This assumes that you've --split the sudoers file for processing
      using sudoers-util. Only the prefix of the file needs to be specified;
      do not specify a wildard.

      Example: --filespec nosudoers

    ${otagBold}-O | --orphaned ${ctag}
      Delete orphaned Aliases. In other words, if an alias is left with no tokens
      or only one token to the left of the equals (=) sign, the alias is orphaned
      and will be deleted.

    ${otagBold}-q | --quoted${ctag}
      Use this option if the CSV fields contain commas;
      this will cause the utility to expect quoted fields.
      (NOT YET IMPLEMENTED)

    ${otagBold}-r | --rulesdirectory ${ctag}${otagItal}[directory]${ctag}
      This is the directory path where inactive rule files arekeypress
      located. This assumes that you've --split the sudoers file.

    ${otagBold}-R | --report | --log ${ctag}${otagItal}[Log Filename]${ctag}
      Specifying logging will capture most output and log most actions
      to the specified filename.

    ${otagBold}-m | --move ${ctag}${otagItal}[directory]${ctag}
      This is the directory path where inactive rule files should
      be relocated to. This assumes that you've --split.
      This will be created a subdirectory of ${ctag}${otagItal}--rulesdirectory${ctag}.

    ${otagBold}-s | --sudoersfile ${ctag}
      This is the complete flattened and recombined sudoers file to review

      Example: ${otagBold}--filespec${ctag} ${otagItal}[sudoersfile]${ctag}

    ${otagBold}-S | --syntax${ctag}
      Validate output file with visudo.


    ${otagBold}-v | --verbose ${ctag}
      Word vomit (helpful for debugging)

    ${otagRed}NOTE: If filenames include spaces or extended ASCII characters, DO
    fully escape the filenames with quotes or \\!!${ctag}
" | less -R
}



##############################
#
# Did user ask us to do anything? If not, let's blow this joint!

if [[ -z "$@" ]];
then
  echo -e "${otagRed}You supplied no command ${curUsername}[ ]?arguments; unable to proceed.${ctag}";
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
    -b | --batchdelete )   optDelete="1";
                      ;;
    -c | --cleancomments ) optCleanComments="1";
                      ;;
           --commit ) optCommit="-i"
                      ;;
    -C | --config )   shift;
                      fileConfig="$1"
                      ;;
    -D | --debug )    optDebug="1";
                      cmdDbgRead="read";
                      cmdDbgSleep="sleep";
                      cmdDbgEcho="echo";
                      ;;
    -d | --deleteuser ) shift;
                      strDeleteUser="${1}";
                      optUserDelete=1;
                      ;;
    -f | --filespec ) shift;
                      strFilespec="${1}";
                      ;;
    -L | --log )      shift;
                      fileLog="${1}";
                      cmdLog="echo";
                      cmdTee="tee -a";
                      optLog="1";
                      ;;
    -m | --move )     shift;
                      dirMoveTarget="${1}";
                      ;;
    -O | --orphaned ) optOrphaned="1";
                      ;;
    -q | --quoted )   optCsvQuoted="1";
                      ;;
    -Q | --quiet )    optQuiet="1";
                      ;;
    -r | --report )   optReport="1";
                      ;;
    -s | --sudoersfile ) shift;
                      fileSudoers="${1}";
                      ;;
    -S | --syntax )   optSyntaxCheck="1";
                      ;;
    -v | --verbose )  optVerbose="-v";
                      cmdEcho="echo";
                      ;;
    -r | --rulesdirectory ) shift;
                      dirTemp="${1}";
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

echo -e "
################################################################################
#

    ######   #######   #####   ###  #     #        ######   #     #  #     #
    #     #  #        #     #   #   ##    #        #     #  #     #  ##    #
    #     #  #        #         #   # #   #        #     #  #     #  # #   #
    ######   #####    #  ####   #   #  #  #        ######   #     #  #  #  #
    #     #  #        #     #   #   #   # #        #   #    #     #  #   # #
    #     #  #        #     #   #   #    ##        #    #   #     #  #    ##
    ######   #######   #####   ###  #     #        #     #   #####   #     #

${dtStart8601}: sudo-chop started.\n" | ${cmdTee} "${fileLog}" ;

##############################
#
# Token preservation filter
#
# This is a customizable word filter, to filter out words that our initial
# attempt at deleting non-account words from the sudoers filePlease modify this to handle more than two commas in a row (with optional whitespace), replacing them with a single comma
# it's impossible to arrive at a one-size-fits-all without a massive increase
# in lines of code (for which bash isn't terribly efficient)

# patCustomFilter='2c912219|_CISSYS|-cert-db|ALL|zoom[[:alnum:]-]+|apache|pattern8|pattern9|etc'

if [ -f /etc/sudo-ninja.conf ] || [ -n "${fileConfig}" ];
then
  if [ -n "${fileConfig}" ] && [ -f "${fileConfig}" ];
  then
    echo -e "\n ${otagRed}Importing variables from ${fileConfig}...${ctag}";
    source "${fileConfig}";
  elif [ -n "${fileConfig}" ] && [ ! -f "${fileConfig}" ];
    echo "${otagRed}ERROR: --config ${fileConfig} is specified, however ${fileConfig} was not found.";
    fnHelp;
    exit 1;
  else
    echo -e "\n ${otagRed}Importing variables from /etc/sudo-ninja.conf...${ctag}";
    source /etc/sudo-ninja.conf;
  fi;
else
  patCustomFilter='apache|root|zoomadmin|oracle|vigadmin|tibadmin|sysadmin|dmadmin|docadmin|nagios|noc|netlog-mgr|vigadmin|_CISSYS|-cert-db|ALL|patternfoo|patternbar|pattern-etc';
  patCustomFilter2='pattern1|pattern2|etc';
fi;

#
#########################
# Check options for sanity:

if [ ${optQuiet} -eq 1 ] && [ "${optVerbose}" == "-v" ] ;
then
  echo -e "\n\n${otagRed}Error:${ctag} ${otagBold}--quiet${ctag} and ${otagBold}--verbose${ctag} options are mutually exclusive. Your command line:" ;
  echo -e "\n\t${otagRed}${cmdLine}${ctag}\n" ;
  exit 1 ;
fi ;

#
##############################
#
# Set the backup filename and back up the file

dtBackupSuffix="$(date +"%Y-%m-%d_%H%M")";
fileBackup="${fileSudoers}.${dtBackupSuffix}" ;
${cmdEcho} -e "\n\n${LINENO} : Backing up sudoers file to [${fileBackup}]." | ${cmdTee} "${fileLog}";
${cmdDbgEcho} -e "\n\nLine ${LINENO} : About to start the sudoers file backup." ;
${cmdDbgRead} -n 1 -s -r -p "Press any key to continue..."  ;
if [ -f "${fileBackup}" ];
then
  read -r -p "A backup file ${fileBackup} already exists; would you like to delete it? Yes/no: " strResponse ;
  if [[ "${strResponse}" =~ ^([yY][eE][sS]|[yY])$ ]] ;
  then
      echo "Deleting ${fileBackup}..." ;
      rm -v "${fileBackup}" ;
  else
      echo "Please archive or delete ${fileBackup}." ;
      exit 1
  fi ;
fi ;
cp -v "${fileSudoers}" "${fileBackup}" | ${cmdTee} "${fileLog}";
echo -e "\033[0K\rBacked up ${fileSudoers} to ${fileBackup}\n" | ${cmdTee} "${fileLog}";
#
##############################

if [ -f  "${fileSudoers}" ] && [ -n "${fileActiveUsers}" ];
then
  ${cmdEcho} -e "\n\n${LINENO} : Generate inactive user list routine is next.\n" | ${cmdTee} "${fileLog}";
  ${cmdDbgEcho} -e "\n\nLine ${LINENO} : About to start the inactive user list generation!" ;
  ${cmdDbgRead} -n 1 -s -r -p "Press any key to continue..."  ;
  echo -e "\n\tNote: Applying custom token filter: ${patCustomFilter}\n" | ${cmdTee} "${fileLog}"
  fnGetUserList
  for curUsername in ${arrAccountList};
  do
  fnIsUserActive;
  done;
  ${cmdEcho} "We got the inactive user list:" | ${cmdTee} "${fileLog}" ;
fi




intTableColumns=$(echo "$(tput cols) / 20 " | bc);

if [ -f "${fileSudoers}" ] && [ -n "${fileActiveUsers}" ];
then
  if [ "${optQuiet}" -ne 1 ];
  then
    echo -e "You asked me to report on active and invalid accounts." | ${cmdTee} "${fileLog}" ;
    echo "A total of ${#arrUserInvalid[@]} invalid accounts were found between users, groups, and hosts:" ;
    for item in ${arrUserInvalid[@]} ;
    do
      echo "${item}";
    done | pr  -T --columns=${intTableColumns} --width=$(tput cols) --length=$(echo "${#arrUserInvalid[@]} / ${intTableColumns}" | bc)  | ${cmdTee} "${fileLog}";
    ${cmdDbgRead} -n 1 -s -r -p "(press shift-pageup and shift-pagedown to scroll) / Press any other keys to continue...";

    echo -e "\nA total of ${#arrUserValid[@]} valid accounts were found between users, groups, and hosts:" | ${cmdTee} "${fileLog}";
    for item in ${arrUserValid[@]} ;
    do
      echo "${item}";
    done| pr  -T --columns=${intTableColumns} --width=$(tput cols) --length=$(echo "${#arrUserInvalid[@]} / ${intTableColumns}" | bc)  | ${cmdTee} "${fileLog}";
    ${cmdDbgRead} -n 1 -s -r -p "(press shift-pageup and shift-pagedown to scroll) / Press any other keys to continue...";
  else
    echo "A total of ${#arrUserInvalid[@]} invalid accounts were found between users, groups, and hosts." | ${cmdTee} "${fileLog}";
    echo "A total of ${#arrUserValid[@]} valid accounts were found between users, groups, and hosts." | ${cmdTee} "${fileLog}";
  fi;
fi;


${cmdEcho} -e "\n\n${LINENO} : Rule deletion routine is next.\n";
${cmdDbgEcho} -e "\n\nAbout to start the rule deletion step!" ;
${cmdDbgRead} -n 1 -s -r -p "Press any key to continue..." ;

${cmdEcho} "Line ${LINENO} : About to check value of \${optDelete}(=1)";
if [ ${optDelete} -eq 1 ];
then
  ${cmdEcho} -en "Line ${LINENO} : You asked us to delete inactive users ";
  if [ -f "${fileSudoers}" ];
  then

    fnDeleteRules ;
    echo -e "\n${#arrUserInvalid[@]} deleted/inactive users actioned.";
  fi
fi

if [ -n "${strDeleteUser}" ]
then
  ${cmdEcho} -e "\n\n${LINENO}  : Deletion of individual user [${strDeleteUser}] is next.\n" | ${cmdTee} "${fileLog}";
  ${cmdDbgEcho} -e "\n\nAbout to start the single user deletion step!";
  ${cmdDbgRead} -n 1 -s -r -p "Press any key to continue...";
  fnDeleteRules "${strDeleteUser}";
fi


${cmdEcho} -e "\n\n${LINENO} : Comment deletion routine is next.\n" ;
${cmdDbgEcho} -e "\n\nLine ${LINENO} : About to start the comment deletion step!" ;
${cmdDbgRead} -n 1 -s -r -p "Line ${LINENO} : Press any key to continue..." ;

if [ ${optCleanComments} -eq 1 ] ;
then
  echo "Deleting all comments which do not contain a date..." ;
  fnDeleteComments ;
fi;

if [ "${optSyntaxCheck}" -eq 1 ];
then
  ${cmdEcho} -e "\n\n${LINENO} : Syntax check of sudoers file is next/\n";
  ${cmdDbgEcho} -e "\n\nLine ${LINENO} : About check syntax of [${fileSudoers}]." ;
  ${cmdDbgRead} -n 1 -s -r -p "Line ${LINENO} : Press any key to continue..." ;
  echo -e "\n\n Checking ${fileSudoers} syntax and integrity with visudo:"  | ${cmdpatCustomFilter2Tee} "${fileLog}";
  visudo -c -f "${fileSudoers}"  | ${cmdTee} "${fileLog}";
fi;

echo -e "\nIt is finished." ;

dtFinish="$(date +"%s")" ;
dtDuration=$(( ${dtFinish} - ${dtStart} )) ;
dtDurationMinutes=$(( ${dtDuration} / 60 )) ;
dtDurationSeconds=$(( ${dtDuration} % 60 )) ;
dtFinish8601="$(date --date="@${dtFinish}" +"%Y-%m-%d_%H:%M:%S")" ;
echo -e "Processing started at ${dtStart8601} and completed at ${dtFinish8601},taking ${dtDurationMinutes}m:${dtDurationSeconds}s.\n

        #######  #     #  ######         ######   #     #  #     #
        #        ##    #  #     #        #     #  #     #  ##    #
        #        # #   #  #     #        #     #  #     #  # #   #
        #####    #  #  #  #     #        ######   #     #  #  #  #
        #        #   # #  #     #        #   #    #     #  #   # #
        #        #    ##  #     #        #    #   #     #  #    ##
        #######  #     #  ######         #     #   #####   #     #
#
################################################################################"  | ${cmdTee} "${fileLog}"

exit 0
