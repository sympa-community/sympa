<!-- RCS Identication ; $Revision$ ; $Date$ -->

 <FORM ACTION="[path_cgi]" METHOD=POST>
  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
  <INPUT TYPE="hidden" NAME="id" VALUE="[id]">
<TABLE>
<TR BGCOLOR="[bg_color]"><TD>
  <INPUT TYPE="submit" NAME="action_distribute" VALUE="分发">
  <INPUT TYPE="submit" NAME="action_reject.quiet" VALUE="拒绝">
  <INPUT TYPE="submit" NAME="action_reject" VALUE="拒绝并通知">
</TD></TR></TABLE>
</FORM>
[PARSE file]

