<!-- RCS Identication ; $Revision$ ; $Date$ -->

    <TABLE WIDTH="100%" BORDER=0 CELLPADDING=10>
      <TR VALIGN="top">
        <TD NOWRAP>
	  <FORM ACTION="[path_cgi]" METHOD=POST>
	    <FONT COLOR="--DARK_COLOR--"><B>设置默认邮递表模板</B></FONT><BR>
	     <SELECT NAME="file">
	      [FOREACH f IN lists_default_files]
	        <OPTION VALUE='[f->NAME]' [f->selected]>[f->complete]
	      [END]
	    </SELECT>
	    <INPUT TYPE="submit" NAME="action_editfile" VALUE="编辑">
	  </FORM>

	  <FORM ACTION="[path_cgi]" METHOD=POST>
	    <FONT COLOR="--DARK_COLOR--"><B>设置站点模板</B></FONT><BR>
	     <SELECT NAME="file">
	      [FOREACH f IN server_files]
	        <OPTION VALUE='[f->NAME]' [f->selected]>[f->complete]
	      [END]
	    </SELECT>
	    <INPUT TYPE="submit" NAME="action_editfile" VALUE="编辑">
	  </FORM>
	</TD>
      </TR>
      <TR><TD><A HREF="[path_cgi]/get_pending_lists"><B>待处理邮递表</B></A></TD></TR>
      <TR><TD><A HREF="[path_cgi]/view_translations"><B>定制模板</B></A></TD></TR>
      <TR>
        <TD>
<FONT COLOR="--DARK_COLOR--">使用<CODE>arctxt</CODE>目录作为输入<B>重建 HTML 归档</B>。
        </TD>
      </TR>
      <TR>
        <TD>
          <FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="submit" NAME="action_rebuildallarc" VALUE="全部"><BR>
	可能要占用很大的 CPU 时间，小心使用!
          </FORM>
	</TD>

    <TD ALIGN="CENTER"> 
          <FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="text" NAME="list" SIZE="20">
          <INPUT TYPE="submit" NAME="action_rebuildarc" VALUE="重建归档">
          </FORM>
    </TD>


      </TR>

      <TR>
        <TD>
	  <FONT COLOR="--DARK_COLOR--">
	  <A HREF="[path_cgi]/scenario_test">
	     <b>情景测试模块</b>
          </A>
          </FONT>
	</TD>
      </TR>
	
    </TABLE>


