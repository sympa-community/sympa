$ 16 Feb 2000, Initial version by Tung Siu Fai <sftung@hongkong.com>

$quote "

$set 1	Messages used while processing the configuration file
1	"设定档发生问题\n"
3	"问题发生在 %d 行: %s"
102	"2.5"

$set 2	Messages used by Conf when verifying the files

$set 3	Misc. messages in the main program
1	"不能存取目录 %s : %m"

$set 4	Messages used in the main loop
11	"你给 %s 的邮件经已被拒绝"
12	"你的邮件不能寄出，因为它的体积超过限制。\n"
15	"你尝试寄出邮件到私人邮寄清单，但你不是订户，所以系统不能接受。\n\
你的邮件 :\n"
17	"指令的结果"
18	"发现指令 'quit'  : 忽略接著的讯息。\n"
19	"发现不理解的指令 : 忽略接著的讯息。\n"
24	"EXPIRE 指令完成 %s"
26	"订户有 :\n"
27	"假如你希望在邮寄清单内除去这些订户，请用下列的指令 :\n"
28	"在邮寄清单 %s 订户之中，自从 %d ， %d 没有确认\n"
37	"忽略邮件内容不是纯文字 (text/plain)，请用纯文字 (text/plain) \n(或 指令放在 subject 上)。\n"
38	"你寄到 %s 的邮件已经转交到编辑(editor)上\n"

$set 5	Messages used in the tools module
1	"Safefork cannot create a new process : %m"
2	"Routing error ?"
3	"The following message was sent to a list while it seems to contain\n\
commands like subscribe, unsubscribe, help, index, get, ...\n\n\
If your message effectively contained a command, please notice that \n\
commands should never ever be sent to lists. Commands must be sent\n\
to %s exclusively.\n\n\
If your message was effectively destinated to the list, it has been\n\
interpreted by the software as a command. Please contact the manager\n\
of the service : %s so that they can take care of your message.\n\n\
Thank you for your attention.\n\n\
------ Beginning of suspected message ------\n"
4	"------ End of suspected message ------\n"

$set 6	Messages du module Commands.pm
2	"不能阅读帮助档案 : %s\n"
5	"邮寄清单 '%s' 不存在。\n"
6	"邮寄清单 %s 注意事项 :\n\n"
7	"邮寄清单纪录没有任何档案\n"
8	"必要的档案不存在。\n"
9	"私人邮寄清单 : 你不能阅读它的纪录。\n"
10	"私人邮寄清单 : 你不能浏览存在的档案。\n"
11	"私人邮寄清单 : 你不能阅读订户资料。\n"
12	"订户 : %d\n"
13	"指令语法错误。\n"
15	"核准程序失败\n\n"
16	"你确认的电邮与申请的不相同，请用你的主电邮地址"
18	"你在邮寄清单 %s 中经已除去"
21	"更新你的订阅在 '%s'"
24	"这邮寄清单暂停申请加人。\n"
25	"你的申请/退出要求已经通知了邮寄清单拥有者\n\
当程序完成，你将会收到通知。\n"
26	"邮寄清单 %s 没有取消订阅功能。\n"
27	"关于你的订阅已经更新。\n"
28	"你已经是 %s 的订户。\n"
29	"有关本邮寄清单的资料将会另外的寄给你。\n"
30	"你的电邮地址不在邮寄清单内，或许你用另外的电邮地址申请。\n"
31	"你已在邮寄清单 %s 中除去，感谢你使用本系统。\n"
32	"只有邮寄清单 %s 的拥有者才能增加或除去订户\n\
你不能使用这指令，或你没有证明你的身份。\n"
33	"电邮地址 %s 不在邮寄清单内。\n"
34	"因邮寄清单拥有者的要求，你已在邮寄清单 %s 中除去。\n\
这动作通常是系统不能寄电邮到你的电邮地址，\n\
如果你的电邮地址是没有问题，请原谅我们和重新申请加人。\n"
35	"档案纪录将会另外的寄给你。\n"
36	"有关用户 %s 已经更新 (邮寄清单 %s)。\n"
37	"%s 已经 %s 的订户。\n"
38	"指定的订户已经从邮寄清单中除去。\n"
39	"有人要求邮寄清单 %s 中的订户增加或除去\n\
如果你执行这动作，请寄电邮到 %s 并且包含 \n\n\
   %s\n\n\
如果你不想执行这动作，请忽略本邮件。\n"
40	"关于邮寄清单 %s 的设定已经更新。\n"
41	"不能存取受管制电邮(在邮寄清单 %s) 利用键 %s。\n\
这电邮可能已经送给邮寄清单主持人\n.\n"
43	"邮寄清单 %s 的邮寄已经删除。\n"
44	"邮寄清单 %s 的邮寄已经分发。\n"
45	"邮寄清单 %s 不支援 摘要(DIGEST) 模式。你对于这指令的设定没有更新。\n"
46	"MODINDEX 指令只供主持人(moderator)使用。\n\
你不是 %s 的主持人.\n"
47	"EXPIRE, EXPIREINDEX 和 EXPIREDEL 指令只供邮寄清单拥有人使用。\n\
你不是 %s 的拥有人.\n"
48	"\
有人要求批准申请 '%s' 超过 %d 日的订户。\n\
如果你不想执行这动作，请忽略本邮件。\n\
如果你执行这动作，请寄电邮到 %s 并且包含 \n\n\
\n\
AUTH %s EXPIRE %s %d %d\n"
49	"\
EXPIRE 指令正在执行中 (%s)。\n\
由拥有人 %s (%s) 执行\n\
系统不能同时执行多于一个 'expire'。\n\
现在执行中的目标是订户多于 %d 日进行没有确认程序。\n\
指令将在 %d 日结束 (%s)。\n"
52	"%s 没有收到从下列电邮地址的确认 :\n"
53	"停止期满(expiration)程序请使用 : EXPIREDEL %s\n"
54	"邮寄清单 %s 目前没有执行期满(expiration)程序。\n"
55	"你刚刚停止邮寄清单 %s 的期满(expiration)程序。\n"
56	"\
%s 期满(expiration)程序开始。并且将在 %d 天完成。\n\
你将收到没有在指定时间内确认的电邮地址。\n\
你能 DEL 指令去掉这些电邮地址。\n"
57	"查阅没有确认的电邮地址 : EXPIREINDEX %s\n"
58	"你能下列指令去掉订户 :\n"
60	"\
EXPIRE 指令不能执行。\n\
必须遵循下列说明 : \n\
 - EXPIRE 指令位于第一行\n\
 - 包含至少20字\n\
 - 最后 QUIT 指令。\n"
61	"因此你的电邮寄回给你 :\n"
67	"以下是你订阅了的邮寄清单 :\n\n"
68	"不能用 %s 键存取电邮。\n"
69	"%s 邮件你的满期(expiration)电邮到下列电邮地址 :\n"
70	"\nPowered by Sympa %s : http://listes.cru.fr/sympa/\n"
71	"由邮寄清单 %s 　开"
72	"\n\n你是下列邮寄清单的拥有者 :\n\n"
73	"\n\n你是下列邮寄清单的编辑 :\n\n"
74	"核准需要 %s 指令 %s\n"
75	"核准取消订阅 %s \n"
76	"提醒你的 %s 订阅"
77	"你是 %s 邮寄清单的会员而电邮是 %s\n"
78	"订阅提醒派到 %d %s 每一订户\n"
79	"有人要求 Sympa 送出 subscribtion\n\
到邮寄清单中 %s 每一订户 \n\n\
如果你不想执行这动作，请忽略本邮件。\n\
如果你执行这动作，请寄电邮到 %s 并且包含 \n\n\
   %s\n\n"
80	"你不能执行 %s 指令 (邮寄清单: %s)\n"
81	"用户指引"
82	"公众邮寄清单"
83	"邮寄清单被订阅摘要"
84	"用户 '%s' 经已 '%s' 的订户\n"
85	"用户 %s 经已被邀请加入邮寄清单 %s.\n"
86	"用户 %s 在邮寄清单 %s 中是不受欢迎.\n"
260	"有人要求增加你的电邮地址到邮寄清单 '%s'。\n\
如果你执行这动作，请遵循下列动作 :\n\
\n\
- 回覆这邮件 \n或\n\
- 寄邮件到 %s 包含主题\n %s\n或\n\
- 寄邮件到 %s\n\
\n\
如果你不想执行这动作，请忽略本邮件。"
261	"有人要求由 %s 邮寄清单中删除你的电邮地址。\n\
如果你执行这动作，请遵循下列动作 :\n\
\n\
- 回覆这邮件 \n或\n\
- 寄邮件到 %s 包含主题\n %s\n或\n\
- 寄邮件到 %s\n\
\n\
经由 URL %s 完成\n\
如果你不想执行这动作，请忽略本邮件。"

$set 7	Commands syslog messages (Commands.pm)

$set 8	Messages used in List.pm
1	"邮寄清单的拥有者 %s"
2	"邮寄清单 %s 订阅要求 "
3	"亲爱的邮寄清单 %s 拥有者,\n\n\
有人要求加人你的邮寄清单。如果你接受\n\
请使用下列的指令:\n\n\
mailto:%s?subject=auth%%20%s%%20ADD%%20%s%%20%s%%20%s\n"
4	"邮寄清单 %s 的主持人"
5	"文章 %s 将通过"
6	"欢迎加入 %s 邮寄清单"
7	"档案"
8	"\
   收到的邮寄 :  %9d\n\
   转寄的邮寄 :  %9d\n\n\
   送出 (MB)  : %9.2f\n\
   转寄 (MB)  : %9.2f\n"
9	"邮寄清单 %s 的摘要(digest)"
10	"如转寄附上的邮寄到邮寄清单 %s : \n\
mailto:%s?subject=DISTRIBUTE%%20%s%%20%s\n\n"
11	"如拒绝(它将会删除) :\n\
mailto:%s?subject=REJECT%%20%s%%20%s\n"
13	"目录" 
14	"邮寄清单 %s 的结束"
15	"%d 电邮受限制 (邮寄清单 %s)" 
16	"需要核准"
21	"FYI: %s 邮寄清单 %s 由 %s %s"
22	"FYI: 指令 %s 邮寄清单 %s 由 %s %s \n (不需要做任何动作)\n"
23	"警告 : %s %s 退出失败 (邮寄清单: %s) 因为他的电邮地址\n\
不在邮寄清单内\n (你可能协助这人)\n"
24	"取消订阅要求(邮寄清单 %s) "
25	"亲爱的邮寄清单 %s 拥有者,\n\n\
有人要求加人你的邮寄清单。如果你接受\n\
请使用下列的指令:\n\n\
DEL %s %s\n"
26	"指令 %s 邮寄清单 %s 由 %s %s  由 %s 确认\n (不需要做任何动作)\n"
27	"Bounce rate in list %s is %d%%.\n\n\
You should delete bouncing subscribers : \n\
%s/reviewbouncing/%s"
28	"WARNING: bounce rate too high in list %s"

$set 9	Messages for the review header
1	"拥有者 Owner                   : %s\n"
2	"主持人 Moderator               : %s\n"
3	"订阅 Subscription              : %s\n"
4	"取消订阅 Un-subscription       : %s\n"
5	"正在传送电邮 Sending messages  : %s\n"
6	"订阅者清单 Subscribers' list   : %s\n"
7	"回答到 Answer to               : %s\n"
8	"最大容量 Maximum size          : %d\n"
9	"邮寄清单 URL for the list      : %s\n"
10	"摘要 Digest                    : %s\n"
11	"自选主题 Custom subject        : %s\n"
12	"主题 Subject                   : %s\n"

$set 11	Messages used by the smtp module.
1	"Your system does not conform to the POSIX P1003.1 standard, or\n\
your Perl system does not define the _SC_ARG_MAX constant in its POSIX\n\
library. You must modify the smtp.pm module in order to set a value\n\
for variable $max_arg.\n"
2	"Unable to create a channel in smtpto: %m"

$set 12 MIME headers
1	"1.0"
2	"cn-gb"
3	"8bit"
4	"SYMPA <%s>"

$set 13	Messages for the header of moderation index
1	"\t     Date                 : %s"
2	"\t     Sender               : %s"
3	"\t     Size                 : %s\n"
4	"\t     Moderation key       : %s\n"
