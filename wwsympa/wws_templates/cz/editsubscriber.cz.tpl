<!-- RCS Identication ; $Revision$ ; $Date$ -->

<FORM ACTION="[path_cgi]" METHOD=POST>
<TABLE WIDTH="100%" BORDER=0>
<TR><TH BGCOLOR="[dark_color]">
<FONT COLOR="[bg_color]">Informace o èlenu</FONT>
</TH></TR><TR><TD>
<INPUT TYPE="hidden" NAME="previous_action" VALUE=[previous_action]>
<INPUT TYPE="hidden" NAME="list" VALUE="[list]">
<INPUT TYPE="hidden" NAME="email" VALUE="[current_subscriber->escaped_email]">
<DL>
<DD>Adresa : <INPUT NAME="new_email" VALUE="[current_subscriber->escaped_email]" SIZE="25">
<DD>Jméno : <INPUT NAME="gecos" VALUE="[current_subscriber->gecos]" SIZE="25">
<DD>Èlenem od [current_subscriber->date]
<DD>Poslední zmìna [current_subscriber->update_date]
<DD>Pøíjem : <SELECT NAME="reception">
		  [FOREACH r IN reception]
		    <OPTION VALUE="[r->NAME]" [r->selected]>[r->description]
		  [END]
	        </SELECT>

<DD>Viditelnost : [current_subscriber->visibility]
<DD>Jazyk : [current_subscriber->lang]
[IF additional_fields]
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
[ENDIF]
<DD><INPUT TYPE="submit" NAME="action_set" VALUE="Update">
<INPUT TYPE="submit" NAME="action_del" VALUE="Unsubscribe the User">
<INPUT TYPE="checkbox" NAME="quiet"> quiet
</DL>
</TD></TR>
[IF current_subscriber->bounce]
<TR><TH BGCOLOR="[error_color]">
<FONT COLOR="[bg_color]">Vracející se adresa</FONT>
</TH></TR><TR><TD>
<DL>
<DD>Stav : [current_subscriber->bounce_status] ([current_subscriber->bounce_code])
<DD>Poèet vrácených zpráv : [current_subscriber->bounce_count]
<DD>Období : od [current_subscriber->first_bounce] do [current_subscriber->last_bounce]
<DD><A HREF="[path_cgi]/viewbounce/[list]/[current_subscriber->escaped_email]">Zobrazit poslední vrácenou zprávu</A>
<DD><INPUT TYPE="submit" NAME="action_resetbounce" VALUE="Vynulovat chyby">
</DL>
</TD></TR>
[ENDIF]
</TABLE>
</FORM>



