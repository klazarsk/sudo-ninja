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
  tl;dr summary:
    Lots and lots of debug output.

**-v | --version**
  Display the version number


## INSTALLATION


## EXAMPLES

**sudo-chop.sh --input** _monolithic-sudoers-file_ **--tempdir** _rules-east-paredmore_ \
 **--flatten --split --outputfile** _nosudoers-output-file_ **--expire --recombine \
 --prefix** _myway_ **--log** _/path/to/your/log-file-location.log_



## HISTORY

This utility is intended to help organizations with years of technical debt to
clean up monolithic sudoers file. While newer environments may deploy frameworks
such as IDM and Satellite combined with ansible to build small, custom per-
device sudoers files, legacy environments leveraging monolithic sudoers files
may need a helping hand in cleaning up rules that are no longer applicable.

One of the hurdles to automating the cleaning up legacy sudoers files, is multi-
first logical step is to "flatten" all sudoers aliases and rules into a single
line per alias or rule.

Another hurdle is how to delete rules that no longer apply. In the particular 
use case which inspired the creation of this toolkit, it was fortunate that they
had maintained a very consistent organization of the sudoers files where the 
aliases and rules were grouped by expiration date, and then a blank line. The 
structure was like so: 

  ```
  # SNOW request INC64738 architects EXP 12-31-2025
  # architects who were brought in to optimize indices in our Foo application.
  qtleela appserver01 = /bin/su -, /usr/bin/su - 
  qtleela appserver02 = /bin/su -, /usr/bin/su - 
  qtleela dbserver01 = /bin/su -, /usr/bin/su - 
  qhfarnsworth appserver01 = /bin/su -, /usr/bin/su - 
  qhfarnsworth appserver02 = /bin/su -, /usr/bin/su - 
  qhfarnsworth dbserver01 = /bin/su -, /usr/bin/su - 

  # SNOW request INC53280 developers EXP 12-31-2025
  # developers who were brought in to refactor our Foo application.
  qawong appserver01 = /bin/su -, /usr/bin/su - 
  qawong appserver02 = /bin/su -, /usr/bin/su - 
  qawong dbserver01 = /bin/su -, /usr/bin/su - 
  dchermes appserver01 = /bin/su -, /usr/bin/su - 
  dchermes appserver02 = /bin/su -, /usr/bin/su - 
  dchermes dbserver01 = /bin/su -, /usr/bin/su - 
  
  # SNOW request INC38911 QA testers EXP 1/31/2025
  # QA testers who were brought in to test Foo application 
  dbrodriguez appserver01 = /bin/su -, /usr/bin/su - 
  dbrodriguez appserver02 = /bin/su -, /usr/bin/su - 
  dbrodriguez dbserver01 = /bin/su -, /usr/bin/su - 
  dpfry appserver01 = /bin/su -, /usr/bin/su - 
  dpfry appserver02 = /bin/su -, /usr/bin/su - 
  dpfry dbserver01 = /bin/su -, /usr/bin/su - 
  qjzoidberg appserver01 = /bin/su -, /usr/bin/su - 
  qjzoidberg appserver02 = /bin/su -, /usr/bin/su - 
  qjzoidberg dbserver01 = /bin/su -, /usr/bin/su - 

  # SNOW request INC64738 architects EXP 12-31-2025
  # QA testers who were brought in to automate testing of Foo application 
  qtleela appserver01 = /bin/su -, /usr/bin/su - 
  qtleela appserver02 = /bin/su -, /usr/bin/su - 
  qtleela dbserver01 = /bin/su -, /usr/bin/su - 
  qhfarnsworth appserver01 = /bin/su -, /usr/bin/su - 
  qhfarnsworth appserver02 = /bin/su -, /usr/bin/su - 
  qhfarnsworth dbserver01 = /bin/su -, /usr/bin/su - 
  ```

You'll notice that while they did maintain a consistent format consisting of 
a comment block with the first line containing an expiration tag, some notes, 
then rules, followed by a blank line, the date format was inconsistent. This was
another complication; there was no standardization of the date format. Some had
even spelled the month out, so we had to contend with that. 

This utility tries to address all of those conditions, but we strongly recommend
sticking with ISO 8601 date formats, that is to say, YYYY-MM-DD.
  
  
November 2025, Authored by Kimberly Lazarski (klazarsk@redhat.com)
