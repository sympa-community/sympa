# msg.pl - This module includes English defaults for long messages
# RCS Identication ; $Revision$ ; $Date$ 
#
# Sympa - SYsteme de Multi-Postage Automatique
# Copyright (c) 1997, 1998, 1999, 2000, 2001 Comite Reseau des Universites
# Copyright (c) 1997,1998, 1999 Institut Pasteur & Christophe Wolfhugel
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

package msg;

## Command report
my @report;

## RCS identification.
#my $id = '@(#)$Id$';

$syntax_error =
'Syntax error. Please review the documentation.
';

$reconfirm_syntax_error =
'The syntax you have given for reconfirm is wrong.
';

$subj_need_to_reconfirm =
'Renewal of your subscription to %s';

$need_to_reconfirm =
'Your subscription to the list %s will expire in %d weeks.
You need to reconfirm your subscription. To do so, please send the
following commands (exactely as shown) back to %s:

   subscrib %s %s

If you do not want to stay on this list, do not reply to this message and
you will be removed in a few weeks.
';

$subscription_confirmed =
'Your subscription to the list %s has been confirmed.
';

$subscription_not_confirmed =
'Your subscription to the list "%s" could not be confirmed.
In many cases this is because you did subscribe from a different
e-mail address than the one use for confirmation.
';

$subscription_forwarded = 
'Your subscription (or unsubscribtion) request has been forwarded to the owners of the list for
approval. You will be notified once you have been added to (or deleted from) the list
';

$subj_purge_done =
'You have been removed from list "%s"';

$purge_done =
'You have been removed from the mailing list "%s". This is
usually because you did not reconfirm your subscription to the list
on time, or simply because you wanted to leave the list.

If you want to come back to the list again you will just need to
subscribe again, using the "sub" command.
';

$remind_need_auth =
'Someone (hopefully you) ask Sympa to send a subscribtion
to each subscriber of list %s

If you want this action to be taken, please send an e-mail to
%s containing
   %s
If you do not want this action to be taken, simply ignore this message.'
;

$reconfirm_need_auth = 
'Someone (possibly you) has requested to send a reconfirm notice to
all subscribers of list "%s". If you really want this action to be
taken, please send the following commands (exactly as shown) back
to "%s":

   auth "%s" reconfirm %s %d %d

If you do not want this action to be taken, simply ignore this message
and the request will be disregarded.
';

$purge_need_auth =
'Someone (possibly you) has requested to purge the mailing list "%s".

If you really want this action to be taken, please send the following
commands (exactly as shown) back to "%s":

   auth %s purge %s %d

If you do not want this action to be taken, simply ignore this message
and the request will be disregarded.
';

$expire_need_auth =
'Someone (possibly you) has requested a purge of the "%s" mailing list
for subscribers older than %d days.

If you really want this action to be taken, please send the following
command (exactly as shown) back to "%s". 

auth %s expire %s %d %d

Otherwise, simply ignore this message and the request will be disregarded. 

WARNING :  every single line following the expire command will be sent
to concerned subscribers. Feel free to insert a "quit" command between 
the end of your message and your signature to skip it.
';

$subscription_need_auth =
'Someone (possibly you) has requested that your email address be added to
or deleted from the mailing list "%s".

If you really want this action to be taken, please send the following
command (exactly as shown) back to "%s":

   %s

If you do not want this action to be taken, simply ignore this message
and the request will be disregarded.
';

$signoff_need_auth =
'Someone (possibly you) has requested that your email address be
deleted from the mailing list "%s".

If you really want this action to be taken, please send the following
command (exactly as shown) back to "%s":

   %s

If you do not want this action to be taken, simply ignore this message
and the request will be disregarded.
';

$adddel_need_auth =
'Someone (possibly you) has requested that a user be added or deleted
from the mailing list %s.

If you really want this action to be taken, please send the following
command (exactly as shown) back to "%s":

   %s

If you do not want this action to be taken, simply ignore this message
and the request will be disregarded.
';

$wrong_authenticator =
'The authenticator you have given is wrong, are you sure you did cut and
paste the right command?
';

$non_canonical = 
'You probably confirmed your subscription using a different
email address. Please try subscribing using your canonical address.';

$sent_to_editor = 'Subject: Article to approve
';

$list_is_private =
'You message for list %s has been rejected. 
For your convenience your original message is being
sent back to you.

Your message:

';

$private_no_review = '
The list is private, you may not get the list of subscribers.
';

$private_no_index = '
This list is private, you may not get the list of available files.
';

$private_no_get = '
This list is private, you may not get files from the archive.
';

$not_owner_reconfirm =
'Only list owners may use the reconfirm command.
';

$not_owner_purge =
'Only list owners may use the purge command, and use of authentication is
required.
';

$not_owner_delete =
'Only owners of the list %s may add/remove users. You are not an authorized
user or you did not provide the adequate authentication items to be allowed to
issue this command.
';

$not_owner_expire =
'Only owners of the liste %s may use expire, expireindex and expiredel commands,
 and use of authentication is required.
';

$num_subscribers =
'Total: %d
';

$info_on_list =
'Informations for list %s:

';

$list_not_found = 
'List %s not found.
';

$user_not_found =
'The indicated user has not been found on the list.
';

$user_not_on_list =
'You are not a member of the list, so your subscription can not
be confirmed.
';

$user_removed_from_list =
'The specified user has been removed from the list.
';

## Messages used for the MD5 authentication
$md5_subscribe =
'You need to confirm your subscription to the list %s.
To confirm the subscription you must just reply to this
message within 48 hours and quote it, particularly without
altering following authentication key:

-=SympaKey=%s-=
';

## User needs to confirm a command sent with the MD5
## authentication.
$md5_auth_sent =
'MD5 message authenticator sent separately, you will need
to confirme your command.
';

## A message sent to a list is too large
$msg_too_large =
'Your message is being rejected because it is too large for this
mailing list.
';

$file_not_found =
'The requested file has not been found.
';

$no_archives_available =
'No files are available for this list.
';

$sub_owner =
'Dear owner of list %s,

A user asked to be added as a subscriber to your list. Shall this be fine
with you, you should click the following URL :

mailto:%s?subject=auth%%20%s%%20ADD%%20%s%%20%s%%20%s

or send an email to %s with the following subject :
AUTH %s ADD %s %s %s
';

$sig_owner =
'Dear owner of list %s,

A user asked to be deleted from your list. Shall this be fine
with you, you should click the following URL :

mailto:%s?subject=auth%%20%s%%20DEL%%20%s%%20%s

or send an email to %s with the following subject :
AUTH %s DEL %s %s
';


## Messages used for syslog activity

$sys_sent_to_editor = 'Message for %s from %s sent to editors';
$sys_msg_accepted = 'Message for %s from %s accepted';
$sys_list_private = 'Message for %s from %s rejected because list is private';
$sys_del_ok = 'DEL %s %s from %s accepted';
$sys_msg_too_large = 'Message for %s from %s too large (%d > %d)';

$expire_comment =
'You will receive a list of subscribers who did not
confirm their subscription to list %s in %d days time.
';

$expire_end =
'A message (at least %d words long) is needed by the EXPIRE command. 
It will be sent to subscribers who need to reconfirm their subscription.
You can tell the EXPIRE command to ignore a signature at the end of
your message by iserting a "quit", "end" or "exit" before the signature';

$expire_running =
'An EXPIRE command has been launched on list "%s" by the owner %s (%s)
Only one EXPIRE command can be launched at a time for one list.

The current EXPIRE process concerns subscribers who are subscribed since 
at least %d days and will end in %d day(s) (%s).
';

$expireindex_info =
'To check the state of the current EXPIRE process (list of unconfirmed 
subscription) : EXPIREINDEX %s
';

$expiredel_info =
'To cancel the EXPIRE process : EXPIREDEL %s
';

$separator="------- CUT --- CUT --- CUT --- CUT --- CUT --- CUT --- CUT -------";
$digest_separator = '------ next message ------';

1;
