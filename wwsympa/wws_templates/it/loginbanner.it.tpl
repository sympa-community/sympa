<!-- RCS Identication ; $Revision$ ; $Date$ -->

<BR>
[IF password_sent]
  Your password as been sent to [init_email].<BR>
  Check your mailbox to complete the following form. 
  <BR><BR>
[ENDIF]

[IF action=loginrequest]
Devi inserire login e password per accedere alle tue sottoscrizioni o per
usare i comandi privilegiati (quelli che richiedono il tuo indirizzo).
[ELSE]
 Alcune parti delle mailing list richiedono il tuo indirizzo. Altre sono nascoste ai
 non sottoscritti.<BR>
 Per accedere a tutti i servizi, devi identificarti.<BR>
[ENDIF]

    <FORM ACTION="[path_cgi]" METHOD=POST> 
        <INPUT TYPE="hidden" NAME="previous_action" VALUE="[previous_action]">
        <INPUT TYPE="hidden" NAME="previous_list" VALUE="[previous_list]">
	<INPUT TYPE="hidden" NAME="referer" VALUE="[referer]">
	<INPUT TYPE="hidden" NAME="action" VALUE="login">

        <TABLE BORDER=0 width=100% CELLSPACING=0 CELLPADDING=0>
         <TR BGCOLOR="--LIGHT_COLOR--">
          <TD NOWRAP align=center>
     	      <INPUT TYPE=hidden NAME=list VALUE="[list]">
     	      <FONT SIZE=-1 COLOR="--SELECTED_COLOR--"><b>email <INPUT TYPE=text NAME=email SIZE=20 VALUE="[init_email]">
      	      password : </b>
              <INPUT TYPE=password NAME=passwd SIZE=8>&nbsp;&nbsp;
              <INPUT TYPE="submit" NAME="action_login" VALUE="Login" SELECTED>
   	    </TD>
     	  </TR>
       </TABLE>
 </FORM> 

<CENTER>

    <FONT COLOR="--DARK_COLOR--"><B>email</B></FONT> &egrave; il tuo indirizzo con cui ti sei iscritto.
    <FONT COLOR="--DARK_COLOR--"><B>password</B></FONT> &egrave; la tua password.<BR><BR>

<TABLE border=0><TR>
<TD>
<I>Se non hai mai ottenuto una password per questo servizio o l'hai dimenticata:</I>
</TD><TD>
<TABLE CELLPADDING="2" CELLSPACING="2" WIDTH="100%" BORDER="0">
  <TR ALIGN=center BGCOLOR="--DARK_COLOR--">
  <TD>
  <TABLE WIDTH="100%" BORDER="0" CELLSPACING="0" CELLPADDING="2">
     <TR> 
      <TD NOWRAP BGCOLOR="--LIGHT_COLOR--" ALIGN="center"> 
      <A HREF="[path_cgi]/nomenu/remindpasswd/referer/[referer]" onClick="window.open('','wws_login','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes,resizable=yes,copyhistory=no,width=450,height=300')" TARGET="wws_login" >
     <FONT SIZE=-1><B>Mandami la password</B></FONT></A>
     </TD>
    </TR>
  </TABLE>
</TR>
</TABLE>
</TD></TR></TABLE>
</CENTER>









