<!-- RCS Identication ; $Revision$ ; $Date$ -->

    <TABLE WIDTH="100%" BORDER=0 CELLPADDING=10>
      <TR VALIGN="top">
        <TD NOWRAP>
	  <FORM ACTION="[path_cgi]" METHOD=POST>
	    <FONT COLOR="#330099"><B>Nastavení standardních ¹ablon konference</B></FONT><BR>
	     <SELECT NAME="file">
	      [FOREACH f IN lists_default_files]
	        <OPTION VALUE='[f->NAME]' [f->selected]>[f->complete]
	      [END]
	    </SELECT>
	    <INPUT TYPE="submit" NAME="action_editfile" VALUE="Upravit">
	  </FORM>

	  <FORM ACTION="[path_cgi]" METHOD=POST>
	    <FONT COLOR="#330099"><B>Nastavení ¹ablon serveru</B></FONT><BR>
	     <SELECT NAME="file">
	      [FOREACH f IN server_files]
	        <OPTION VALUE='[f->NAME]' [f->selected]>[f->complete]
	      [END]
	    </SELECT>
	    <INPUT TYPE="submit" NAME="action_editfile" VALUE="Upravit">
	  </FORM>
	</TD>
      </TR>
      <TR><TD><A HREF="[path_cgi]/get_pending_lists"><B>Èekající konference</B></A></TD></TR>

      <TR><TD NOWRAP>
        <FORM ACTION="[path_cgi]" METHOD="POST">
	  <INPUT NAME="email" SIZE="30" VALUE="[email]">
	  <INPUT TYPE="submit" NAME="action_search_user" VALUE="Najít u¾ivatele">
	</FORM>     
      </TD></TR>

      <TR><TD><A HREF="[path_cgi]/view_translations"><B>Upravit ¹ablony</B></A></TD></TR>
      <TR>
        <TD>
<FONT COLOR="#330099"><B>Znovu sestavit HTML archívy</B> pomocí <CODE>arctxt</CODE> adresáøe jako vstup.
        </TD>
      </TR>
      <TR>
        <TD>
          <FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="submit" NAME="action_rebuildallarc" VALUE="ALL"><BR>
	Opatrnì, vezme si hodnì strojového èasu!
          </FORM>
	</TD>

    <TD ALIGN="CENTER"> 
          <FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="text" NAME="list" SIZE="20">
          <INPUT TYPE="submit" NAME="action_rebuildarc" VALUE="Znovu sestavit archív">
          </FORM>
    </TD>


      </TR>

      <TR>
        <TD>
	  <FONT COLOR="#330099">
	  <A HREF="[path_cgi]/scenario_test">
	     <b>Modul testu scénáøe</b>
          </A>
          </FONT>
	</TD>
      </TR>
	
    </TABLE>
