<!-- RCS Identication ; $Revision$ ; $Date$ -->

<FORM ACTION="[path_cgi]" METHOD=POST>
<TABLE WIDTH="100%" BORDER=0>
<TR><TH BGCOLOR="[dark_color]">
<FONT COLOR="[bg_color]">Listiliikme info</FONT>
</TH></TR><TR><TD>
<INPUT TYPE="hidden" NAME="previous_action" VALUE=[previous_action]>
<INPUT TYPE="hidden" NAME="list" VALUE="[list]">
<INPUT TYPE="hidden" NAME="email" VALUE="[subscriber->escaped_email]">
<DL>
<DD>Epost: <INPUT NAME="new_email" VALUE="[subscriber->email]" SIZE="25">
<DD>Nimi: <INPUT NAME="gecos" VALUE="[subscriber->gecos]" SIZE="25">
<DD>Liitus listiga [subscriber->date]
<DD>Viimane uuendus: [subscriber->update_date]
<DD>Info saamise viis: <SELECT NAME="reception">
		  [FOREACH r IN reception]
		    <OPTION VALUE="[r->NAME]" [r->selected]>[r->description]
		  [END]
	        </SELECT>

<DD>Nähtavus: [subscriber->visibility]
<DD>Keel: [subscriber->lang]
<DD><INPUT TYPE="submit" NAME="action_set" VALUE="Uuenda">
<INPUT TYPE="submit" NAME="action_del" VALUE="Eemalda listist">
<INPUT TYPE="checkbox" NAME="quiet"> teavituseta
</DL>
</TD></TR>
[IF subscriber->bounce]
<TR><TH BGCOLOR="[error_color]">
<FONT COLOR="[bg_color]">Vigane aadress</FONT>
</TD></TR><TR><TD>
<DL>
<DD>Olek: [subscriber->bounce_status] ([subscriber->bounce_code])
<DD>Vigade arv: [subscriber->bounce_count]
<DD>Vigade esinemise periood: from [subscriber->first_bounce] to [subscriber->last_bounce]
<DD><A HREF="[path_cgi]/viewbounce/[list]/[subscriber->escaped_email]">Vaata viimast veateadet</A>
<DD><INPUT TYPE="submit" NAME="action_resetbounce" VALUE="Tühista vead">
</DL>
</TD></TR>
[ENDIF]
</TABLE>
</FORM>



