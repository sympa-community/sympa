<!-- RCS Identication ; $Revision$ ; $Date$ -->

<FORM ACTION="[path_cgi]" METHOD=POST>
<TABLE WIDTH="100%" BORDER=0>
<TR><TH BGCOLOR="[dark_color]">
<FONT COLOR="[bg_color]">Informazione del sottoscrivente</FONT>
</TH></TR><TR><TD>
<INPUT TYPE="hidden" NAME="previous_action" VALUE=[previous_action]>
<INPUT TYPE="hidden" NAME="list" VALUE="[list]">
<INPUT TYPE="hidden" NAME="email" VALUE="[current_subscriber->escaped_email]">
<DL>
<DD>Email : <A HREF="mailto:[current_subscriber->email]">[current_subscriber->email]</A>
<DD>Nome : <INPUT NAME="gecos" VALUE="[current_subscriber->gecos]" SIZE="25">
<DD>Sottoscritto dal [current_subscriber->date]
<DD>Modalit&agrave; di ricezione : <SELECT NAME="reception">
		  [FOREACH r IN reception]
		    <OPTION VALUE="[r->NAME]" [r->selected]>[r->description]
		  [END]
	        </SELECT>

<DD>Visibilit&agrave; : [current_subscriber->visibility]
<DD>Lingua: [current_subscriber->lang]
<DD><INPUT TYPE="submit" NAME="action_set" VALUE="Aggiorna">
<INPUT TYPE="submit" NAME="action_del" VALUE="Cancella l'utente">
<INPUT TYPE="checkbox" NAME="quiet"> silenzioso
</DL>
</TD></TR>
[IF current_subscriber->bounce]
<TR><TH BGCOLOR="[error_color]">
<FONT COLOR="[bg_color]">Indirizzo non funzionante</FONT>
</TD></TR><TR><TD>
<DL>
<DD>Stato : [current_subscriber->bounce_status] ([current_subscriber->bounce_code])
<DD>Conteggio degli errori : [current_subscriber->bounce_count]
<DD>Periodo : dal [current_subscriber->first_bounce] al [current_subscriber->last_bounce]
<DD><A HREF="[path_cgi]/viewbounce/[list]/[current_subscriber->escaped_email]">Guarda l'ultimo errore</A>
<DD><INPUT TYPE="submit" NAME="action_resetbounce" VALUE="Resetta gli errori">
</DL>
</TD></TR>
[ENDIF]
</TABLE>
</FORM>



