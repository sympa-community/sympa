$ 16 Feb 2000, Initial version by Tung Siu Fai <sftung@hongkong.com>

$quote "

$set 1	Messages used while processing the configuration file
1	"設定檔發生問題\n"
3	"問題發生在 %d 行: %s"
102	"2.5"

$set 2	Messages used by Conf when verifying the files

$set 3	Misc. messages in the main program
1	"不能存取目錄 %s : %m"

$set 4	Messages used in the main loop
11	"你給 %s 的郵件經已被拒絕"
12	"你的郵件不能寄出，因為它的体積超過限制。\n"
15	"你嘗試寄出郵件到私人郵寄清單，但你不是訂戶，所以系統不能接受。\n\
你的郵件 :\n"
17	"指令的結果"
18	"發現指令 'quit'  : 忽略接著的訊息。\n"
19	"發現不理解的指令 : 忽略接著的訊息。\n"
24	"EXPIRE 指令完成 %s"
26	"訂戶有 :\n"
27	"假如你希望在郵寄清單內除去這些訂戶，請用下列的指令 :\n"
28	"在郵寄清單 %s 訂戶之中，自從 %d ， %d 沒有确認\n"
37	"忽略郵件內容不是純文字 (text/plain)，請用純文字 (text/plain) \n(或 指令放在 subject 上)。\n"
38	"你寄到 %s 的郵件已經轉交到編輯(editor)上\n"

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
2	"不能閱\讀幫助檔案 : %s\n"
5	"郵寄清單 '%s' 不存在。\n"
6	"郵寄清單 %s 注意事項 :\n\n"
7	"郵寄清單紀錄沒有任何檔案\n"
8	"必要的檔案不存在。\n"
9	"私人郵寄清單 : 你不能閱\讀它的紀錄。\n"
10	"私人郵寄清單 : 你不能瀏覽存在的檔案。\n"
11	"私人郵寄清單 : 你不能閱\讀訂戶資料。\n"
12	"訂戶 : %d\n"
13	"指令語法錯誤。\n"
15	"核准程序失敗\n\n"
16	"你确認的電郵与申請的不相同，請用你的主電郵地址"
18	"你在郵寄清單 %s 中經已除去"
21	"更新你的訂閱\在 '%s'"
24	"這郵寄清單暫停申請加人。\n"
25	"你的申請/退出要求已經通知了郵寄清單擁有者\n\
當程序完成，你將會收到通知。\n"
26	"郵寄清單 %s 沒有取消訂閱\功\能。\n"
27	"關于你的訂閱\已經更新。\n"
28	"你已經是 %s 的訂戶。\n"
29	"有關本郵寄清單的資料將會另外的寄給你。\n"
30	"你的電郵地址不在郵寄清單內，或許\你用另外的電郵地址申請。\n"
31	"你已在郵寄清單 %s 中除去，感謝你使用本系統。\n"
32	"只有郵寄清單 %s 的擁有者才能增加或除去訂戶\n\
你不能使用這指令，或你沒有証明你的身份。\n"
33	"電郵地址 %s 不在郵寄清單內。\n"
34	"因郵寄清單擁有者的要求，你已在郵寄清單 %s 中除去。\n\
這動作通常是系統不能寄電郵到你的電郵地址，\n\
如果你的電郵地址是沒有問題，請原諒我們和重新申請加人。\n"
35	"檔案紀錄將會另外的寄給你。\n"
36	"有關用戶 %s 已經更新 (郵寄清單 %s)。\n"
37	"%s 已經 %s 的訂戶。\n"
38	"指定的訂戶已經從郵寄清單中除去。\n"
39	"有人要求郵寄清單 %s 中的訂戶增加或除去\n\
如果你執行這動作，請寄電郵到 %s 并且包含 \n\n\
   %s\n\n\
如果你不想執行這動作，請忽略本郵件。\n"
40	"關于郵寄清單 %s 的設定已經更新。\n"
41	"不能存取受管制電郵(在郵寄清單 %s) 利用鍵 %s。\n\
這電郵可能已經送給郵寄清單主持人\n.\n"
43	"郵寄清單 %s 的郵寄已經刪除。\n"
44	"郵寄清單 %s 的郵寄已經分發。\n"
45	"郵寄清單 %s 不支援 摘要(DIGEST) 模式。你對于這指令的設定沒有更新。\n"
46	"MODINDEX 指令只供主持人(moderator)使用。\n\
你不是 %s 的主持人.\n"
47	"EXPIRE, EXPIREINDEX 和 EXPIREDEL 指令只供郵寄清單擁有人使用。\n\
你不是 %s 的擁有人.\n"
48	"\
有人要求批准申請 '%s' 超過 %d 日的訂戶。\n\
如果你不想執行這動作，請忽略本郵件。\n\
如果你執行這動作，請寄電郵到 %s 并且包含 \n\n\
\n\
AUTH %s EXPIRE %s %d %d\n"
49	"\
EXPIRE 指令正在執行中 (%s)。\n\
由擁有人 %s (%s) 執行\n\
系統不能同時執行多于一個 'expire'。\n\
現在執行中的目標是訂戶多于 %d 日進行沒有确認程序。\n\
指令將在 %d 日結束 (%s)。\n"
52	"%s 沒有收到從下列電郵地址的确認 :\n"
53	"停止期滿(expiration)程序請使用 : EXPIREDEL %s\n"
54	"郵寄清單 %s 目前沒有執行期滿(expiration)程序。\n"
55	"你剛剛停止郵寄清單 %s 的期滿(expiration)程序。\n"
56	"\
%s 期滿(expiration)程序開始。并且將在 %d 天完成。\n\
你將收到沒有在指定時間內确認的電郵地址。\n\
你能 DEL 指令去掉這些電郵地址。\n"
57	"查閱\沒有确認的電郵地址 : EXPIREINDEX %s\n"
58	"你能下列指令去掉訂戶 :\n"
60	"\
EXPIRE 指令不能執行。\n\
必須遵循下列說明 : \n\
 - EXPIRE 指令位于第一行\n\
 - 包含至少20字\n\
 - 最后 QUIT 指令。\n"
61	"因此你的電郵寄回給你 :\n"
67	"以下是你訂閱\了的郵寄清單 :\n\n"
68	"不能用 %s 鍵存取電郵。\n"
69	"%s 郵件你的滿期(expiration)電郵到下列電郵地址 :\n"
70	"\nPowered by Sympa %s : http://listes.cru.fr/sympa/\n"
71	"由郵寄清單 %s 离開"
72	"\n\n你是下列郵寄清單的擁有者 :\n\n"
73	"\n\n你是下列郵寄清單的編輯 :\n\n"
74	"核准需要 %s 指令 %s\n"
75	"核准取消訂閱\ %s \n"
76	"提醒你的 %s 訂閱\"
77	"你是 %s 郵寄清單的會員而電郵是 %s\n"
78	"訂閱\提醒派到 %d %s 每一訂戶\n"
79	"有人要求 Sympa 送出 subscribtion\n\
到郵寄清單中 %s 每一訂戶 \n\n\
如果你不想執行這動作，請忽略本郵件。\n\
如果你執行這動作，請寄電郵到 %s 并且包含 \n\n\
   %s\n\n"
80	"你不能執行 %s 指令 (郵寄清單: %s)\n"
81	"用戶指引"
82	"公眾郵寄清單"
83	"郵寄清單被訂閱\摘要"
84	"用戶 '%s' 經已 '%s' 的訂戶\n"
85	"用戶 %s 經已被邀請加入郵寄清單 %s.\n"
86	"用戶 %s 在郵寄清單 %s 中是不受歡迎.\n"
260	"有人要求增加你的電郵地址到郵寄清單 '%s'。\n\
如果你執行這動作，請遵循下列動作 :\n\
\n\
- 回覆這郵件 \n或\n\
- 寄郵件到 %s 包含主題\n %s\n或\n\
- 寄郵件到 %s\n\
\n\
如果你不想執行這動作，請忽略本郵件。"
261	"有人要求由 %s 郵寄清單中刪除你的電郵地址。\n\
如果你執行這動作，請遵循下列動作 :\n\
\n\
- 回覆這郵件 \n或\n\
- 寄郵件到 %s 包含主題\n %s\n或\n\
- 寄郵件到 %s\n\
\n\
經由 URL %s 完成\n\
如果你不想執行這動作，請忽略本郵件。"

$set 7	Commands syslog messages (Commands.pm)

$set 8	Messages used in List.pm
1	"郵寄清單的擁有者 %s"
2	"郵寄清單 %s 訂閱\要求 "
3	"親愛的郵寄清單 %s 擁有者,\n\n\
有人要求加人你的郵寄清單。如果你接受\n\
請使用下列的指令:\n\n\
mailto:%s?subject=auth%%20%s%%20ADD%%20%s%%20%s%%20%s\n"
4	"郵寄清單 %s 的主持人"
5	"文章 %s 將通過"
6	"歡迎加入 %s 郵寄清單"
7	"檔案"
8	"\
   收到的郵寄 :  %9d\n\
   轉寄的郵寄 :  %9d\n\n\
   送出 (MB)  : %9.2f\n\
   轉寄 (MB)  : %9.2f\n"
9	"郵寄清單 %s 的摘要(digest)"
10	"如轉寄附上的郵寄到郵寄清單 %s : \n\
mailto:%s?subject=DISTRIBUTE%%20%s%%20%s\n\n"
11	"如拒絕(它將會刪除) :\n\
mailto:%s?subject=REJECT%%20%s%%20%s\n"
13	"目錄" 
14	"郵寄清單 %s 的結束"
15	"%d 電郵受限制 (郵寄清單 %s)" 
16	"需要核准"
21	"FYI: %s 郵寄清單 %s 由 %s %s"
22	"FYI: 指令 %s 郵寄清單 %s 由 %s %s \n (不需要做任何動作)\n"
23	"警告 : %s %s 退出失敗 (郵寄清單: %s) 因為他的電郵地址\n\
不在郵寄清單內\n (你可能協助這人)\n"
24	"取消訂閱\要求(郵寄清單 %s) "
25	"親愛的郵寄清單 %s 擁有者,\n\n\
有人要求加人你的郵寄清單。如果你接受\n\
請使用下列的指令:\n\n\
DEL %s %s\n"
26	"指令 %s 郵寄清單 %s 由 %s %s  由 %s 确認\n (不需要做任何動作)\n"
27	"Bounce rate in list %s is %d%%.\n\n\
You should delete bouncing subscribers : \n\
%s/reviewbouncing/%s"
28	"WARNING: bounce rate too high in list %s"

$set 9	Messages for the review header
1	"擁有者 Owner                   : %s\n"
2	"主持人 Moderator               : %s\n"
3	"訂閱\ Subscription              : %s\n"
4	"取消訂閱\ Un-subscription       : %s\n"
5	"正在傳送電郵 Sending messages  : %s\n"
6	"訂閱\者清單 Subscribers' list   : %s\n"
7	"回答到 Answer to               : %s\n"
8	"最大容量 Maximum size          : %d\n"
9	"郵寄清單 URL for the list      : %s\n"
10	"摘要 Digest                    : %s\n"
11	"自選主題 Custom subject        : %s\n"
12	"主題 Subject                   : %s\n"

$set 11	Messages used by the smtp module.
1	"Your system does not conform to the POSIX P1003.1 standard, or\n\
your Perl system does not define the _SC_ARG_MAX constant in its POSIX\n\
library. You must modify the smtp.pm module in order to set a value\n\
for variable $max_arg.\n"
2	"Unable to create a channel in smtpto: %m"

$set 12 MIME headers
1	"1.0"
2	"cn-big5"
3	"8bit"
4	"SYMPA <%s>"

$set 13	Messages for the header of moderation index
1	"\t     Date                 : %s"
2	"\t     Sender               : %s"
3	"\t     Size                 : %s\n"
4	"\t     Moderation key       : %s\n"
