sudo-chop.sh 5 "November 2025" sudo-chop.sh "User Manual"
==================================================

# NAME
sudo-chop.sh \- Sudo ninja sudoers preprocessor and expired rules deletion


# SYNOPSIS

**sudo-chop.sh --input** _nosudoers-east-paredmore_ **--tempdir** _rules-east-paredmore_ **--flatten --split --outputfile** _recombined-east-paredmore_ **--expire --recombine --prefix** _myway_ **--log** _mylog.log_

# DESCRIPTION
**sudo-chop** is part of the sudo-ninja suite; this utility takes a monolithic sudoers file, flattens all of the multi-line rules into a single line apiece, splits the file into chunks with each file consisting of comment block followed by a block of rules, and optionally removes expired rules before recombining the split files back into a single monolithic sudoers file, with the final step being to check syntax.


# OPTIONS

**-h | --help**
  Display help (this screen)

**-C | --check**
  Validate output file with visudo.

**-D | --debug**
  Debug mode which turns on sleeps, pause breaks waiting for keypress
  to continue, allowing for review and analysis of intermediate files

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
  extra words and stuff (Word vomit!)

**-vvv | --plaid**
  tl;dr (read this output you'll get a headache)
  Lots and lots of debug output. Too muh. dahling, gobble gobble gobble,

**-v | --version**
  Display the version number



# INSTALLATION
Place alert_syslog.sh in pacemaker lib dirctory (typically /var/lib/pacemaker)
 chown it the pacemaker user and group (typically hacluster:haclient on a
 default install); chmod it 0750

.PP
~]# \fBcp /usr/share/pacemaker/alerts/alert_smtp.sh.sample \\
  /var/lib/pacemaker/alert_smtp.sh\fP
 ~]# chown hacluster:haclient /var/lib/pacemaker/alert_smtp.sh
 ~]# chmod 0750 /var/lib/pacemaker/alert_smtp.sh

.PP
Proceed to EXAMPLES section for alert configuration


# EXAMPLES
The following example will send alert emails whenever a node is fenced and
.br
 unhandled alerts, but not node or resource alerts. The agent will send the
 alert emails to sysad@example.com

.PP
~]# \fBpcs alert create id=\fP\fIfiltered-smtp\fP \\
 \fBpath=/var/lib/pacemaker/alert_smtp.sh options\fP \\
 \fBemail_sender=\fP\fInoreply@example.com\fP \fBRHA_alert_kind=\fP\fI"fencing"\fP
 ~]# \fBpcs alert recipient add\fP \fIfiltered-smtp\fP \\
 \fBvalue=\fP\fIsysad@example.com@example.com\fP
 ~]#

.PP
This example will send alerts of kind node, resource, and "unhandled"
 alerts, but not fencing notifications, and the alert emails will go to
 monitor@example.com:

.PP
~]# \fBpcs alert create id=\fP\fIfiltered-smtp\fP \\
 \fBpath=/var/lib/pacemaker/alert_smtp.sh options\fP \\
 \fBemail_sender=\fP\fInoreply@example.com\fP \fBRHA_alert_kind=\fP\fI"node,resource"\fP
 ~]# **pcs alert recipient add **\fIfiltered-smtp\fP \\
\fBvalue=\fP_monitor@example.com
.br
 ~]#


# HISTORY
November 2025, Authored by Kimberly Lazarski (klazarsk@redhat.com)
