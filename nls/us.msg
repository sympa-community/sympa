$ 15 Nov 2000, Correct line 21
$ 16 Oct 2000, Add web translations <os@cru.fr>
$ 14 Apr 2000, Changes in moderation
$ Jan 1999, Initial version by Stephane Alnet

$quote "

$set 1	Messages used while processing the configuration file
1	"The configuration file contains errors.\n"
3	"Error at line %d : %s"
102	"2.8.1"

$set 2	Messages used by Conf when verifying the files

$set 3	Misc. messages in the main program
1	"Unable to access directory %s : %m"

$set 4	Messages used in the main loop
11	"Your message to %s has been rejected"
12	"Your message could not be sent because its size \n\
was over the maximum size allowed on this list.\n"
15	"Your message for list %s has been rejected.\n\
The message is thus sent back to you.\n\n\
Your message :\n"
17	"Results of your commands"
18	"Command 'quit' found : ignoring end of message.\n"
19	"Command not understood: ignoring end of message.\n"
24	"End of your EXPIRE command on list %s"
26	"These subscribers are :\n"
27	"If you want to remove these subscriber from the list, use the following commands :\n"
28	"Among subscriber of list %s since %d days, %d didn't confirm there subscription.\n"
37	"Ignoring message body not in text/plain, please use text/plain only \n(or put your command in the subject).\n"
38	"Your message for list %s has been forwarded to editor(s)\n"
39	"No command found in message"
40	"Moderating your message"

$set 5	Messages used in the tools module
1	"Safefork cannot create a new process : %m"
2	"Routing error ?"
3	"The following message was sent to a list while it seems to contain\n\
commands like subscribe, unsubscribe, help, index, get, ...\n\n\
If your message effectively contained a command, please notice that \n\
commands should never ever be sent to lists. Commands must be sent\n\
to %s exclusively.\n\n\
If your message was effectively addressed to the list, it has been\n\
interpreted by the software as a command. Please contact the manager\n\
of the service : %s so that they can take care of your message.\n\n\
Thank you for your attention.\n\n\
------ Beginning of suspected message ------\n"
4	"------ End of suspected message ------\n"

$set 6	Messages du module Commands.pm
2	"Unable to read help file : %s\n"
5	"List '%s' does not exist.\n"
6	"Information regarding list %s :\n\n"
7	"This list's archives do not contain any file.\n"
8	"Required file does not exist.\n"
9	"List is Private : You can not read the archives.\n"
10	"List is Private : You can not browse available files.\n"
11	"List is Private : You can not browse subscribers' list.\n"
12	"Subscribers : %d\n"
13	"Command syntax error.\n"
15	"The authentication process failed\n\n"
16	"You probably confirmed your subscription using a different\n\
email address. Please try subscribing using your canonical address."
18	"Your subscription to list %s has been removed."
21	"Renewal of your subscription to list '%s'"
24	"Subscription to this list are currently suspended.\n"
25	"Your request of subscription/unssubscribtion has been forwarded to the list's\n\
owners for approval. You will receive a notification when you will have\n\
been subscribed (or unsubscribed) to the list.\n"
26	"Unsubscription is not available for list %s.\n"
27	"Information regarding your subscription have been updated.\n"
28	"You are now a subscriber of list %s.\n"
29	"Information regarding this list will be sent in a separate message.\n"
30	"Your e-mail address has not been found in the list %s. Maybe\n\
you subscribed from a different e-mail address ?\n"
31	"You have been removed from list %s.\n\
Thank you for using this list.\n"
32	"Only owners of list %s may add or remove subscribers.\n\
You are not allowed to use this command, or you didn't provide the items\n\
requested for your identification.\n"
33	"E-mail address %s was not found in the list.\n"
34	"Your have been removed from the list\n\
by %s, owner of this list.\n\n\
This action is generally performed to delete addresses generating\n\
non-delivery reports. Your address may however work correctly.\n\
If so, please excuse us for this trouble and renew your subsciption.\n"
35	"The archive will be sent to you in a separate message.\n"
36	"Information regarding user %s have been updated for list %s.\n"
37	"User %s is now subscriber of list %s.\n"
38	"The user %s has been removed from the list %s/\n"
39	"Someone (hopefully you) requested a user of list %s to be\n\
added or removed.\n\n\
If you want this action to be taken, please send an e-mail to\n\
%s containing \n\n\
   %s\n\n\
If you do not want this action to be taken, simply ignore this message.\n"
40	"Your configuration regarding list %s has been updated.\n"
41	"Unable to access the moderated message on list %s with key %s.\n\
This message may already have been sent by one of the list's moderators\n.\n"
43	"Message %s for list %s has been rejected.\n"
44	"Message %s for list %s has been distributed.\n"
45	"List %s does not accept the DIGEST mode. Your configuration regarding this command has not been updated.\n"
46	"The MODINDEX command is restricted to moderators.\n\
You are not one of the moderators for list %s.\n"
47	"The EXPIRE, EXPIREINDEX and EXPIREDEL commands are restricted to the owners of the list.\n\
You are not one of the owners for list %s.\n"
48	"\
Someone (hopefully you) resquested that the subscribers to the list\n\
'%s' for more than %d days have to confirm their subscription.\n\
If you do not want this action to be taken, simply ignore this message.\n\
To confirm this action, please send an e-mail to '%s', with the following command:\n\
\n\
AUTH %s EXPIRE %s %d %d\n"
49	"\
An EXPIRE command is currently running for list %s.\n\
It had been run by owner %s (%s)\n\
There cannot be more than one 'expire' process at a time for a given list.\n\
The currently running expiration is for people subscribing for more\n\
than %d days and who didn't confirm their subscription. The expiration\n\
will end in %d day(s) (%s).\n"
52	"%s did not receive confirmation for the following addresses :\n"
53	"To stop the expiration process : EXPIREDEL %s\n"
54	"List %s is not currently running an expiration process.\n"
55	"You just stopped the expiration process for list %s\n"
56	"\
An expiration process for list %s has been started. This process\n\
will end in %d days. You will then receive the list of subscribers \n\
who didn't confirm their subscription in time.\n\
You will then be able to remove these addresses yourself with the DEL command.\n"
57	"To read the list of subscribers who haven't confirm their\n\
subscription : EXPIREINDEX %s\n"
58	"You can remove these subscriber from the list by using the following commands :\n"
60	"\
The EXPIRE command couldn't be run. It must followed by an explication\n\
text aimed to subscribers who need to confirm their subscription.\n\
This text must\n\n\
 - start on the very first line following the EXPIRE command,\n\
 - contain at least 20 words,\n\
 - and end with the QUIT word.\n"
61	"Thus, your message is sent back to you :\n"
67	"Here are the lists you are currently subscribe to :\n\n"
68	"Unable to access to the message authenticated with key %s.\n"
69	"%s posted your expiration message to the following addresses :\n"
70	"\nPowered by Sympa %s : http://listes.cru.fr/sympa/\n"
71	"Unsubscribe from list %s"
72	"\n\nLists you are owner of:\n\n"
73	"\n\nLists you are editor of :\n\n"
74	"Authentication requested to %s for command %s\n"
75	"Enable to unsubscribe %s from any list \n"
76	"Reminder of your %s subscription"
77	"You are member of list %s with email %s\n"
78	"Subscription reminder sent to each of %d %s subscribers\n"
79	"You requested a subscription reminder to be sent\n\
to each subscriber of list %s\n\n\
If you want this action to be taken, please send an e-mail to\n\
%s containing \n\n\
   %s\n\n\
If you do not want this action to be taken, simply ignore this message.\n"
80	"You are not allowed to perform command %s in list %s\n"
81	"User guide"
82	"Public lists"
83	"Subscription summary"
84	"The User '%s' is already subscriber of list '%s'\n"
85	"User %s has been invited to subscribe in list %s.\n"
86	"User %s is unwanted in list %s.\n"
90	"List %s allows only these reception modes : %s\n\
Your configuration hasn't been modified.\n"
260	"Someone (hopefully you) asked for your e-mail address\n\
to be added to list '%s'.\n\
If you want this action to be taken, please\n\
\n\
- reply to this mail\nOR\n\
- send a message to %s with subject\n %s\nOR\n\
- hit the following mailto %s\n\
\n\
If you do not want this action to be taken, you can safely ignore\n\
this message."
261	"Someone (hopefully you) asked for you e-mail address\n\
to be removed from list '%s'.\n\
If you want this action to be taken, please \n\
\n\
- reply to this mail\nOR\n\
- send a message to '%s' with subject\n %s\nOR\n\
- hit the following mailto %s\n\n\
\
This can be done via the URL %s\n\
If you do not want this action to be taken, you can safely ignore\n\
this message."

$set 7	Commands syslog messages (Commands.pm)

$set 8	Messages used in List.pm
1	"Owners of list %s"
2	"Subscription request to list %s"
3	"Dear owner of list %s,\n\n\
A user asked to be added as a subscriber to your list. Shall this be fine\n\
with you, you should click the following URL :\n\n\
mailto:%s?subject=auth%%20%s%%20ADD%%20%s%%20%s%%20%s\n\n\
or send an email to %s with the following subject :\n\
AUTH %s ADD %s %s %s\n"
4	"Moderators of list %s"
5	"[%s] Article to be approved"
6	"Welcome on list %s"
7	"File"
8	"\
   Number of received messages :  %9d\n\
   Number of forwarded messages:  %9d\n\n\
   Sent mega-bytes             : %9.2f\n\
   Forwarded mega-bytes        : %9.2f\n"
9	"Digest for list %s"
10	"To distribute the attached message in list %s:\n\
mailto:%s?subject=DISTRIBUTE%%20%s%%20%s\n\
Or send a message to %s with the following subject :\n\
DISTRIBUTE %s %s\n\n"
11	"To reject it (it will be removed):\n\
mailto:%s?subject=REJECT%%20%s%%20%s\n\
Or send a message to %s with the following subject :\n\
REJECT %s %s\n"
12	"To distribute the attached message in list %s :\n\
mailto:%s?subject=CONFIRM%%20%s\n\
Or send a message to %s with the following subject :\n\
CONFIRM %s\n"
13	"Table of content" 
14	"End of digest for list %s"
15	"There are %d messages to be moderated for list %s" 
16	"Authentication requested"
21	"FYI: %s list %s from %s %s"
22	"FYI command %s list %s from %s %s \n (no action needed)\n"
23	"WARNING : %s %s failed to unsubscribe from %s because his address was\n\
not found in the list\n (You may help this person)\n"
24	"UNsubscription request from list %s"
25	"Dear owner of list %s,\n\n\
A user asked to be deleted from your list. Shall this be fine\n\
with you, you should click the following URL :\n\n\
mailto:%s?subject=auth%%20%s%%20DEL%%20%s%%20%s\n\n\
or send an email to %s with the following subject :\n\
AUTH %s DEL %s %s\n"
26	"FYI command %s list %s from %s %s validated by %s\n (no action needed)\n"
27	"Bounce rate in list %s is %d%%.\n\n\
You should delete bouncing subscribers : \n\
%s/reviewbouncing/%s"
28	"WARNING: bounce rate too high in list %s"
29	"Invitation to join list %s"
30	"You are invited to join list %s"
31	"Summary of list %s"

$set 9	Messages for the review header
1	"Owner              : %s\n"
2	"Moderator          : %s\n"
3	"Subscription       : %s\n"
4	"Un-subscription    : %s\n"
5	"Sending messages   : %s\n"
6	"Subscribers' list  : %s\n"
7	"Answer to          : %s\n"
8	"Maximum size       : %d\n"
9	"URL for the list   : %s\n"
10	"Digest             : %s\n"
11	"Custom subject     : %s\n"
12	"Subject            : %s\n"
13	"Reception mode     : %s\n"

$set 11	Messages used by the smtp module.
1	"Your system does not conform to the POSIX P1003.1 standard, or\n\
your Perl system does not define the _SC_ARG_MAX constant in its POSIX\n\
library. You must modify the smtp.pm module in order to set a value\n\
for variable $max_arg.\n"
2	"Unable to create a channel in smtpto: %m"

$set 12 MIME headers
1	"1.0"
2	"us-ascii"
3	"7bit"
4	"SYMPA <%s>"

$set 13	Messages for the header of moderation index
1	"\t     Date                 : %s"
2	"\t     Sender               : %s"
3	"\t     Size                 : %s\n"
4	"\t     Moderation key       : %s\n"

$set 14 Pour le web
1	"en_US"
2	"english"

$set 15 Templates files
1	"welcome message"
2	"unsubscription message"
3	"deletion message"
4	"message footer"
5	"message header"
6	"remind message"
7	"editor rejection message"
8	"subscribing invitation message"
9	"help file"
10	"directory of lists"
11	"global remind message"
12	"summary message"
13	"list description"
14	"list homepage"

$set 16 Listm parameters titles
1	"Account"
2	"Who can add subscribers"
3	"Anonymous sender"
4	"Text archives"
5	"frequency"
6	"access right"
7	"Bounces management"
8	"warn rate"
9	"halt rate"
10	"Expiration of unmoderated messages"
11	"Secret string for generating unique keys"
12	"Creation of the list"
16	"Custom header field"
17	"Subject tagging"
18	"Subscription profile"
19	"reception mode"
20	"visibility"
21	"Who can delete subscribers"
22	"Digest frequency"
23	"days"
24	"hour"
25	"minute"
26	"Moderators"
27	"email address"
28	"reception mode"
29	"name"
30	"private information"
31	"Attachment type"
32	"Forced reply address"
33	"Internet domain"
34	"File inclusion"
35	"LDAP query inclusion"
36	"remote host"
37	"remote port"
38	"remote user"
39	"remote password"
40	"suffix"
41	"filter"
42	"extracted attribute"
43	"selection (if multiple)"
44	"List inclusion"
45	"SQL query inclusion"
46	"database type"
47	"remote host"
48	"database name"
49	"remote user"
50	"remote password"
51	"SQL query"
53	"Who can view list information"
54	"Who can invite people"
55	"Language of the list"
56	"Maximum message size"
57	"Owner"
58	"email address"
59	"reception mode"
60	"name"
61	"private informations"
62	"profile"
63	"Priority"
64	"Who can start a remind process"
65	"Remind return-path"
66	"Reply address"
67	"Who can review subscribers"
68	"Who can send messages"
69	"Serial number of the config"
70	"Shared documents"
71	"Status of the list"
72	"Subject of the list"
73	"Who can subscribe to the list"
74	"Topics for the list"
75	"Inclusions timeout"
76	"Who can unsubscribe"
77	"Last update of config"
81	"User data source"
82	"Visibility of the list"
83	"Web archives"
84	"access right"
85	"Welcome return-path"
86	"Who can view"
87	"Who can edit"
88	"Available subscription options"
89	"reception mode"

$set 17 Cookie expiration periods
1	"session"
2	"10 minutes"
3	"30 minutes"
4	"1 hour"
5	"6 hours"
6	"1 day"
7	"1 week"

