<!-- RCS Identication ; $Revision$ ; $Date$ -->

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>

<!-- comment -->
<HEAD>
<SCRIPT LANGUAGE="JavaScript">
<!-- for other browsers

  // To confirm a form submition
  function request_confirm(my_form, my_message, my_action){
    if (window.confirm(my_message)) {
      my_form.action.value = my_action;
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
      url = '[path_cgi]/'
    }

    window.opener.location = url
    self.close()
  }

[IF cookie_set]
  function GetCookie (name) {
     var arg = name + "=";
     var alen = arg.length;
     var clen = document.cookie.length;
     var i = 0;
     while (i < clen) {
       var j = i + alen;
       if (document.cookie.substring(i, j) == arg)
         return getCookieVal (j);
         i = document.cookie.indexOf(" ", i) + 1;
         if (i == 0) break; 
       }
     return null;
  }  

  function getCookieVal (offset) {
    var endstr = document.cookie.indexOf (";", offset);
    if (endstr == -1)
      endstr = document.cookie.length;
    return unescape(document.cookie.substring(offset, endstr));
  }

  function check_cookie() {
 
     if (GetCookie('sympauser') == null) {
        alert("Sympa could not set a cookie for login.\n Your should setup your navigator to accept cookies");
     }
  }
[ENDIF]

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

<BODY bgcolor="[bg_color]" text="[text_color]" link="[selected_color]" vlink="[selected_color]" 
onLoad="
[IF cookie_set]
check_cookie(); 
[ENDIF]
[IF back_to_mom]
setTimeout('refresh_mom_and_die()',1000);
[ENDIF]
">

[IF nomenu]
    [IF errors]
          <TABLE>
          <TR BGCOLOR="[error_color]">
            <TD>
              <FONT COLOR="[bg_color]">
       [PARSE error_template]
       </FONT>
            </TD>
          </TR>
          </TABLE>
    [ENDIF]
    [IF notices]
          <TABLE>
          <TR BGCOLOR="[shaded_color]">
            <TD>
              <FONT COLOR="[text_color]">
       [PARSE notice_template]
       </FONT>
            </TD>
          </TR>
          </TABLE>
    [ENDIF]

  [PARSE title_template]
  <BR>
  [PARSE action_template]

     <FORM ACTION="[path_cgi]" METHOD="POST">
     <INPUT TYPE="hidden" NAME="action" VALUE="set_lang">
     <INPUT TYPE="hidden" NAME="previous_action" VALUE="[action]">
     <INPUT TYPE="hidden" NAME="previous_list" VALUE="[list]">
     <SELECT NAME="lang" onchange="this.form.submit();">

     [FOREACH lang IN  languages]
     <OPTION VALUE="[lang->NAME]" [lang->selected]>[lang->complete]
     [END]
     </SELECT>
     </FORM>

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
        <TR BGCOLOR="[error_color]">
          <TD>
            <FONT COLOR="[bg_color]">
	    [PARSE error_template]
	    </FONT>
          </TD>
        </TR>
       </TABLE>
     [ENDIF]
     [IF notices]
       <TABLE>
        <TR BGCOLOR="[shaded_color]">
          <TD>
           <FONT COLOR="[text_color]">
	   [PARSE notice_template]
	   </FONT>
          </TD>
        </TR>
       </TABLE>
     [ENDIF]

   <TABLE BORDER="0" WIDTH="100%"  CELLPADDING="0" CELLSPACING="1" VALIGN="top"><TR><TD BGCOLOR="[dark_color]"><TABLE BORDER="0" WIDTH="100%"  CELLPADDING="1" CELLSPACING="1" VALIGN="top">

    [IF action_type=admin]
      <TR VALIGN="top">
       [PARSE admin_menu_template]
      </TR>
      <TR VALIGN="top">
        <TD colspan="7" BGCOLOR="[shaded_color]" >
         [IF active]
          [PARSE action_template]
         [ENDIF]
        </TD>
      </TR>
	  
    [ELSE]
      <TR VALIGN="top"><TD BGCOLOR="[shaded_color]">
        [IF active]
         [PARSE action_template]
        [ENDIF]
      </TD>
      </TR>
    [ENDIF]
   </TABLE></TD></TR></TABLE>

  </TD>
  </TR>
 </TABLE>
 <TABLE BORDER="0" ALIGN="right">
  <TR>
   <TD ALIGN="left">
     <FORM ACTION="[path_cgi]" METHOD="POST">
     <INPUT TYPE="hidden" NAME="action" VALUE="set_lang">
     <INPUT TYPE="hidden" NAME="previous_action" VALUE="[action]">
     <INPUT TYPE="hidden" NAME="previous_list" VALUE="[list]">
     <SELECT NAME="lang" onchange="this.form.submit();">

     [FOREACH lang IN  languages]
     <OPTION VALUE="[lang->NAME]" [lang->selected]>[lang->complete]
     [END]
     </SELECT>
     </FORM>
   </TD> 
   <TD WIDTH="100%">&nbsp;</TD>
    <TD NOWRAP><I>Powered by</I></TD>
    <TD><A HREF="http://www.sympa.org/">
         [IF auth_method=smime]
           <IMG SRC="[icons_url]/logo-s-lock.png" ALT="Sympa [version]" BORDER="0" >
         [ELSE]
           <IMG SRC="[icons_url]/logo-s.png" ALT="Sympa [version]" BORDER="0" >
         [ENDIF]
         </A></TD>
   </TR>
  </TABLE>
[ENDIF]

</BODY>
</HTML>

