<!-- RCS Identication ; $Revision$ ; $Date$ -->

  <FORM ACTION="[path_cgi]" METHOD=POST>
  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
<TABLE>
<TR BGCOLOR="[bg_color]"><TD>
  <INPUT TYPE="submit" NAME="action_distribute" VALUE="分发">
  <INPUT TYPE="submit" NAME="action_reject.quiet" VALUE="拒绝">
  <INPUT TYPE="submit" NAME="action_reject" VALUE="拒绝并通知">
</TD></TR></TABLE>  
    <TABLE BORDER="1" WIDTH="100%">
      <TR BGCOLOR="[dark_color]">
	<TH><FONT COLOR="[bg_color]">X</FONT></TH>
        <TH><FONT COLOR="[bg_color]">日期</FONT></TH>
	<TH><FONT COLOR="[bg_color]">作者</FONT></TH>
	<TH><FONT COLOR="[bg_color]">标题</FONT></TH>
	<TH><FONT COLOR="[bg_color]">大小</FONT></TH>
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
	      <A HREF="[path_cgi]/viewmod/[list]/[msg->NAME]"><FONT SIZE=-1>没有标题</FONT></A>
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
  <INPUT TYPE="submit" NAME="action_distribute" VALUE="分发">
  <INPUT TYPE="submit" NAME="action_reject.quiet" VALUE="拒绝">
  <INPUT TYPE="submit" NAME="action_reject" VALUE="拒绝并通知">
</TD></TR></TABLE>
</FORM>












