<!-- RCS Identication ; $Revision$ ; $Date$ -->

<FORM ACTION="[path_cgi]" METHOD=POST>
<TABLE WIDTH="100%" BORDER=0>
<TR><TH BGCOLOR="[dark_color]">
<FONT COLOR="[bg_color]">Información del Suscriptor</FONT>
</TH></TR><TR><TD>
<INPUT TYPE="hidden" NAME="previous_action" VALUE=[previous_action]>
<INPUT TYPE="hidden" NAME="list" VALUE="[list]">
<INPUT TYPE="hidden" NAME="email" VALUE="[current_subscriber->escaped_email]">
<DL>
<DD>Email : <A HREF="mailto:[current_subscriber->email]">[current_subscriber->email]</A>
<DD>Nombre : <INPUT NAME="gecos" VALUE="[current_subscriber->gecos]" SIZE="25">
<DD>Suscrito desde [current_subscriber->date]
<DD>Recepción : <SELECT NAME="reception">
		  [FOREACH r IN reception]
		    <OPTION VALUE="[r->NAME]" [r->selected]>[r->description]
		  [END]
	        </SELECT>

<DD>Visibilidad : [current_subscriber->visibility]
<DD>Idioma : [current_subscriber->lang]
<DD><INPUT TYPE="submit" NAME="action_set" VALUE="Actualizar">
<INPUT TYPE="submit" NAME="action_del" VALUE="Anular su suscripción">
<INPUT TYPE="checkbox" NAME="quiet"> silencioso
</DL>
</TD></TR>
[IF current_subscriber->bounce]
<TR><TH BGCOLOR="[error_color]">
<FONT COLOR="[bg_color]">Dirección errónea</FONT>
</TD></TR><TR><TD>
<DL>
<DD>Estado : [current_subscriber->bounce_status] ([current_subscriber->bounce_code])
<DD>Nro. de errores: [current_subscriber->bounce_count]
<DD>Período : from [current_subscriber->first_bounce] to [current_subscriber->last_bounce]
<DD><A HREF="[path_cgi]/viewbounce/[list]/[current_subscriber->escaped_email]">Ver último error</A>
<DD><INPUT TYPE="submit" NAME="action_resetbounce" VALUE="Inicializar errores">
</DL>
</TD></TR>
[ENDIF]
</TABLE>
</FORM>



