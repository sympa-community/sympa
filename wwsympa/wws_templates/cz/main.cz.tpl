<!-- RCS Identication ; $Revision$ ; $Date$ -->

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>

<!-- comment -->
<HEAD>
<SCRIPT LANGUAGE="JavaScript">
<!-- for other browsers

  // To confirm a form submition
  function request_confirm(my_form, my_message){
    if (window.confirm(my_message)) {
      my_form.submit();
    }
  }

  // To confirm on a link (A HREF)
  function request_confirm_link(my_url, my_message){
    question = confirm(my_message)
    if (question !="0"){
         top.location = my_url
    }
  }

  // To confirm on a link (A HREF)
  function refresh_mom_and_die(){
    url = window.opener.location.href

    if (url.indexOf('logout') > -1 ) {
      url = '[base_url][path_cgi]/'
    }

    window.opener.location = url
    self.close()
  }

  function toggle_selection(myfield) {
    for (i = 0; i < myfield.length; i++) {
    [STOPPARSE]
       if (myfield[i].checked) {
            myfield[i].checked = false;
       }else {
	    myfield[i].checked = true;
       }
    [STARTPARSE]
    }
  }
// end browsers -->
</SCRIPT>

<STYLE type="text/css" title="style sympa">
<!--
A {
	text-decoration: none;
}
-->
</STYLE>

  [IF base]
    <BASE HREF="[base]">
  [ENDIF]
  <TITLE>
    [title]
  </TITLE>
</HEAD>

<BODY bgcolor="#ffffff" text="#000000" link="#3366cc" vlink="#3366cc"
[IF back_to_mom]
onLoad="setTimeout('refresh_mom_and_die()',1000);"
[ENDIF]
>

[IF nomenu]
    [IF errors]
          <TABLE>
          <TR BGCOLOR="#ff6666">
            <TD>
              <FONT COLOR="#ffffff">
       [PARSE error_template]
       </FONT>
            </TD>
          </TR>
          </TABLE>
    [ENDIF]
    [IF notices]
          <TABLE>
          <TR BGCOLOR="#eeeeee">
            <TD>
              <FONT COLOR="#000000">
       [PARSE notice_template]
       </FONT>
            </TD>
          </TR>
          </TABLE>
    [ENDIF]

  [PARSE title_template]
  <BR>
  [PARSE action_template]
[ELSE]
  [PARSE menu_template]
  [PARSE title_template]
  <TABLE CELLSPACING=0 CELLPADDING=0 WIDTH="100%">
    <TR VALIGN="top">
      [IF list]
        <TD>
          [PARSE list_menu_template]
        </TD>
      [ENDIF]
        <TD WIDTH="100%">
      [IF errors]
            <TABLE>
            <TR BGCOLOR="#ff6666">
              <TD>
                <FONT COLOR="#ffffff">
	        [PARSE error_template]
	        </FONT>
              </TD>
            </TR>
            </TABLE>
      [ENDIF]
      [IF notices]
            <TABLE>
            <TR BGCOLOR="#eeeeee">
              <TD>
                <FONT COLOR="#000000">
	        [PARSE notice_template]
	        </FONT>
              </TD>
            </TR>
            </TABLE>
      [ENDIF]

            <TABLE BORDER="0" WIDTH="100%"  CELLPADDING="1" CELLSPACING="0" VALIGN="top"><TR><TD BGCOLOR="#330099">
            <TABLE BORDER="0" WIDTH="100%"  VALIGN="top">

      [IF action_type=admin]
            <TR VALIGN="top">
                [PARSE admin_menu_template]
            </TR>
            <TR VALIGN="top">
               <TD colspan="7" BGCOLOR="#ffffff" >
                 [IF active]
                   [PARSE action_template]
                 [ENDIF]
               </TD>
            </TR>
	  
          [ELSE]
            <TR VALIGN="top"><TD BGCOLOR="#ffffff">
            [IF active]
              [PARSE action_template]
            [ENDIF]
            </TD></TR>
          [ENDIF]
            </TABLE>
            </TD></TR></TABLE>

        </TD>
    </TR>
  </TABLE>
  <TABLE BORDER="0" ALIGN="right">
   <TR>
    <TD><I>Powered by</I></TD>
    <TD><A HREF="http://listes.cru.fr/sympa/">
            [IF auth_method=smime]
            <IMG SRC="[icons_url]/logo-s-lock.gif" ALT="Sympa [version]" BORDER="0" >
            [ELSE]
            <IMG SRC="[icons_url]/logo-s.gif" ALT="Sympa [version]" BORDER="0" >
            [ENDIF]
            </A></TD>
   </TR>
  </TABLE>
[ENDIF]

</BODY>
</HTML>

