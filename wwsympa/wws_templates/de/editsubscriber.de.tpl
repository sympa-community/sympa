<!-- RCS Identication ; $Revision$ ; $Date$ -->

<FORM ACTION="[path_cgi]" METHOD=POST>
<TABLE WIDTH="100%" BORDER=0>
<TR><TH BGCOLOR="--DARK_COLOR--">
<FONT COLOR="--BG_COLOR--">Abonnenten Information</FONT>
</TH></TR><TR><TD>
<INPUT TYPE="hidden" NAME="previous_action" VALUE=[previous_action]>
<INPUT TYPE="hidden" NAME="list" VALUE="[list]">
<INPUT TYPE="hidden" NAME="email" VALUE="[subscriber->escaped_email]">
<DL>
<DD>Email: <INPUT NAME="new_email" VALUE="[subscriber->email]" SIZE="25">
<DD>Name: <INPUT NAME="gecos" VALUE="[subscriber->gecos]" SIZE="25">
<DD>Abonnent seit [subscriber->date]
<DD>Empfang: <SELECT NAME="reception">
		  [FOREACH r IN reception]
		    <OPTION VALUE="[r->NAME]" [r->selected]>[r->description]
		  [END]
	        </SELECT>

<DD>Sichbarkeit: [subscriber->visibility]
<DD>Sprache: [subscriber->lang]
<DD><INPUT TYPE="submit" NAME="action_set" VALUE="&Auml;ndern">
<INPUT TYPE="submit" NAME="action_del" VALUE="Abonnierung beenden">
<INPUT TYPE="checkbox" NAME="quiet"> Still
</DL>
</TD></TR>
[IF subscriber->bounce]
<TR><TH BGCOLOR="--ERROR_COLOR--">
<FONT COLOR="--BG_COLOR--">Unzustellbare Adresse</FONT>
</TD></TR><TR><TD>
<DL>
<DD>Zustand: [subscriber->bounce_status] ([subscriber->bounce_code])
<DD>Anzahl: [subscriber->bounce_count]
<DD>Zeitraum: from [subscriber->first_bounce] to [subscriber->last_bounce]
<DD><A HREF="[path_cgi]/viewbounce/[list]/[subscriber->escaped_email]">Letzte abgewiesene Nachricht anschauen</A>
<DD><INPUT TYPE="submit" NAME="action_resetbounce" VALUE="Zur&uuml;cksetzen">
</DL>
</TD></TR>
[ENDIF]
</TABLE>
</FORM>



