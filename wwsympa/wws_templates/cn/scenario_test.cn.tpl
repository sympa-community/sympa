
<FORM ACTION="[path_cgi]" METHOD=POST>
    <INPUT TYPE=HIDDEN NAME="action" value="scenario_test">
    <center>
    <TABLE BORDER=0 CELLPADDING=10>
      <TR VALIGN="top">
        <TD COLSPAN=2 NOWRAP>
    	<FONT COLOR="--DARK_COLOR--"><CENTER><B>情景测试模块</b></CENTER></FONT><BR>
        </TD>
      </TR>
      <TR>
        <TD>情景名</TD>
        <TD>
	  <SELECT NAME="scenario">
	      [FOREACH sc IN scenario]
	        <OPTION VALUE="[sc->NAME]" [sc->selected]>[sc->NAME]
	      [END]
	  </SELECT>
        </TD>
    </TR>
    <TR>
        <TD>邮递表名</TD>

        <TD>
	  <SELECT NAME="listname">
	      [FOREACH l IN listname]
	        <OPTION VALUE="[l->NAME]"[l->selected] >[l->NAME]
	      [END]
	  </SELECT>
        </TD>
    </TR>
    <TR>
        <TD>发件人邮件</TD>
        <TD>
          <INPUT TYPE="text" NAME="sender" SIZE="20" value="[sender]">
        </TD>
    </TR>
    <TR>
        <TD>关联邮件</TD>
        <TD>
          <INPUT TYPE="text" NAME="email" SIZE="20" value="[email]">
        </TD>
    </TR>
    <TR>
        <TD>远程地址</TD>
        <TD>
          <INPUT TYPE="text" NAME="remote_addr" SIZE="16" value="[remote_addr]">
        </TD>
    </TR>
    <TR>
        <TD>远程主机</TD>	
        <TD>
          <INPUT TYPE="text" NAME="remote_host" SIZE="16" value="[remote_host]">
        </TD>
    </TR>
    <TR>
        <TD>验证模式</TD>
        <TD>
          <SELECT NAME="auth_method">
              [FOREACH a IN auth_method]
	        <OPTION VALUE="[a->NAME]"[a->selected] >[a->NAME]
	      [END] 
	  </SELECT>
        </TD>
    </TR>
    <TR>

	<TD><INPUT TYPE="submit" NAME="action_scenario_test" VALUE="获取应用的规则"></TD>
        <TD bgcolor="--DARK_COLOR--">
          [IF scenario_action]
             <code>[scenario_condition], [scenario_auth_method] -> [scenario_action]</code>
          [ELSE]
          <center>-</center>
          [ENDIF]
        </TD>

      </TR>

    </TABLE>
    </FORM>












