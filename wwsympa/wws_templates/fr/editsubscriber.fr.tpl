<!-- RCS Identication ; $Revision$ ; $Date$ -->

<FORM ACTION="[path_cgi]" METHOD=POST>
<TABLE WIDTH="100%" BORDER=0>
<TR><TH BGCOLOR="[dark_color]">
<FONT COLOR="[bg_color]">Information abonné</FONT>
</TH></TR><TR><TD>
<INPUT TYPE="hidden" NAME="previous_action" VALUE=[previous_action]>
<INPUT TYPE="hidden" NAME="list" VALUE="[list]">
<INPUT TYPE="hidden" NAME="email" VALUE="[current_subscriber->escaped_email]">
<DL>
<DD>E-mail : <INPUT NAME="new_email" VALUE="[current_subscriber->escaped_email]" SIZE="25">
<DD>Nom : <INPUT NAME="gecos" VALUE="[current_subscriber->gecos]" SIZE="25">
<DD>Abonné depuis : [current_subscriber->date]
<DD>Dernière mise à jour : [current_subscriber->update_date]
<DD>Réception : <SELECT NAME="reception">
		  [FOREACH r IN reception]
		    <OPTION VALUE="[r->NAME]" [r->selected]>[r->description]
		  [END]
	        </SELECT>

<DD>Visibilité : [current_subscriber->visibility]
<DD>Langue : [current_subscriber->lang]
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
<DD><INPUT TYPE="submit" NAME="action_set" VALUE="Mise à jour">
<INPUT TYPE="submit" NAME="action_del" VALUE="Désabonner l'usager">
<INPUT TYPE="checkbox" NAME="quiet"> sans prévenir
</DL>
</TD></TR>
[IF current_subscriber->bounce]
<TR><TH BGCOLOR="[error_color]">
<FONT COLOR="[bg_color]">Adresse en erreur</FONT>
</TH></TR><TR><TD>
<DL>
<DD>Type d'erreur : [current_subscriber->bounce_status] ([current_subscriber->bounce_code])
<DD>Nombre de retour : [current_subscriber->bounce_count]
<DD>Période : from [current_subscriber->first_bounce] to [current_subscriber->last_bounce]
<DD><A HREF="[path_cgi]/viewbounce/[list]/[current_subscriber->escaped_email]">Dernière erreur</A>
<DD><INPUT TYPE="submit" NAME="action_resetbounce" VALUE="Effacer les erreurs">
</DL>
</TD></TR>
[ENDIF]
</TABLE>
</FORM>



