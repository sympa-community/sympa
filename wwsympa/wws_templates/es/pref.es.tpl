<!-- RCS Identication ; $Revision$ ; $Date$ -->


    <TABLE WIDTH="100%" CELLPADDING="1" CELLSPACING="0">
      <TR VALIGN="top">
        <TH BGCOLOR="[dark_color]" COLSPAN="2">
          <TABLE WIDTH="100%" CELLPADDING="0" CELLSPACING="0">
            <TR>
             <TH BGCOLOR="[selected_color]" WIDTH="50%">
	      <FONT COLOR="[bg_color]">
	        Su configuración
	      </FONT>
	     </TH>
            </TR>
           </TABLE>
         </TH>
      </TR>
      <TR VALIGN="top">
	<TD>
	  <FORM ACTION="[path_cgi]" METHOD=POST>
	    <INPUT TYPE="hidden" NAME="previous_action" VALUE="[previous_action]">
	    <INPUT TYPE="hidden" NAME="previous_list" VALUE="[previous_list]">
  	    <FONT COLOR="[dark_color]">E-mail </FONT> [user->email]<BR><BR>
	    <FONT COLOR="[dark_color]">Nombre</FONT> 
	    <INPUT TYPE="text" NAME="gecos" SIZE=20 VALUE="[user->gecos]"><BR><BR> 
	    <FONT COLOR="[dark_color]">Idioma </FONT>
	    <SELECT NAME="lang">
	      [FOREACH l IN languages]
	        <OPTION VALUE="[l->NAME]" [l->selected]>[l->complete]
	      [END]
	    </SELECT>
	    <BR><BR>
	    <FONT COLOR="[dark_color]">Duración de la conexión </FONT>
	    <SELECT NAME="cookie_delay">
	      [FOREACH period IN cookie_periods]
	        <OPTION VALUE="[period->value]" [period->selected]>[period->desc]
	      [END]
	    </SELECT>
	    <BR><BR>
	    <INPUT TYPE="submit" NAME="action_setpref" VALUE="Aceptar"></FONT>
	  </FORM>
	</TD>
      </TR>
      <TR VALIGN="top">
        <TH BGCOLOR="[dark_color]" COLSPAN="2">
          <TABLE WIDTH="100%" CELLPADDING="0" CELLSPACING="0">
            <TR>
	     <TH WIDTH="50%" BGCOLOR="[selected_color]">
	      <FONT COLOR="[bg_color]">
	        Modificar su E-mail
	      </FONT>
	     </TH><TH WIDTH="50%" BGCOLOR="[selected_color]">
	      <FONT COLOR="[bg_color]">
	        Modificar su contraseña
	      </FONT>
	     </TH>
            </TR>
           </TABLE>
         </TH>
      </TR>
      <TR VALIGN="top">
        <TD>
   	    <FORM ACTION="[path_cgi]" METHOD=POST>
	    <INPUT TYPE="hidden" NAME="previous_action" VALUE="[previous_action]">
	    <INPUT TYPE="hidden" NAME="previous_list" VALUE="[previous_list]">
	    <BR><BR><BR><FONT COLOR="[dark_color]">Nuevo E-mail : </FONT>
	    <BR>&nbsp;&nbsp;&nbsp;<INPUT NAME="email" SIZE=15>
	    <BR><BR><BR><INPUT TYPE="submit" NAME="action_change_email" VALUE="Aceptar">
	    </FORM>
	</TD>
	<TD>
	  <FORM ACTION="[path_cgi]" METHOD=POST>
	    <INPUT TYPE="hidden" NAME="previous_action" VALUE="[previous_action]">
	    <INPUT TYPE="hidden" NAME="previous_list" VALUE="[previous_list]">
	    <BR><BR><BR><FONT COLOR="[dark_color]">Nueva contraseña : </FONT>
	    <BR>&nbsp;&nbsp;&nbsp;<INPUT TYPE="password" NAME="newpasswd1" SIZE=15>
	    <BR><FONT COLOR="[dark_color]">Repita la contraseña : </FONT>
	    <BR>&nbsp;&nbsp;&nbsp;<INPUT TYPE="password" NAME="newpasswd2" SIZE=15>
	    <BR><BR><BR><INPUT TYPE="submit" NAME="action_setpasswd" VALUE="Aceptar">
	    </FORM>
	</TD>
      </TR>


    </TABLE>

<!-- end prefs.es.tpl -->
