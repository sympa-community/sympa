<!-- RCS Identication ; $Revision$ ; $Date$ -->

<FORM ACTION="[path_cgi]" METHOD=POST>
<TABLE WIDTH="100%" BORDER=0>
<TR><TH BGCOLOR="[dark_color]">
<FONT COLOR="[bg_color]">Listiliikme info</FONT>
</TH></TR><TR><TD>
<INPUT TYPE="hidden" NAME="previous_action" VALUE=[previous_action]>
<INPUT TYPE="hidden" NAME="list" VALUE="[list]">
<INPUT TYPE="hidden" NAME="email" VALUE="[current_subscriber->escaped_email]">
<DL>
<DD>Epost: <INPUT NAME="new_email" VALUE="[current_subscriber->email]" SIZE="25">
<DD>Nimi: <INPUT NAME="gecos" VALUE="[current_subscriber->gecos]" SIZE="25">
<DD>Liitus listiga [current_subscriber->date]
<DD>Viimane uuendus: [current_subscriber->update_date]
<DD>Info saamise viis: <SELECT NAME="reception">
		  [FOREACH r IN reception]
		    <OPTION VALUE="[r->NAME]" [r->selected]>[r->description]
		  [END]
	        </SELECT>

<DD>Nähtavus: [current_subscriber->visibility]
<DD>Keel: [current_subscriber->lang]
<DD><INPUT TYPE="submit" NAME="action_set" VALUE="Uuenda">
<INPUT TYPE="submit" NAME="action_del" VALUE="Eemalda listist">
<INPUT TYPE="checkbox" NAME="quiet"> teavituseta
</DL>
</TD></TR>
[IF current_subscriber->bounce]
<TR><TH BGCOLOR="[error_color]">
<FONT COLOR="[bg_color]">Vigane aadress</FONT>
</TD></TR><TR><TD>
<DL>
<DD>Olek: [current_subscriber->bounce_status] ([current_subscriber->bounce_code])
<DD>Vigade arv: [current_subscriber->bounce_count]
<DD>Vigade esinemise periood: from [current_subscriber->first_bounce] to [current_subscriber->last_bounce]
<DD><A HREF="[path_cgi]/viewbounce/[list]/[current_subscriber->escaped_email]">Vaata viimast veateadet</A>
<DD><INPUT TYPE="submit" NAME="action_resetbounce" VALUE="Tühista vead">
</DL>
</TD></TR>
[ENDIF]
</TABLE>
</FORM>



