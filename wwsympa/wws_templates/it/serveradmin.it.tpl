<!-- RCS Identication ; $Revision$ ; $Date$ -->

    <TABLE WIDTH="100%" BORDER=0 CELLPADDING=10>
      <TR VALIGN="top">
        <TD NOWRAP>
	  <FORM ACTION="[path_cgi]" METHOD=POST>
	    <FONT COLOR="[dark_color]"><B>Settaggi di default per le liste</B></FONT><BR>
	     <SELECT NAME="file">
	      [FOREACH f IN lists_default_files]
	        <OPTION VALUE='[f->NAME]' [f->selected]>[f->complete]
	      [END]
	    </SELECT>
	    <INPUT TYPE="submit" NAME="action_editfile" VALUE="Edit">
	  </FORM>

	  <FORM ACTION="[path_cgi]" METHOD=POST>
	    <FONT COLOR="[dark_color]"><B>Settaggio dei template</B></FONT><BR>
	     <SELECT NAME="file">
	      [FOREACH f IN server_files]
	        <OPTION VALUE='[f->NAME]' [f->selected]>[f->complete]
	      [END]
	    </SELECT>
	    <INPUT TYPE="submit" NAME="action_editfile" VALUE="Edit">
	  </FORM>
	</TD>
      </TR>
      <TR><TD><A HREF="[path_cgi]/get_pending_lists"><B>Liste in attesa di approvazione o rigetto</B></A></TD></TR>
      <TR><TD><A HREF="[path_cgi]/view_translations"><B>Modifica dei template</B></A></TD></TR>
      <TR>
        <TD>
          <FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="submit" NAME="action_rebuildallarc" VALUE="Ricostruzione di tutti gli archivi"><BR>
	ATTENZIONE: Potrebbe richiedere molto tempo!
          </FORM>
	</TD>
      </TR>

      <TR>
        <TD>
	  <FONT COLOR="[dark_color]">
	  <A HREF="[path_cgi]/scenario_test">
	     <b>Modulo di test degli scenari</b>
          </A>
          </FONT>
	</TD>
      </TR>
	
    </TABLE>


