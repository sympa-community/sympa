You can translate the <B>[template]</B> web template bellow.<BR>
You also view the sentences in the page context <A HREF="[path_cgi]/view_template/[template]/[lang]">here</A> .<BR><BR>
Be carefull : do not alter HTML tags(&lt;tag&gt;) or Sympa parser tags ([ var ]) while translating.<BR><BR>

 <FORM ACTION="[path_cgi]" METHOD="POST">
     <INPUT TYPE="hidden" NAME="lang" VALUE="[lang]">
     <INPUT TYPE="hidden" NAME="template" VALUE="[template]">

<TABLE><TR>
<TH>ID</TH>
<TH>default / translation</TH></TR>
[FOREACH t IN trans]
<TR>
<TD>[t->NAME]</TD>
<TD>[t->default]</TD></TR>
<TR><TD>&nbsp;</TD><TD><INPUT SIZE="80" NAME="trans[t->NAME]" VALUE="[t->translation]"></TD>
</TR>
[END]     
</TABLE>

   <INPUT TYPE="submit" NAME="action_update_translation" VALUE="Update translations">

 </FORM>
