<!-- RCS Identication ; $Revision$ ; $Date$ -->

<BR>
[IF password_sent]
  Ihr Passwort wurde an die EMail-Adresse [init_email] geschickt.<BR>
  Bitte warten Sie die EMail ab und gegeben Sie das Passwort unten ein.
  <BR><BR>
[ENDIF]

[IF action=loginrequest]
 Sie m&uuml;ssen sich anmelden um Operationen durch zuf&uuml;hren, welche
 Ihre EMail-Adresse ben&ouml;tigen.
[ELSE]
 Die meisten Mailing-Listen-Operationen ben&ouml;tigen Ihre EMail-Adresse.
 Mache Mailing-Listen sind f&uuml;r unidentifierte Personen unzug&auml;nglich.
 <BR>
 Um Zugang zu den vollen M&ouml;glichkeiten dieses Servers zu erhalten,
 ist es erforderlich, da&szlig; Sie sich identifizieren.
 <BR>
[ENDIF]

    <FORM ACTION="[path_cgi]" METHOD=POST> 
        <INPUT TYPE="hidden" NAME="previous_action" VALUE="[previous_action]">
        <INPUT TYPE="hidden" NAME="previous_list" VALUE="[previous_list]">
	<INPUT TYPE="hidden" NAME="referer" VALUE="[referer]">
	<INPUT TYPE="hidden" NAME="action" VALUE="login">
	<INPUT TYPE="hidden" NAME="nomenu" VALUE="[nomenu]">

        <TABLE BORDER=0 width=100% CELLSPACING=0 CELLPADDING=0>
         <TR BGCOLOR="--LIGHT_COLOR--">
          <TD NOWRAP align=center>
     	      <INPUT TYPE=hidden NAME=list VALUE="[list]">
     	      <FONT SIZE=-1 COLOR="--SELECTED_COLOR--"><b>EMail: <INPUT TYPE=text NAME=email SIZE=20 VALUE="[init_email]">
      	      Passwort: </b>
              <INPUT TYPE=password NAME=passwd SIZE=8>&nbsp;&nbsp;
              <INPUT TYPE="submit" NAME="action_login" VALUE="Anmelden" SELECTED>
   	    </TD>
     	  </TR>
       </TABLE>
 </FORM> 

<CENTER>

    <B>EMail</B> ist die EMail-Adresse als Abonnent<BR>
    <B>password</B> ist Ihr WWSympa-Passwort.<BR><BR>

<TABLE border=0><TR>
<TD>
<I>Falls Sie noch nie ein Passwort hatten oder sich nicht erinnern k&ouml;nnen:</I>
</TD><TD>
<TABLE CELLPADDING="2" CELLSPACING="2" WIDTH="100%" BORDER="0">
  <TR ALIGN=center BGCOLOR="--DARK_COLOR--">
  <TD>
  <TABLE WIDTH="100%" BORDER="0" CELLSPACING="0" CELLPADDING="2">
     <TR> 
      <TD NOWRAP BGCOLOR="--LIGHT_COLOR--" ALIGN="center"> 
      [IF escaped_init_email]
         <A HREF="[path_cgi]/nomenu/sendpasswd/[escaped_init_email]"
      [ELSE]
         <A HREF="[path_cgi]/nomenu/remindpasswd/referer/[referer]"
      [ENDIF]
       onClick="window.open('','wws_login','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes,resizable=yes,copyhistory=no,width=450,height=300')" TARGET="wws_login">
     <FONT SIZE=-1><B>Passwort an mich schicken</B></FONT></A>
     </TD>
    </TR>
  </TABLE>
</TR>
</TABLE>
</TD></TR></TABLE>
</CENTER>




