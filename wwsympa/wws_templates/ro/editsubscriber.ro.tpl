<!-- RCS Identication ; $Revision$ ; $Date$ -->

<FORM ACTION="[path_cgi]" METHOD=POST>
<TABLE WIDTH="100%" BORDER=0>
<TR>
      <TH BGCOLOR="[dark_color]"> <font color="[bg_color]">Informatii abonat</font> 
      </TH>
    </TR><TR><TD>
<INPUT TYPE="hidden" NAME="previous_action" VALUE=[previous_action]>
<INPUT TYPE="hidden" NAME="list" VALUE="[list]">
<INPUT TYPE="hidden" NAME="email" VALUE="[current_subscriber->escaped_email]">
<DL>
<DD>Email : <INPUT NAME="new_email" VALUE="[current_subscriber->email]" SIZE="25">
          <DD>Nume : 
            <INPUT NAME="gecos" VALUE="[current_subscriber->gecos]" SIZE="25">
          <DD>Abonat din[current_subscriber->date] 
          <DD>Ultima actualizare: [current_subscriber->update_date] 
          <DD>Primire : 
            <SELECT NAME="reception">
		  [FOREACH r IN reception]
		    <OPTION VALUE="[r->NAME]" [r->selected]>[r->description]
		  [END]
	        </SELECT>

          <DD>Vizibilitate : [current_subscriber->visibility] 
          <DD>Limba : [current_subscriber->lang] 
          <DD>
            <INPUT TYPE="submit" NAME="action_set" VALUE="Actualizare">
            <INPUT TYPE="submit" NAME="action_del" VALUE="Dezabonare utilizator">
<INPUT TYPE="checkbox" NAME="quiet"> quiet
</DL>
</TD></TR>
[IF current_subscriber->bounce]
<TR>
      <TH BGCOLOR="[error_color]"> <FONT COLOR="[bg_color]">Adresa bumerang</FONT> 
    </TH></TR><TR><TD>
<DL>
          <DD>Statut : [current_subscriber->bounce_status] ([current_subscriber->bounce_code]) 
          <DD>Contor adrese bumerang: [current_subscriber->bounce_count] 
          <DD>Perioada : de la [current_subscriber->first_bounce] la[current_subscriber->last_bounce] 
          <DD><A HREF="[path_cgi]/viewbounce/[list]/[current_subscriber->escaped_email]">Vezi 
            ultimul efect bumerang</A>
          <DD>
            <INPUT TYPE="submit" NAME="action_resetbounce" VALUE="Reseteaza erorile">
</DL>
</TD></TR>
[ENDIF]
</TABLE>
</FORM>



