<!-- RCS Identication ; $Revision$ ; $Date$ -->

<FORM ACTION="[path_cgi]" METHOD=POST>
<TABLE WIDTH="100%" BORDER=0>
<TR><TH BGCOLOR="#330099">
<FONT COLOR="#ffffff">Informace o èlenu</FONT>
</TH></TR><TR><TD>
<INPUT TYPE="hidden" NAME="previous_action" VALUE=[previous_action]>
<INPUT TYPE="hidden" NAME="list" VALUE="[list]">
<INPUT TYPE="hidden" NAME="email" VALUE="[subscriber->escaped_email]">
<DL>
<DD>Adresa : <INPUT NAME="new_email" VALUE="[subscriber->email]" SIZE="25">
<DD>Jméno : <INPUT NAME="gecos" VALUE="[subscriber->gecos]" SIZE="25">
<DD>èlenem od [subscriber->date]
<DD>Pøíjem : <SELECT NAME="reception">
		  [FOREACH r IN reception]
		    <OPTION VALUE="[r->NAME]" [r->selected]>[r->description]
		  [END]
	        </SELECT>

<DD>Viditelnost : [subscriber->visibility]
<DD>Jazyk : [subscriber->lang]
<DD><INPUT TYPE="submit" NAME="action_set" VALUE="Zmìnit">
<INPUT TYPE="submit" NAME="action_del" VALUE="Odhlásit u¾ivatele">
<INPUT TYPE="checkbox" NAME="quiet"> Potichu
</DL>
</TD></TR>
[IF subscriber->bounce]
<TR><TH BGCOLOR="#ff6666">
<FONT COLOR="#ffffff">Vracející se adresa</FONT>
</TD></TR><TR><TD>
<DL>
<DD>Stav : [subscriber->bounce_status] ([subscriber->bounce_code])
<DD>Poèet vrácených zpráv : [subscriber->bounce_count]
<DD>Období : od [subscriber->first_bounce] do [subscriber->last_bounce]
<DD><A HREF="[path_cgi]/viewbounce/[list]/[subscriber->escaped_email]">Zobrazit poslední vrácenou zprávu</A>
<DD><INPUT TYPE="submit" NAME="action_resetbounce" VALUE="Vynulovat chyby">
</DL>
</TD></TR>
[ENDIF]
</TABLE>
</FORM>
