From: [conf->sympa]
Reply-to: [conf->request]
To: [newuser->email]
[IF action=subrequest]
Subject: [wwsconf->title] / subscribing to [list]
[ELSIF action=sigrequest]
Subject: [wwsconf->title] / unsubscribing from [list]
[ELSE]
Subject: [wwsconf->title] / your environment
[ENDIF]
Content-Type: multipart/alternative;
  boundary="============ [list] ============--"
Content-Transfer-Encoding: 7bit

--============ [list] ============--
Content-Type: text/plain
Content-Transfer-Encoding: 7bit

[IF action=subrequest]
You requested a subscription to [list] mailing list.

To confirm your subscription, you need to provide the following password

	password: [newuser->password]

[ELSIF action=sigrequest]
You requested unsubscription from [list] mailing list.

To unsubscribe from the list, you need to provide the following password

	password: [newuser->password]

[ELSE]
To access your personal environment, you need to login first

     your email address    : [newuser->email]
     your password : [newuser->password]

Changing your password 
[base_url][path_cgi]/choosepasswd/[newuser->escaped_email]/[newuser->password]
[ENDIF]


[wwsconf->title]: [base_url][path_cgi] 

Help on Sympa: [base_url][path_cgi]/help

--============ [list] ============--
Content-Type: text/html
Content-Transfer-Encoding:  7bit

<HTML>
<HEAD>
</HEAD>
<BODY>

<TABLE WIDTH="100%" BORDER="0" cellpadding="2" cellspacing="0">
<TR><TD WIDTH="100%">&nbsp</TD>
<TD NOWRAP BGCOLOR="--LIGHT_COLOR--" ALIGN="right"><A HREF="[base_url][path_cgi]">Home</A> <B>|</B>
<A HREF="[base_url][path_cgi]/help">Help</A></TD>
</TR>
<TR><TD COLSPAN="2" ALIGN="center" BGCOLOR="--SELECTED_COLOR--">
<FONT COLOR="--BG_COLOR--" SIZE="+2"><B>
[IF action=subrequest]
[wwsconf->title] / subscribing to [list]
[ELSIF action=sigrequest]
[wwsconf->title] / unsubscribing from [list]
[ELSE]
[wwsconf->title] / your environment
</B></FONT>
</TD></TR>
<TR><TD COLSPAN="2" BGCOLOR="--BG_COLOR--">

<P>
<FORM ACTION="[base_url][path_cgi]" METHOD=POST>
<INPUT TYPE="hidden" NAME="email" VALUE="[newuser->email]">
<INPUT TYPE="hidden" NAME="passwd" VALUE="[newuser->password]">

[IF action=subrequest]
You requested a subscription to [list] mailing list.<BR>
To confirm your subscription, choose a password associated to your email
and submit the form bellow :<UL>

<INPUT TYPE="hidden" NAME="action" VALUE="subscribe">
<INPUT TYPE="hidden" NAME="list" VALUE="[list]">

<LI>Email address: [newuser->email]
<LI>Password: <INPUT TYPE="password" NAME="newpasswd1" SIZE=15>
<LI>Re-enter your password: <INPUT TYPE="password" NAME="newpasswd2" SIZE=15>
</UL>

<INPUT TYPE="submit" NAME="action_subscribe" VALUE="Subscribe to [list]">

[ELSIF action=sigrequest]
You requested unsubscription from [list] mailing list.<BR>
To unsubscribe from the list, choose a password associated to your email
and submit the form bellow :<UL>

<INPUT TYPE="hidden" NAME="action" VALUE="signoff">
<INPUT TYPE="hidden" NAME="list" VALUE="[list]">

<LI>Email address: [newuser->email]
<LI>Password: <INPUT TYPE="password" NAME="newpasswd1" SIZE=15>
<LI>Re-enter your password: <INPUT TYPE="password" NAME="newpasswd2" SIZE=15>

</UL>
<INPUT TYPE="submit" NAME="action_signoff" VALUE="Unsubscribe from [list]">

[ELSE]

<INPUT TYPE="hidden" NAME="action" VALUE="login">

To access your personal environment, you need to login first.<BR>
[IF init_passwd=1]
Please choose a password that will be associated to your email
address :<UL>
<LI>Email address: [newuser->email]
<LI>Password: <INPUT TYPE="password" NAME="newpasswd1" SIZE=15>
<LI>Re-enter your password: <INPUT TYPE="password" NAME="newpasswd2" SIZE=15>
</UL>
[ELSE]
<UL>
<LI>Email address   : <B>[newuser->email]</B>
<LI>Your password   : <B>[newuser->password]</B>	
</UL>
[ENDIF]

<INPUT TYPE="submit" NAME="action_login" VALUE="Login">

[ENDIF]
</FORM>

</TD></TR>
<TR><TD ALIGN="right"COLSPAN="2">
<I>Powered by <A HREF="http://listes.cru.fr/sympa">Sympa</A></I>
</TD></TR>
</TABLE>

</BODY>

</HTML>

--============ [list] ============----
