<!-- RCS Identication ; $Revision$ ; $Date$ -->


<FORM ACTION="[path_cgi]" METHOD=POST>

<P>
<TABLE>
 <TR>
   <TD NOWRAP><B>邮递表名字:</B></TD>
   <TD><INPUT TYPE="text" NAME="listname" SIZE=30 VALUE="[saved->listname]"></TD>
   <TD><img src="/icons/unknown.png" alt="邮递表名；注意，不是它的地址!"></TD>
 </TR>
 
 <TR>
   <TD NOWRAP><B>所有者:</B></TD>
   <TD><I>[user->email]</I></TD>
   <TD><img src="/icons/unknown.png" alt="您是这个邮递表的特权所有者"></TD>
 </TR>

 <TR>
   <TD valign=top NOWRAP><B>邮递表类型: </B></TD>
   <TD>
     <MENU>
  [FOREACH template IN list_list_tpl]
     <INPUT TYPE="radio" NAME="template" Value="[template->NAME]"
     [IF template->selected]
       CHECKED
     [ENDIF]
     > [template->NAME]<BR>
     [PARSE template->comment]
     <BR>
  [END]
     </MENU>
    </TD>
    <TD valign=top><img src="/icons/unknown.png" alt="邮递表类型是参数集配置。可以在邮递表创建后编辑参数"></TD>
 </TR>
 <TR>
   <TD NOWRAP><B>主题:</B></TD>
   <TD><INPUT TYPE="text" NAME="subject" SIZE=60 VALUE="[saved->subject]"></TD>
   <TD><img src="/icons/unknown.png" alt="这是邮递表的主题"></TD>
 </TR>
 <TR>
   <TD NOWRAP><B>话题:</B></TD>
   <TD><SELECT NAME="topics">
	<OPTION VALUE="">--选择话题--
	[FOREACH topic IN list_of_topics]
	  <OPTION VALUE="[topic->NAME]"
	  [IF topic->selected]
	    SELECTED
	  [ENDIF]
	  >[topic->title]
	  [IF topic->sub]
	  [FOREACH subtopic IN topic->sub]
	     <OPTION VALUE="[topic->NAME]/[subtopic->NAME]">[topic->title] / [subtopic->title]
	  [END]
	  [ENDIF]
	[END]
     </SELECT>
   </TD>
   <TD valign=top><img src="/icons/unknown.png" alt="目录中的邮递表分类"></TD>
 </TR>

 <TR>
   <TD valign=top NOWRAP><B>描述:</B></TD>
   <TD><TEXTAREA COLS=60 ROWS=10 NAME="info">[saved->info]</TEXTAREA></TD>
   <TD valign=top><img src="/icons/unknown.png" alt="几行对邮递表的描述文字"></TD>
 </TR>

 <TR>
   <TD COLSPAN=2 ALIGN="center">
    <TABLE>
     <TR>
      <TD BGCOLOR="[light_color]">
<INPUT TYPE="submit" NAME="action_create_list" VALUE="提交您的创建请求">
      </TD>
     </TR></TABLE>
</TD></TR>
</TABLE>



</FORM>




