sudo-chop.sh 5 "November 2025" sudo-chop.sh "User Manual"
==================================================

## NAME
sudo-chop.sh \- Sudo ninja sudoers preprocessor and expired rules deletion


## SYNOPSIS

**sudo-chop.sh --input** _monolithic-sudoers-file_ **--tempdir** \
 _rules-east-paredmore_ **--flatten --split --outputfile** _nosudoers-output-file_ \
 **--expire --recombine --prefix** _myway_ **--log** _/path/to/your/log-file-location.log_

## DESCRIPTION


**sudo-chop** is part of the sudo-ninja suite; this utility takes a monolithic
sudoers file, flattens all of the multi-line rules into a single line apiece,
splits the file into chunks with each file consisting of comment block followed
by a block of rules, and optionally removes expired rules before recombining the
split files back into a single monolithic sudoers file, with the final step
being to check syntax.


## OPTIONS

**-h | --help**
  Display help (this screen)

**-C | --check**
  Validate output file with visudo.

**-D | --debug**
  Debug mode which turns on sleeps, pause breaks waiting for keypress
  to continue, allowing for review and analysis of intermediate files
  (this debug mode does not turn on the bash debugger; for the bash debugger
  use -vvv | --plaid)

**-e | --expire**
  Expiration tags driven by EXP MM/DD/YY or EXP MM/DD/YYYY
  non-8601 date format driven by client's preexisting data. Utility
  converts all dates to ISO8601 format for internal processing. We do
  recommend switching to YYYY-MM-DD format for future EXP tags!

**--expirenewer** _[YYYY-MM-DD]_

  Expire rules which are NEWER than the specified date, but older than
  today's date $(date +"%Y-%m-%d").This option requires the --expire option.

  The date MUST be specified in ISO8601 format (YYYY-MM-DD).

**--expireolder** _[YYYY-MM-DD]_

  Expire rules which are OLDER than the specified date. The tool does not
  accept dates that are prior to the start of UNIX Epoch (1970-01-01). This 
  option requires the --expire option.

  The date MUST be specified in ISO8601 format (YYYY-MM-DD).
  
**-f | --flatten**
  This flattens multi-line aliases, rules, etc. into single, flat lines
  for easier processing and pruning of inactive/deleted users, hosts,
  groups, and orphaned aliases in cases where all member tokens have been
  removed.

**-i | --input** _[filename]_
  Input file you want to process

**-l | --log | --report** _[Log Filename]_
  Specifying logging will capture most output and log most actions
  to the specified filename.

**-m | --monitor**
  Monitor tail of ls -lhtr of target directory when appropriate.
  WARNING! This is VERY slow! Use ONLY for debugging!
  (not fully implemented/not tested yet)

**-M | --nomerge**
  Don't merge the comments back in - this is good for
  further processing of the split files before recombining.

**-n | --nocomment**
  Strip out all comments

**-o | --outputfile** _[filename]_
  outputfile (for recombined sudoers file)

**-O | --overwrite**
  Overwrite output file

**-p | --prefix** _[PREfix]_
  PREfix for the split files which are numbered in order the rules are
  found in --input file. This is for the temp files created in tempdir.

**-r | --recombine**
  Merge files back together into a monolithic sudoers file (file path
  specified by _--outputfile_).

**-s | --split**
  disassemble nosudoers into individual files for each comment+rules
  section for easier processing and flattening of rules

**-S | --syntax**
  Validate output file with visudo.

**-t | --tempdir** _[dirname]_
  temp directory to place working files  (should _not_ be /tmp!)

**-v | --verbose**
  words and stuff for debugging

**-vv | --verbose11**
  More verbosity, with bash debugger added in

**-vvv | --plaid**
  tl;dr summarycontrac:
    Lots and lots of debug output.

**-v | --version**
  Display the version number


## INSTALLATION

1. Open a terminal prompt and change to the directory where you want to clone sudo-ninja to


```
$ cd ~/Download
```

2. Open the repository in a web browser: https://github.com/klazarsk/sudo-ninja/

2. Click the green "code" button toward the right, then from the dropmenu, then
under the "Clone" tab in the dropmenu, select https and then copy the url

2. Back to the terminal, clone the repository to your current working directory:


```
$ git clone git@github.com:klazarsk/sudo-ninja.git
```

2. Copy the utilities to a directory in your PATH (optionally add ~/bin to your
PATH variable):

```
$ sudo cp {sudo-chop.sh,sudo-chop.sh} /usr/bin
```

2. Set the execute permission bit on the files

```
$ sudo chmod +x /usr/bin/{sudo-chop.sh,sudo-chop.sh}
```

2. Verify the utilities are accessible by trying to run the help screens:

```
$ sudo-chop.sh --help
$ sudo-cleanup.sh --help
```

## EXAMPLES

This example will take input file _monolithic-sudoers-file_, split it into
chunks which are placed in temporary directory _temp_directory_name_ with the file
prefix _myway_, flatten  all the rules, recombine the split files into
_nosudoers-output_file_, delete all the expired blocks, and log all actions
to _/path/to-your/log-file-location.log_:

**sudo-chop.sh --input** _monolithic-sudoers-file_ **--tempdir** _temp_directory_name_ \
 **--flatten --split --outputfile** _nosudoers-output-file_ **--expire --recombine \
 --prefix** _myway_ **--log** _/path/to/your/log-file-location.log_


The following example will take input file _monolithic-sudoers-file_, split it
into chunks which are placed in temporary directory _temp_directory_name_ with the
file prefix _east_, flatten all rules, recombine the split files into a monolithic
sudoers file named output-sudoers-file, and check the syntax upon completion,
but will not delete the expired rules, and log all actions to mylog.log:

**sudo-chop.sh --input** _monolithic-sudoers-file_ **--tempdir** _temp_directory_name_ \
**--flatten --split --outputfile** _output-sudoers_file_ **--recombine --prefix** \
_east_ **--log** _mylog.log_ **--syntax**


This last example will take the split files located in _temp_directory_name_ from
a previous **--split** and **--flatten** action, which were further processed by
the sysadmin team, and then recombine the split files into a monolithic sudoers
file and verify the syntax, and log all actions to file _sudo-ninja.log_:

**sudo-chop.sh **--tempdir** _temp_directory_name_ \
**--outputfile** _output-sudoers_file_ **--recombine --prefix** \
_east_ **--log** _sudo-ninja.log_ **--syntax**



## HISTORY

This utility is intended to help organizations with years of technical debt to
clean up monolithic sudoers file. While newer environments may deploy frameworks
such as IDM and Satellite combined with ansible to build small, custom per-
device sudoers files, legacy environments leveraging monolithic sudoers files
may need a helping hand in cleaning up rules that are no longer applicable.

One of the hurdles to automating the cleaning up legacy sudoers files, is multi-
first logical step is to "flatten" all sudoers aliases and rules into a single
line per alias or rule.

As it happens in so many IT environments, "tyranny of the moment" caused pro-
active manual maintenance of the sudoers file to be deprioritized until security
audits required that the files be cleaned up. Thankfully, this organization had
the foresight to keep their monolithic sudoer files organized into blocks of 
rules for each creation and expiration date, with an eye to manual cleanup 
at a later date. Apart from the multiline sudoers rules, their foresight to keep
the sudoers file organized into blocks with descriptive comments preceding each
block of rules, made automated cleanup of the sudoers file not only possible, 
but repeatable. 

Another hurdle is how to delete rules that no longer apply. In the particular 
use case which inspired the creation of this toolkit, it was fortunate that they
had maintained a very consistent organization of the sudoers files where the 
aliases and rules were grouped by expiration date, and then a blank line. The 
structure was like so: 

  ```

  # SNOW request INC53280 developers EXP 12-31-2025
  # developers who were brought in to refactor our Foo application.
  qawong appserver01 = /bin/su -, /usr/bin/su - \
    /opt/appserver/fooapp, /opt/dbserver/foodb, \
    /opt/appserver/fooadm, systemctl stop fooapp, systemctl start fooapp, \
    systemctl stop foodb, systemctl start foodb, /opt/appserver/fooappconfig
  qawong appserver02 = /bin/su -, /usr/bin/su - \
    /opt/appserver/fooapp, /opt/dbserver/foodb, \
    /opt/appserver/fooadm, systemctl stop fooapp, systemctl start fooapp, \
    systemctl stop foodb, systemctl start foodb, /opt/appserver/fooappconfig
  qawong dbserver01 = /bin/su -, /usr/bin/su - \
    /opt/appserver/fooapp, /opt/dbserver/foodb, \
    /opt/appserver/fooadm, systemctl stop fooapp, systemctl start fooapp, \
    systemctl stop foodb, systemctl start foodb, /opt/appserver/fooappconfig
  dchermes appserver01 = /bin/su -, /usr/bin/su - \
    /opt/appserver/fooapp, /opt/dbserver/foodb, \
    /opt/appserver/fooadm, systemctl stop fooapp, systemctl start fooapp, \
    systemctl stop foodb, systemctl start foodb, /opt/appserver/fooappconfig
  dchermes appserver02 = /bin/su -, /usr/bin/su - \
    /opt/appserver/fooapp, /opt/dbserver/foodb, \
    /opt/appserver/fooadm, systemctl stop fooapp, systemctl start fooapp, \
    systemctl stop foodb, systemctl start foodb, /opt/appserver/fooappconfig
  dchermes dbserver01 = /bin/su -, /usr/bin/su - \
    /opt/appserver/fooapp, /opt/dbserver/foodb, \
    /opt/appserver/fooadm, systemctl stop fooapp, systemctl start fooapp, \
    systemctl stop foodb, systemctl start foodb, /opt/appserver/fooappconfig
  
  # SNOW request INC64738 architects created PERM 12-31-2025
  # architects who were brought in to optimize the schema of our Foo application.
  qtleela appserver01 = /bin/su -, /usr/bin/su - \
    /opt/appserver/fooapp, /opt/dbserver/foodb, \
    /opt/appserver/fooadm, systemctl stop fooapp, systemctl start fooapp, \
    systemctl stop foodb, systemctl start foodb, /opt/appserver/fooappconfig, \
    /opt/appserver/foodbconfig
  qtleela appserver02 = /bin/su -, /usr/bin/su - \
    /opt/appserver/fooapp, /opt/dbserver/foodb, \
    /opt/appserver/fooadm, systemctl stop fooapp, systemctl start fooapp, \
    systemctl stop foodb, systemctl start foodb, /opt/appserver/fooappconfig, \
    /opt/appserver/foodbconfig
  qtleela dbserver01 = /bin/su -, /usr/bin/su - \
    /opt/appserver/fooapp, /opt/dbserver/foodb, \
    /opt/appserver/fooadm, systemctl stop fooapp, systemctl start fooapp, \
    systemctl stop foodb, systemctl start foodb, /opt/appserver/fooappconfig, \
    /opt/appserver/foodbconfig
  qhfarnsworth appserver01 = /bin/su -, /usr/bin/su - \
    /opt/appserver/fooapp, /opt/dbserver/foodb, \
    /opt/appserver/fooadm, systemctl stop fooapp, systemctl start fooapp, \
    systemctl stop foodb, systemctl start foodb, /opt/appserver/fooappconfig, \
    /opt/appserver/foodbconfig
  qhfarnsworth appserver02 = /bin/su -, /usr/bin/su - \
    /opt/appserver/fooapp, /opt/dbserver/foodb, \
    /opt/appserver/fooadm, systemctl stop fooapp, systemctl start fooapp, \
    systemctl stop foodb, systemctl start foodb, /opt/appserver/fooappconfig, \
    /opt/appserver/foodbconfig
  qhfarnsworth dbserver01 = /bin/su -, /usr/bin/su - \
    /opt/appserver/fooapp, /opt/dbserver/foodb, \
    /opt/appserver/fooadm, systemctl stop fooapp, systemctl start fooapp, \
    systemctl stop foodb, systemctl start foodb, /opt/appserver/fooappconfig, \
    /opt/appserver/foodbconfig

  # SNOW request INC38911 QA engineers PERM 1/31/2025
  # QA engineering
  dbrodriguez appserver01 = /opt/appserver/fooapp, /opt/dbserver/foodb, \
    /opt/appserver/fooadm, systemctl stop fooapp, systemctl start fooapp, \
    systemctl stop foodb, systemctl start foodb
  dbrodriguez appserver02 = /opt/appserver/fooapp, /opt/dbserver/foodb, \
    /opt/appserver/fooadm, systemctl stop fooapp, systemctl start fooapp, \
    systemctl stop foodb, systemctl start foodb
  dbrodriguez dbserver01 = /opt/appserver/fooapp, /opt/dbserver/foodb, \
    /opt/appserver/fooadm, systemctl stop fooapp, systemctl start fooapp, \
    systemctl stop foodb, systemctl start foodb
  dpfry appserver01 = /opt/appserver/fooapp, /opt/dbserver/foodb, \
    /opt/appserver/fooadm, systemctl stop fooapp, systemctl start fooapp, \
    systemctl stop foodb, systemctl start foodb
  dpfry appserver02 = /opt/appserver/fooapp, /opt/dbserver/foodb, \
    /opt/appserver/fooadm, systemctl stop fooapp, systemctl start fooapp, \
    systemctl stop foodb, systemctl start foodb
  dpfry dbserver01 = /opt/appserver/fooapp, /opt/dbserver/foodb, \
    /opt/appserver/fooadm, systemctl stop fooapp, systemctl start fooapp, \
    systemctl stop foodb, systemctl start foodb
  qjzoidberg appserver01 = /opt/appserver/fooapp, /opt/dbserver/foodb, \
    /opt/appserver/fooadm, systemctl stop fooapp, systemctl start fooapp, \
    systemctl stop foodb, systemctl start foodb
  qjzoidberg appserver02 = /opt/appserver/fooapp, /opt/dbserver/foodb, \
    /opt/appserver/fooadm, systemctl stop fooapp, systemctl start fooapp, \
    systemctl stop foodb, systemctl start foodb
  qjzoidberg dbserver01 = /opt/appserver/fooapp, /opt/dbserver/foodb, \
    /opt/appserver/fooadm, systemctl stop fooapp, systemctl start fooapp, \
    systemctl stop foodb, systemctl start foodb

  # SNOW request INC64738 manual testers EXP 12-31-2025
  # QA testers who were brought in to perform manual testing of Foo application 
  qscruffy appserver01 =  /opt/appserver/fooapp, /opt/dbserver/foodb, \
      /opt/appserver/fooadm, systemctl stop fooapp, systemctl start fooapp,
      systemctl stop foodb, systemctl start foodb
  qscruffy appserver02 = /opt/appserver/fooapp, /opt/dbserver/foodb, \
      /opt/appserver/fooadm, systemctl stop fooapp, systemctl start fooapp,
      systemctl stop foodb, systemctl start foodb
  qscruffy dbserver01 = /opt/appserver/fooapp, /opt/dbserver/foodb, \
      /opt/appserver/fooadm, systemctl stop fooapp, systemctl start fooapp,
      systemctl stop foodb, systemctl start foodb
  qkkroker appserver01 = /opt/appserver/fooapp, /opt/dbserver/foodb, \
      /opt/appserver/fooadm, systemctl stop fooapp, systemctl start fooapp,
      systemctl stop foodb, systemctl start foodb
  qkkroker appserver02 = /opt/appserver/fooapp, /opt/dbserver/foodb, \
      /opt/appserver/fooadm, systemctl stop fooapp, systemctl start fooapp,
      systemctl stop foodb, systemctl start foodb
  qkkroker dbserver01 = /opt/appserver/fooapp, /opt/dbserver/foodb, \
      /opt/appserver/fooadm, systemctl stop fooapp, systemctl start fooapp,
      systemctl stop foodb, systemctl start foodb
      
  
  ```


Processing of a multiline selection in a long file is trivial, but processing 
an arbitrary number of multiline selections in an inteterminate length file is 
overly complex for a short development cycle, so to complete this project within
the short period of time we were alotted, we elected to "flatten" all alias and
rules definitions into a single line apiece.

You'll notice that while they did maintain a consistent format consisting of 
a comment block with the first line containing an expiration tag, some notes, 
then rules, followed by a blank line, the date format was inconsistent. This was
another complication; there was no standardization of the date format. Some had
even spelled the month out, so we had to contend with that.

This utility tries to address all of those date format variations, but we strong-
ly recommend sticking with ISO 8601 date formats, i.e., YYYY-MM-DD.


# Copyright
Copyright 2025 Red Hat. Inc. 
First release: November 2025
Developed and Authored by Kimberly Lazarski (klazarsk@redhat.com)
License: GPL V3.0
