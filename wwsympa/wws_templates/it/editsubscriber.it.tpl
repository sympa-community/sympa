<FORM ACTION="[path_cgi]" METHOD=POST>
<TABLE WIDTH="100%" BORDER=0>
<TR><TH BGCOLOR="--DARK_COLOR--">
<FONT COLOR="--BG_COLOR--">Informazione del sottoscrivente</FONT>
</TH></TR><TR><TD>
<INPUT TYPE="hidden" NAME="previous_action" VALUE=[previous_action]>
<INPUT TYPE="hidden" NAME="list" VALUE="[list]">
<INPUT TYPE="hidden" NAME="email" VALUE="[subscriber->escaped_email]">
<DL>
<DD>Email : <A HREF="mailto:[subscriber->email]">[subscriber->email]</A>
<DD>Nome : <INPUT NAME="gecos" VALUE="[subscriber->gecos]" SIZE="25">
<DD>Sottoscritto dal [subscriber->date]
<DD>Modalit&agrave; di ricezione : <SELECT NAME="reception">
		  [FOREACH r IN reception]
		    <OPTION VALUE="[r->NAME]" [r->selected]>[r->description]
		  [END]
	        </SELECT>

<DD>Visibilit&agrave; : [subscriber->visibility]
<DD>Lingua: [subscriber->lang]
<DD><INPUT TYPE="submit" NAME="action_set" VALUE="Aggiorna">
<INPUT TYPE="submit" NAME="action_del" VALUE="Cancella l'utente">
<INPUT TYPE="checkbox" NAME="quiet"> silenzioso
</DL>
</TD></TR>
[IF subscriber->bounce]
<TR><TH BGCOLOR="--ERROR_COLOR--">
<FONT COLOR="--BG_COLOR--">Indirizzo non funzionante</FONT>
</TD></TR><TR><TD>
<DL>
<DD>Stato : [subscriber->bounce_status] ([subscriber->bounce_code])
<DD>Conteggio degli errori : [subscriber->bounce_count]
<DD>Periodo : dal [subscriber->first_bounce] al [subscriber->last_bounce]
<DD><A HREF="[path_cgi]/viewbounce/[list]/[subscriber->escaped_email]">Guarda l'ultimo errore</A>
<DD><INPUT TYPE="submit" NAME="action_resetbounce" VALUE="Resetta gli errori">
</DL>
</TD></TR>
[ENDIF]
</TABLE>
</FORM>



