<!-- RCS Identication ; $Revision$ ; $Date$ -->

  <FORM ACTION="[path_cgi]" METHOD=POST>
  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
<TABLE>
<TR BGCOLOR="[bg_color]"><TD>
        <INPUT TYPE="submit" NAME="action_distribute" VALUE="Trimite mai departe">
        <INPUT TYPE="submit" NAME="action_reject.quiet" VALUE="Respinge">
        <INPUT TYPE="submit" NAME="action_reject" VALUE="respingere cu notificare">
</TD></TR></TABLE>  
    <TABLE BORDER="1" WIDTH="100%">
      <TR BGCOLOR="[dark_color]">
	<TH><FONT COLOR="[bg_color]">X</FONT></TH>
        
      <TH><FONT COLOR="[bg_color]">Data</FONT></TH>
	  <TH><FONT COLOR="[bg_color]">Autor</FONT></TH>
	  <TH><FONT COLOR="[bg_color]">Subiect</FONT></TH>
	  <TH><FONT COLOR="[bg_color]">Marime</FONT></TH>
      </TR>	 
      [FOREACH msg IN spool]
        <TR>
         <TD>
            <INPUT TYPE=checkbox name="id" value="[msg->NAME]">
	 </TD>
	  <TD>
	    [IF msg->date]
	      <FONT SIZE=-1>[msg->date]</FONT>
	    [ELSE]
	      &nbsp;
	    [ENDIF]
	  </TD>
	  <TD><FONT SIZE=-1>[msg->from]</FONT></TD>
	  <TD>
	    [IF msg->subject=no_subject]
	      <A HREF="[path_cgi]/viewmod/[list]/[msg->NAME]"><FONT SIZE=-1>No subject</FONT></A>
	    [ELSE]
	      <A HREF="[path_cgi]/viewmod/[list]/[msg->NAME]"><FONT SIZE=-1>[msg->subject]</FONT></A>
	    [ENDIF]
	  </TD>
	  <TD><FONT SIZE=-1>[msg->size] kb</FONT></TD>
	</TR>
      [END] 
    </TABLE>
<TABLE>
<TR BGCOLOR="[bg_color]"><TD>
        <INPUT TYPE="submit" NAME="action_distribute" VALUE="Accepta">
        <INPUT TYPE="submit" NAME="action_reject.quiet" VALUE="Respinge">
        <INPUT TYPE="submit" NAME="action_reject" VALUE="respingere cu notificare">
</TD></TR></TABLE>
</FORM>












