<!-- RCS Identication ; $Revision$ ; $Date$ -->

    <TABLE WIDTH="100%" BORDER=0 CELLPADDING=10>
      <TR VALIGN="top">
        <TD NOWRAP>
	  <FORM ACTION="[path_cgi]" METHOD=POST>
	    <FONT COLOR="--DARK_COLOR--"><B>Setting defaults list templates</B></FONT><BR>
	     <SELECT NAME="file">
	      [FOREACH f IN lists_default_files]
	        <OPTION VALUE='[f->NAME]' [f->selected]>[f->complete]
	      [END]
	    </SELECT>
	    <INPUT TYPE="submit" NAME="action_editfile" VALUE="Edit">
	  </FORM>

	  <FORM ACTION="[path_cgi]" METHOD=POST>
	    <FONT COLOR="--DARK_COLOR--"><B>Setting site templates</B></FONT><BR>
	     <SELECT NAME="file">
	      [FOREACH f IN server_files]
	        <OPTION VALUE='[f->NAME]' [f->selected]>[f->complete]
	      [END]
	    </SELECT>
	    <INPUT TYPE="submit" NAME="action_editfile" VALUE="Edit">
	  </FORM>
	</TD>
      </TR>
      <TR><TD><A HREF="[path_cgi]/get_pending_lists"><B>Pending lists</B></A></TD></TR>

      <TR><TD NOWRAP>
        <FORM ACTION="[path_cgi]" METHOD="POST">
	  <INPUT NAME="email" SIZE="30" VALUE="[email]">
	  <INPUT TYPE="submit" NAME="action_search_user" VALUE="Search User">
	</FORM>     
      </TD></TR>

      <TR><TD><A HREF="[path_cgi]/view_translations"><B>Customize templates</B></A></TD></TR>
      <TR>
        <TD>
<FONT COLOR="--DARK_COLOR--"><B>Rebuild HTML archives</B> using <CODE>arctxt</CODE> directories as input.
        </TD>
      </TR>
      <TR>
        <TD>
          <FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="submit" NAME="action_rebuildallarc" VALUE="ALL"><BR>
	May take a lot of time CPU,  be carefull !
          </FORM>
	</TD>

    <TD ALIGN="CENTER"> 
          <FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="text" NAME="list" SIZE="20">
          <INPUT TYPE="submit" NAME="action_rebuildarc" VALUE="Rebuild archive">
          </FORM>
    </TD>


      </TR>

      <TR>
        <TD>
	  <FONT COLOR="--DARK_COLOR--">
	  <A HREF="[path_cgi]/scenario_test">
	     <b>Scenari test module</b>
          </A>
          </FONT>
	</TD>
      </TR>
	
    </TABLE>


