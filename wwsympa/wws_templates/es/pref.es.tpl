<!-- RCS Identication ; $Revision$ ; $Date$ -->


    <TABLE WIDTH="100%" CELLPADDING="1" CELLSPACING="0">
      <TR VALIGN="top">
        <TH BGCOLOR="--DARK_COLOR--" COLSPAN="2">
          <TABLE WIDTH="100%" CELLPADDING="0" CELLSPACING="0">
            <TR>
             <TH BGCOLOR="--SELECTED_COLOR--" WIDTH="50%">
	      <FONT COLOR="--BG_COLOR--">
	        Su entorno
	      </FONT>
	     </TH><TH WIDTH="50%" BGCOLOR="--SELECTED_COLOR--">
	      <FONT COLOR="--BG_COLOR--">
	        Cambiar su contraseña
	      </FONT>
	     </TH>
            </TR>
           </TABLE>
         </TH>
      </TR>
      <TR VALIGN="top">
	<TD>
	  <FORM ACTION="[path_cgi]" METHOD=POST>
  	    <FONT COLOR="--DARK_COLOR--">E-mail </FONT> [user->email]<BR><BR>
	    <FONT COLOR="--DARK_COLOR--">Nombre</FONT> 
	    <INPUT TYPE="text" NAME="gecos" SIZE=20 VALUE="[user->gecos]"><BR><BR> 
	    <FONT COLOR="--DARK_COLOR--">Idioma </FONT>
	    <SELECT NAME="lang">
	      [FOREACH l IN languages]
	        <OPTION VALUE='[l->NAME]' [l->selected]>[l->complete]
	      [END]
	    </SELECT>
	    <BR><BR>
	    <FONT COLOR="--DARK_COLOR--">Duración de su conexión </FONT>
	    <INPUT TYPE="text" NAME="cookie_delay" SIZE=3 VALUE="[user->cookie_delay]"> min<BR><BR>
	    <INPUT TYPE="submit" NAME="action_setpref" VALUE="Aceptar"></FONT>
	  </FORM>
	</TD>
	<TD>
	  <FORM ACTION="[path_cgi]" METHOD=POST>
	    <BR><BR><BR><FONT COLOR="--DARK_COLOR--">Nueva contraseña: </FONT>
	    <BR>&nbsp;&nbsp;&nbsp;<INPUT TYPE="password" NAME="newpasswd1" SIZE=15>
	    <BR><FONT COLOR="--DARK_COLOR--">Entre de nuevo su nueva contraseña: </FONT>
	    <BR>&nbsp;&nbsp;&nbsp;<INPUT TYPE="password" NAME="newpasswd2" SIZE=15>
	    <BR><BR><BR><INPUT TYPE="submit" NAME="action_setpasswd" VALUE="Aceptar">
	    </FORM>
	</TD>
      </TR>
    </TABLE>
