<!-- RCS Identication ; $Revision$ ; $Date$ -->
<!-- begin list_menu.tpl -->
<TABLE border="0"  CELLPADDING="0" CELLSPACING="0">
 <TR VALIGN="top"><!-- empty line in the left menu panel -->
  <TD WIDTH="5" BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH="40" BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH="30" ></TD>
  <TD WIDTH="40" ></TD>
 </TR>
 <TR>
  <TD WIDTH="5" BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>

<!-- begin -->
  <TD WIDTH="70" COLSPAN="2" NOWRAP align=right>
   <TABLE  WIDTH="100%" BORDER="0" CELLPADDING="1" CELLSPACING="2">
    <TR>
     <TD BGCOLOR="[dark_color]" VALIGN="top">
      <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
       <TR>

      [IF action=info]
        <TD WIDTH=100% BGCOLOR="[selected_color]" NOWRAP align=right>
           <font color="[bg_color]" size=-1><b>邮递表信息</b></font>
        </TD>
      [ELSE]
        <TD WIDTH=100% BGCOLOR="[light_color]" NOWRAP align=right>
        <A HREF="[path_cgi]/info/[list]" ><font size=-1><b>邮递表信息</b>
        </font></A>
        </TD>
      [ENDIF]

       </TR>
      </TABLE>
     </TD>
    </TR>
   </TABLE>
  </TD>


  <TD WIDTH=40></TD>
 </TR>
 <TR><!-- empty line in the left menu panel -->
  <TD WIDTH=45 COLSPAN=2 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH=70 COLSPAN=2><BR></TD>
 </TR>
 <TR><!-- Panel list info -->
  <TD WIDTH=5 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH=110 COLSPAN=3 BGCOLOR="[bg_color]" NOWRAP align=left>
   <TABLE  WIDTH="100%" BORDER="0" CELLPADDING="1" CELLSPACING="2">
    <TR>
     <TD BGCOLOR="[dark_color]" VALIGN="top">
      <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
       <TR>
        <TD BGCOLOR="[light_color]">
	  订阅者: <B>共[total]人</B><BR>
	  <BR>
	  所有者:
	  [FOREACH o IN owner]
	    <BR><FONT SIZE=-1><A HREF="mailto:[o->NAME]">[o->gecos]</A></FONT>
	  [END]
	  <BR>
	  [IF is_moderated]
	    监管者:
	    [FOREACH e IN editor]
	      <BR><FONT SIZE=-1><A HREF="mailto:[e->NAME]">[e->gecos]</A></FONT>
	    [END]
	  [ENDIF]
          <BR>
	  [IF list_as_x509_cert]
          <BR><A HREF="[path_cgi]/load_cert/[list]"><font size="-1"><b>载入证书<b></font></A><BR>
          [ENDIF]
        </TD>
       </TR>
      </TABLE>
     </TD>
    </TR>
   </TABLE>
  </TD>
 </TR>
 <TR><!-- empty line in the left menu panel -->
  <TD WIDTH=45 COLSPAN=2 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH=70 COLSPAN=2><BR></TD>
 </TR>
   [IF is_priv]
 <TR><!-- for listmaster owner and editor -->
  <TD WIDTH=5 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>

  <TD WIDTH="70" COLSPAN="2" NOWRAP align=right>
   <TABLE  WIDTH="100%" BORDER="0" CELLPADDING="1" CELLSPACING="2">
    <TR>
     <TD BGCOLOR="[dark_color]" VALIGN="top">
      <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
       <TR>

   [IF action=admin]
        <TD WIDTH="100%" BGCOLOR="[selected_color]" NOWRAP align=right><font color="[bg_color]" size=-1><b>邮递表管理</b></font></TD>
   [ELSIF action_type=admin]
        <TD WIDTH="100%" BGCOLOR="[selected_color]" NOWRAP align=right>
        <b>
         <A HREF="[path_cgi]/admin/[list]" ><FONT COLOR="[bg_color]" SIZE="-1">邮递表管理</FONT></A>
        </b>
        </TD>
   [ELSE]
        <TD WIDTH="100%" BGCOLOR="[light_color]" NOWRAP align=right>
        <font size=-1><b>
         <A HREF="[path_cgi]/admin/[list]" >邮递表管理</A>
        </b></font>
        </TD>
   [ENDIF]

       </TR>
      </TABLE>
     </TD>
    </TR>
   </TABLE>
  </TD>

  <TD WIDTH=40></TD>
 </TR>
 <TR>
  <TD WIDTH=45 COLSPAN=2 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH=70 COLSPAN=2><BR></TD>
 </TR>
 <TR><!-- Panel admin info -->
  <TD WIDTH=5 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH=110 COLSPAN=3 BGCOLOR="[bg_color]" NOWRAP align=left>
   <TABLE  WIDTH="100%" BORDER="0" CELLPADDING="1" CELLSPACING="2">
    <TR>
     <TD BGCOLOR="[dark_color]" VALIGN="top">
      <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
       <TR>
        <TD BGCOLOR="[light_color]">
	   退信率: <B>[bounce_rate]%</B><BR>
           <BR>
	   [if mod_total=0]
	   没有邮件要监管
           [else]
           要监管的邮件:<B> 共 [mod_total]</B>
           [endif]
	  <BR>
        </TD>
       </TR>
      </TABLE>
     </TD>
    </TR>
   </TABLE>
  </TD>
 </TR>
 <TR>
  <TD WIDTH=45 COLSPAN=2 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH=70 COLSPAN=2><BR></TD>
 </TR>


     <!-- end is_priv -->
   [ENDIF]
   <!-- Subscription depending on susbscriber or not, email define or not etc -->
   [IF is_subscriber=1]
 <TR>
  <TD WIDTH=5 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>

  <TD WIDTH="70" COLSPAN="2" NOWRAP align=right>
   <TABLE  WIDTH="100%" BORDER="0" CELLPADDING="1" CELLSPACING="2">
    <TR>
     <TD BGCOLOR="[dark_color]" VALIGN="top">
      <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
       <TR>
      [IF action=suboptions]
        <TD WIDTH="100%" BGCOLOR="[selected_color]" NOWRAP align=right><font color="[bg_color]" size=-1><b>订阅者选项</b></font></TD>
      [ELSE]
        <TD WIDTH="100%" BGCOLOR="[light_color]" NOWRAP align=right>
        <font size=-1><b>
         <A HREF="[path_cgi]/suboptions/[list]" >订阅者选项</A>
        </b></font>
        </TD>
      [ENDIF]
       </TR>
      </TABLE>
     </TD>
    </TR>
   </TABLE>
  </TD>

  <TD WIDTH=40>
  </TD>
 </TR>
 <TR>
  <TD WIDTH=45 COLSPAN=2 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH=70 COLSPAN=2><BR></TD>
 </TR>
   [IF may_subscribe<>1]
        <!-- Should we print something in case subscription is closed ?? ->
        <!-- END may subscribe -->     
   [ENDIF] 
   [IF may_signoff=1] 
 <TR>
  <TD WIDTH=5 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH="70" COLSPAN="2" NOWRAP align=right>
   <TABLE  WIDTH="100%" BORDER="0" CELLPADDING="1" CELLSPACING="2">
    <TR>
     <TD BGCOLOR="[dark_color]" VALIGN="top">
      <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
       <TR>
      [IF action=signoff]
        <TD WIDTH="100%" BGCOLOR="[selected_color]" NOWRAP align=right><font color="[bg_color]" size=-1><b>退订</b></font></TD>
      [ELSE]
        <TD WIDTH="100%" BGCOLOR="[light_color]" NOWRAP align=right>
        <font size=-1><b>
         <A HREF="[path_cgi]/signoff/[list]" onClick="request_confirm_link('[path_cgi]/signoff/[list]', '您确定要退订邮递表 [list]?'); return false;">退订</A>
        </b></font>
        </TD>
      [ENDIF]

       </TR>
      </TABLE>
     </TD>
    </TR>
   </TABLE>
  </TD>

  <TD WIDTH=40></TD>
 </TR>
   [ELSE]
 <TR>
  <TD WIDTH=5 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH="70" COLSPAN="2" NOWRAP align=right>
   <TABLE  WIDTH="100%" BORDER="0" CELLPADDING="1" CELLSPACING="2">
    <TR>
     <TD BGCOLOR="[dark_color]" VALIGN="top">
      <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
       <TR>
        <TD WIDTH="100%" BGCOLOR="[light_color]" NOWRAP align=right>
        <font size=-1 COLOR="[bg_color]"><b>退订</b></font>
        </TD>
        <TD WIDTH=40></TD>
       </TR>
      </TABLE>
     </TD>
    </TR>
   </TABLE>
  </TD>
 </TR>
      <!-- end may_signoff -->
   [ENDIF]
      <!-- is_subscriber -->

   [ELSE]
      <!-- else is_subscriber -->

 <TR>
  <TD WIDTH=5 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH="70" COLSPAN="2" NOWRAP align=right>
   <TABLE  WIDTH="100%" BORDER="0" CELLPADDING="1" CELLSPACING="2">
    <TR>
     <TD BGCOLOR="[dark_color]" VALIGN="top">
      <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
       <TR>
   [IF action=subrequest]
        <TD WIDTH="100%" BGCOLOR="[selected_color]" NOWRAP align=right><font color="[bg_color]" size=-1><b>订阅</b></font></TD>
   [ELSE]
        <TD WIDTH="100%" BGCOLOR="[light_color]" NOWRAP align=right>
   [IF may_subscribe=1]
        <font size=-1><b>
     <A HREF="[path_cgi]/subscribe/[list]" onClick="request_confirm_link('[path_cgi]/subscribe/[list]', '您确定要订阅邮递表 [list]?'); return false;">订阅</A>
        </b></font>
   [ELSE]
	<font size=-1 COLOR="[bg_color]"><b>订阅</b></font>
   [ENDIF]
        </TD>
   [ENDIF]

       </TR>
      </TABLE>
     </TD>
    </TR>
   </TABLE>
  </TD>

  <TD WIDTH=40></TD>
 </TR>

   [IF may_signoff]
 <TR>
  <TD WIDTH=45 COLSPAN=2 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH=70 COLSPAN=2><BR></TD>
 </TR>
 <TR>
  <TD WIDTH=5 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH="70" COLSPAN="2" NOWRAP align=right>
   <TABLE  WIDTH="100%" BORDER="0" CELLPADDING="1" CELLSPACING="2">
    <TR>
     <TD BGCOLOR="[dark_color]" VALIGN="top">
      <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
       <TR>

        <TD WIDTH="100%" BGCOLOR="[light_color]" NOWRAP align=right>
        <font size=-1><b>
         <A HREF="[path_cgi]/signoff/[list]" onClick="request_confirm_link('[path_cgi]/signoff/[list]', '您确定要退订邮递表 [list]?'); return false;">退订</A>
        </b></font>
        </TD>
       </TR>
      </TABLE>
     </TD>
    </TR>
   </TABLE>
  </TD>

  <TD WIDTH=40></TD>
 </TR>
   [ENDIF]

      <!-- END is_subscriber -->
   [ENDIF]
 <TR>
  <TD WIDTH=45 COLSPAN=2 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH=70 COLSPAN=2><BR></TD>
 </TR>
   [IF is_archived]
 <TR>
  <TD WIDTH=5 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH="70" COLSPAN="2" NOWRAP align=right>
   <TABLE  WIDTH="100%" BORDER="0" CELLPADDING="1" CELLSPACING="2">
    <TR>
     <TD BGCOLOR="[dark_color]" VALIGN="top">
      <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
       <TR>
   [IF action=arc]
        <TD WIDTH="100%" BGCOLOR="[selected_color]" NOWRAP align=right>
          <font size=-1 COLOR="[bg_color]"><b>归档</b></font>
	</TD>
   [ELSIF action=arcsearch_form]
        <TD WIDTH="100%" BGCOLOR="[selected_color]" NOWRAP align=right>
          <font size=-1 COLOR="[bg_color]"><b>归档</b></font>
	</TD>
   [ELSIF action=arcsearch]
        <TD WIDTH="100%" BGCOLOR="[selected_color]" NOWRAP align=right>
          <font size=-1 COLOR="[bg_color]"><b>归档</b></font>
	</TD>
   [ELSIF action=arc_protect]
        <TD WIDTH="100%" BGCOLOR="[selected_color]" NOWRAP align=right>
          <font size=-1 COLOR="[bg_color]"><b>归档</b></font>
	</TD>
  [ELSE]

        <TD WIDTH="100%" BGCOLOR="[light_color]" NOWRAP align=right>
   [IF arc_access]
        <font size=-1><b>
         <A HREF="[path_cgi]/arc/[list]" >归档</A>
        </b></font>
   [ELSE]
        <font size=-1 COLOR="[bg_color]"><b>归档</b></font>
   [ENDIF]
        </TD>
   [ENDIF]

       </TR>
      </TABLE>
     </TD>
    </TR>
   </TABLE>
  </TD>

  <TD WIDTH=40></TD>
 </TR>
 <TR>
  <TD WIDTH=45 COLSPAN=2 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH=70 COLSPAN=2><BR></TD>
 </TR>
      <!-- END is_archived -->
    [ENDIF]

    [IF shared=exist]
 <TR>
  <TD WIDTH=5 BGCOLOR="[dark_color]" NOWRAP>&nbsp; </TD>   
  <TD WIDTH="70" COLSPAN="2" NOWRAP align=right>
   <TABLE  WIDTH="100%" BORDER="0" CELLPADDING="1" CELLSPACING="2">
    <TR>
     <TD BGCOLOR="[dark_color]" VALIGN="top">
      <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
       <TR>
    [IF action=d_read]
        <TD WIDTH="100%" BGCOLOR="[selected_color]" NOWRAP align=right><font color="[bg_color]" size=-1>
         <b>共享页面</b></font>
        </TD>
    [ELSE]
      [IF may_d_read]
        <TD WIDTH="100%" BGCOLOR="[light_color]" NOWRAP align=right>
         <font size=-1><b>
         <A HREF="[path_cgi]/d_read/[list]/" >共享页面</A>
         </b></font>
        </TD>
      [ELSE]
        <TD WIDTH="100%" BGCOLOR="[light_color]" NOWRAP align=right>
         <font size=-1 COLOR="[bg_color]"><b>共享页面</b></font>
        </TD>
      [ENDIF]
    [ENDIF]

       </TR>
      </TABLE>
     </TD>
    </TR>
   </TABLE>
  </TD>

       <!-- END shared --> 
  <TD WIDTH=40></TD>
 </TR> 
 <TR>
  <TD WIDTH=45 COLSPAN=2 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH=70 COLSPAN=2><BR></TD>
 </TR>
    [ENDIF]

    [IF may_review]
 <TR>
  <TD WIDTH=5 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH="70" COLSPAN="2" NOWRAP align=right>
   <TABLE  WIDTH="100%" BORDER="0" CELLPADDING="1" CELLSPACING="2">
    <TR>
     <TD BGCOLOR="[dark_color]" VALIGN="top">
      <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
       <TR>
        <TD WIDTH="100%" BGCOLOR="[light_color]" NOWRAP align=right>
         <font size=-1><b>
         <A HREF="[path_cgi]/review/[list]" >查看</A>
         </b></font>
	</TD>
       </TR>
      </TABLE>
     </TD>
    </TR>
   </TABLE>
  </TD>
  <TD WIDTH=40></TD>
 </TR>
 <TR>
  <TD WIDTH=45 COLSPAN=2 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH=70 COLSPAN=2><BR></TD>
 </TR>
    [ENDIF]
</TABLE>
<!-- end list_menu.tpl -->
