<!-- RCS Identication ; $Revision$ ; $Date$ -->

<FORM ACTION="[path_cgi]" METHOD=POST>
<TABLE WIDTH="100%" BORDER=0>
<TR><TH BGCOLOR="[dark_color]">
<FONT COLOR="[bg_color]">Subscriber information</FONT>
</TH></TR><TR><TD>
<INPUT TYPE="hidden" NAME="previous_action" VALUE=[previous_action]>
<INPUT TYPE="hidden" NAME="list" VALUE="[list]">
<INPUT TYPE="hidden" NAME="email" VALUE="[current_subscriber->escaped_email]">
<DL>
<DD>Email : <INPUT NAME="new_email" VALUE="[current_subscriber->escaped_email]" SIZE="25">
<DD>Name : <INPUT NAME="gecos" VALUE="[current_subscriber->gecos]" SIZE="25">
<DD>Subscribed since [current_subscriber->date]	
<DD>Last update : [current_subscriber->update_date]
<DD>Reception : <SELECT NAME="reception">
		  [FOREACH r IN reception]
		    <OPTION VALUE="[r->NAME]" [r->selected]>[r->description]
		  [END]
	        </SELECT>

<DD>Visibility : [current_subscriber->visibility]
<DD>Language : [current_subscriber->lang]
[FOREACH field IN additional_fields]
 [IF field->type=enum]
    <DD>[field->NAME] :  <SELECT NAME="additional_field_[field->NAME]">
	                  <OPTION VALUE="">
	[FOREACH e IN field->enum]
		          <OPTION VALUE="[e->NAME]" [e]>[e->NAME]
        [END]
	                 </SELECT>
 [ELSE]
    <DD>[field->NAME] : <INPUT NAME="additional_field_[field->NAME]" VALUE="[field->value]" SIZE="25">
 [ENDIF]
[END]
<DD><INPUT TYPE="submit" NAME="action_set" VALUE="Update">
<INPUT TYPE="submit" NAME="action_del" VALUE="Unsubscribe the User">
<INPUT TYPE="checkbox" NAME="quiet"> quiet
</DL>
</TD></TR>
[IF current_subscriber->bounce]
<TR><TH BGCOLOR="[error_color]">
<FONT COLOR="[bg_color]">Bouncing address</FONT>
</TH></TR><TR><TD>
<DL>
<DD>Status : [current_subscriber->bounce_status] ([current_subscriber->bounce_code])
<DD>Bounces count : [current_subscriber->bounce_count]
<DD>Period : from [current_subscriber->first_bounce] to [current_subscriber->last_bounce]
<DD><A HREF="[path_cgi]/viewbounce/[list]/[current_subscriber->escaped_email]">View last bounce</A>
<DD><INPUT TYPE="submit" NAME="action_resetbounce" VALUE="Reset errors">
</DL>
</TD></TR>
[ENDIF]
</TABLE>
</FORM>



