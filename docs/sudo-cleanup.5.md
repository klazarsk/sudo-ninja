.nh
.TH alert_smtp.sh 5 "July 2025" alert_smtp.sh "User Manual"

.SH NAME
alert_smtp.sh \- Sample SMTP alert agent for pacemaker with filtering


.SH SYNOPSIS
\fBpcs alert create id=\fP\fIfiltered-smtp\fP \\
 \fBpath=/var/lib/pacemaker/alert_smtp.sh\fP \fBoptions\fP \\
 \fBemail_sender=\fP\fInoreply@example.com\fP [\fBRHA_alert_kind=\fP"\fIfencing\fP,\fInode\fP,\fIresource\fP"]


.SH DESCRIPTION
\fBalert_smtp.sh\fP is a sample alert agent which implements filtering by
 matching the value of pacemaker's CRM_alert_kind variable that is set when an
 alert is generated. This agent was built for a client who wished to send
 receive alerts whenever resources are relocated,.

.PP
By default, the email client the script expects is sendmail.


.SH OPTIONS
\fBpath=\fP\fI/var/lib/pacemaker/alert_smtp.sh\fP

.PP
This is the path to the alert agent on the nodes' filesystems - the path should
 match to wherever you've installed the file. By default they're placed in
 /usr/share/pacemaker/alerts/ when installing from rpm, and they're usually
 manually placed in /var/lib/pacemaker/ for runtime when the agents are
 configured.

.PP
\fBemail_sender=\fP\fIuser@example.com\fP

.PP
This is what the agent will use as the "FROM" field on email alerts

.PP
\fBRHA_alert_kind=\fP\fI"fencing,node,resource"\fP

.PP
This option sets the RHA_alert_kind variable in the alert_smtp.sh alert
 agent, to specify the criteria on which alerts to allow to send to the email
 recipient.

.PP
Note that otherwise-unspecified alert types will be sent to the recipient
 regardless of the filter specification.

.PP
\fBfencing\fP

.PP
These alerts are generated when a node is fenced, whether automatically or
 automatically.

.PP
\fBnode\fP

.PP
These alerts when a node is suspended, unsuspended, rebooted, joins the
 cluster, etc.

.PP
\fBresource\fP

.PP
These alerts are generated when a resource is started, stopped, or fails to
 start.


.SH INSTALLATION
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


.SH EXAMPLES
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


.SH HISTORY
July 2025, Originally compiled by Kimberly Lazarski (klazarsk@redhat.com)
