<!-- RCS Identication ; $Revision$ ; $Date$ -->

<FORM ACTION="[path_cgi]" METHOD=POST>
<TABLE WIDTH="100%" BORDER=0>
<TR><TH BGCOLOR="[dark_color]">
<FONT COLOR="[bg_color]">Abonnee informatie</FONT>
</TH></TR><TR><TD>
<INPUT TYPE="hidden" NAME="previous_action" VALUE=[previous_action]>
<INPUT TYPE="hidden" NAME="list" VALUE="[list]">
<INPUT TYPE="hidden" NAME="email" VALUE="[current_subscriber->escaped_email]">
<DL>
<DD>Email : <INPUT NAME="new_email" VALUE="[current_subscriber->escaped_email]" SIZE="25">
<DD>Naam : <INPUT NAME="gecos" VALUE="[current_subscriber->gecos]" SIZE="25">
<DD>Ingeschreven sinds [current_subscriber->date]	
<DD>Laatste wijziging : [current_subscriber->update_date]
<DD>Ontvangst : <SELECT NAME="reception">
		  [FOREACH r IN reception]
		    <OPTION VALUE="[r->NAME]" [r->selected]>[r->description]
		  [END]
	        </SELECT>

<DD>Zichtbaarheid : [current_subscriber->visibility]
<DD>Taal : [current_subscriber->lang]
<DD><INPUT TYPE="submit" NAME="action_set" VALUE="Wijzig">
<INPUT TYPE="submit" NAME="action_del" VALUE="Schrijf de gebruiker uit">
<INPUT TYPE="checkbox" NAME="quiet"> stil
</DL>
</TD></TR>
[IF current_subscriber->bounce]
<TR><TH BGCOLOR="[error_color]">
<FONT COLOR="[bg_color]">Bouncing adres</FONT>
</TH></TR><TR><TD>
<DL>
<DD>Status : [current_subscriber->bounce_status] ([current_subscriber->bounce_code])
<DD>Aantal bounces : [current_subscriber->bounce_count]
<DD>Periode : from [current_subscriber->first_bounce] to [current_subscriber->last_bounce]
<DD><A HREF="[path_cgi]/viewbounce/[list]/[current_subscriber->escaped_email]">Bekijk laatste bounce</A>
<DD><INPUT TYPE="submit" NAME="action_resetbounce" VALUE="Reset foutmeldingen">
</DL>
</TD></TR>
[ENDIF]
</TABLE>
</FORM>



