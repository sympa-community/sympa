<!-- RCS Identication ; $Revision$ ; $Date$ -->

<FORM ACTION="[path_cgi]" METHOD=POST>
<TABLE WIDTH="100%" BORDER=0>
<TR><TH BGCOLOR="[dark_color]">
<FONT COLOR="[bg_color]">Abonnee informatie</FONT>
</TH></TR><TR><TD>
<INPUT TYPE="hidden" NAME="previous_action" VALUE=[previous_action]>
<INPUT TYPE="hidden" NAME="list" VALUE="[list]">
<INPUT TYPE="hidden" NAME="email" VALUE="[subscriber->escaped_email]">
<DL>
<DD>Email : <INPUT NAME="new_email" VALUE="[subscriber->escaped_email]" SIZE="25">
<DD>Naam : <INPUT NAME="gecos" VALUE="[subscriber->gecos]" SIZE="25">
<DD>Ingeschreven sinds [subscriber->date]	
<DD>Laatste wijziging : [subscriber->update_date]
<DD>Ontvangst : <SELECT NAME="reception">
		  [FOREACH r IN reception]
		    <OPTION VALUE="[r->NAME]" [r->selected]>[r->description]
		  [END]
	        </SELECT>

<DD>Zichtbaarheid : [subscriber->visibility]
<DD>Taal : [subscriber->lang]
<DD><INPUT TYPE="submit" NAME="action_set" VALUE="Wijzig">
<INPUT TYPE="submit" NAME="action_del" VALUE="Schrijf de gebruiker uit">
<INPUT TYPE="checkbox" NAME="quiet"> stil
</DL>
</TD></TR>
[IF subscriber->bounce]
<TR><TH BGCOLOR="[error_color]">
<FONT COLOR="[bg_color]">Bouncing adres</FONT>
</TH></TR><TR><TD>
<DL>
<DD>Status : [subscriber->bounce_status] ([subscriber->bounce_code])
<DD>Aantal bounces : [subscriber->bounce_count]
<DD>Periode : from [subscriber->first_bounce] to [subscriber->last_bounce]
<DD><A HREF="[path_cgi]/viewbounce/[list]/[subscriber->escaped_email]">Bekijk laatste bounce</A>
<DD><INPUT TYPE="submit" NAME="action_resetbounce" VALUE="Reset foutmeldingen">
</DL>
</TD></TR>
[ENDIF]
</TABLE>
</FORM>



