<!-- RCS Identication ; $Revision$ ; $Date$ -->

    <TABLE WIDTH="100%" BORDER=0 CELLPADDING=10>
      <TR VALIGN="top">
        <TD NOWRAP>
	  <FORM ACTION="[path_cgi]" METHOD=POST>
	    <FONT COLOR="[dark_color]"><B>Standard-Listen-Templates setzen</B></FONT><BR>
	     <SELECT NAME="file">
	      [FOREACH f IN lists_default_files]
	        <OPTION VALUE='[f->NAME]' [f->selected]>[f->complete]
	      [END]
	    </SELECT>
	    <INPUT TYPE="submit" NAME="action_editfile" VALUE="Editieren">
	  </FORM>

	  <FORM ACTION="[path_cgi]" METHOD=POST>
	    <FONT COLOR="[dark_color]"><B>Listen-Templates f&uuml;r diese Maschine setzen</B></FONT><BR>
	     <SELECT NAME="file">
	      [FOREACH f IN server_files]
	        <OPTION VALUE='[f->NAME]' [f->selected]>[f->complete]
	      [END]
	    </SELECT>
	    <INPUT TYPE="submit" NAME="action_editfile" VALUE="Editieren">
	  </FORM>
	</TD>
      </TR>
      <TR><TD><A HREF="[path_cgi]/get_pending_lists"><B>Unbest&auml;tigte Listen</B></A></TD></TR>

      <TR><TD NOWRAP>
        <FORM ACTION="[path_cgi]" METHOD="POST">
	  <INPUT NAME="email" SIZE="30" VALUE="[email]">
	  <INPUT TYPE="submit" NAME="action_search_user" VALUE="Suche Benutzer">
	</FORM>     
      </TD></TR>

      <TR><TD><A HREF="[path_cgi]/view_translations"><B>Templates anpassen</B></A></TD></TR>
      <TR>
        <TD>
<FONT COLOR="[dark_color]"><B>Baue HTML-Archive neu auf</B> basierend auf <CODE>arctxt</CODE>-Verzeichnissen als Eingabe.
        </TD>
      </TR>
      <TR>
        <TD>
          <FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="submit" NAME="action_rebuildallarc" VALUE="ALLE"><BR>
	Achtung! Das kann viel Prozessorzeit kosten.
          </FORM>
	</TD>

    <TD ALIGN="CENTER"> 
          <FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="text" NAME="list" SIZE="20">
          <INPUT TYPE="submit" NAME="action_rebuildarc" VALUE="Archiv neu aufbauen">
          </FORM>
    </TD>


      </TR>

      <TR>
        <TD>
	  <FONT COLOR="[dark_color]">
	  <A HREF="[path_cgi]/scenario_test">
	     <b>Szenarien-Test-Modul</b>
          </A>
          </FONT>
	</TD>
      </TR>
	
    </TABLE>


