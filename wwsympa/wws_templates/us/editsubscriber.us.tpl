<!-- RCS Identication ; $Revision$ ; $Date$ -->

<FORM ACTION="[path_cgi]" METHOD=POST>
<TABLE WIDTH="100%" BORDER=0>
<TR><TH BGCOLOR="--DARK_COLOR--">
<FONT COLOR="--BG_COLOR--">Subscriber information</FONT>
</TH></TR><TR><TD>
<INPUT TYPE="hidden" NAME="previous_action" VALUE=[previous_action]>
<INPUT TYPE="hidden" NAME="list" VALUE="[list]">
<INPUT TYPE="hidden" NAME="email" VALUE="[subscriber->escaped_email]">
<DL>
<DD>Email : <INPUT NAME="new_email" VALUE="[subscriber->email]" SIZE="25">
<DD>Name : <INPUT NAME="gecos" VALUE="[subscriber->gecos]" SIZE="25">
<DD>Subscribed since [subscriber->date]
<DD>Reception : <SELECT NAME="reception">
		  [FOREACH r IN reception]
		    <OPTION VALUE="[r->NAME]" [r->selected]>[r->description]
		  [END]
	        </SELECT>

<DD>Visibility : [subscriber->visibility]
<DD>Language : [subscriber->lang]
<DD><INPUT TYPE="submit" NAME="action_set" VALUE="Update">
<INPUT TYPE="submit" NAME="action_del" VALUE="Unsubscribe the User">
<INPUT TYPE="checkbox" NAME="quiet"> quiet
</DL>
</TD></TR>
[IF subscriber->bounce]
<TR><TH BGCOLOR="--ERROR_COLOR--">
<FONT COLOR="--BG_COLOR--">Bouncing address</FONT>
</TD></TR><TR><TD>
<DL>
<DD>Status : [subscriber->bounce_status] ([subscriber->bounce_code])
<DD>Bounces count : [subscriber->bounce_count]
<DD>Period : from [subscriber->first_bounce] to [subscriber->last_bounce]
<DD><A HREF="[path_cgi]/viewbounce/[list]/[subscriber->escaped_email]">View last bounce</A>
<DD><INPUT TYPE="submit" NAME="action_resetbounce" VALUE="Reset errors">
</DL>
</TD></TR>
[ENDIF]
</TABLE>
</FORM>



