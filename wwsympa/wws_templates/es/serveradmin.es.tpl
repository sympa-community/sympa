<!-- RCS Identication ; $Revision$ ; $Date$ -->

    <TABLE WIDTH="100%" BORDER=0 CELLPADDING=10>
      <TR VALIGN="top">
        <TD NOWRAP>
	  <FORM ACTION="[path_cgi]" METHOD=POST>
	    <FONT COLOR="[dark_color]"><B>Editar los "temas" de las listas por omisión</B></FONT><BR>
	     <SELECT NAME="file">
	      [FOREACH f IN lists_default_files]
	        <OPTION VALUE='[f->NAME]' [f->selected]>[f->complete]
	      [END]
	    </SELECT>
	    <INPUT TYPE="submit" NAME="action_editfile" VALUE="Editar">
	  </FORM>

	  <FORM ACTION="[path_cgi]" METHOD=POST>
	    <FONT COLOR="[dark_color]"><B>Editar los "temas" por omisión del servidor</B></FONT><BR>
	     <SELECT NAME="file">
	      [FOREACH f IN server_files]
	        <OPTION VALUE='[f->NAME]' [f->selected]>[f->complete]
	      [END]
	    </SELECT>
	    <INPUT TYPE="submit" NAME="action_editfile" VALUE="Editar">
	  </FORM>
	</TD>
      </TR>
      <TR><TD><A HREF="[path_cgi]/get_pending_lists"><B>Listas pendientes</B></A></TD></TR>
      <TR><TD><A HREF="[path_cgi]/view_translations"><B>Ver las traducciones de los "temas"</B></A></TD></TR>
      <TR>
        <TD>
<FONT COLOR="[dark_color]"><B>Reconstruir archivos HTML </B> usando los directorios <CODE>arctxt</CODE> como entrada.
        </TD>
      </TR>
      <TR>
        <TD>
          <FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="submit" NAME="action_rebuildallarc" VALUE="ALL"><BR>
	Puede consumir mucho tiempo de CPU, sea precavido !
          </FORM>
	</TD>

    <TD ALIGN="CENTER"> 
          <FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="text" NAME="list" SIZE="20">
          <INPUT TYPE="submit" NAME="action_rebuildarc" VALUE="Reconstruir archivo">
          </FORM>
    </TD>


      </TR>

      <TR>
        <TD>
	  <FONT COLOR="[dark_color]">
	  <A HREF="[path_cgi]/scenario_test">
	     <b>Módulo "Scenari" de test </b>
          </A>
          </FONT>
	</TD>
      </TR>
	
    </TABLE>


