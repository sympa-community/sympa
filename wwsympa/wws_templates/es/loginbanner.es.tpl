<!-- RCS Identication ; $Revision$ ; $Date$ -->

<BR>
[IF password_sent]
  Your password has been sent to your email address [init_email].<BR>
  Please check your e-mail box to provide your password bellow.
  <BR><BR>
[ENDIF]

[IF action=loginrequest]
 Usted necesita hacer un login para acceder a su entorno de WWSympa o para efectuar una operación privilegiada (una que requiera su email).
[ELSE]
 La mayoría de las funciones de las listas de correo requieren su email. Algunas de las funcionas de las listas de correo están ocultas a personas no autentificadas.<br>
Para poder utilizar todas las funciones, lo mejor es que se autentifique primero.<br>
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
     	      <FONT SIZE=-1 COLOR="--SELECTED_COLOR--"><b>E-mail <INPUT TYPE=text NAME=email SIZE=20 VALUE="[init_email]"> Contraseña : </b>
              <INPUT TYPE=password NAME=passwd SIZE=8>&nbsp;&nbsp;
              <INPUT TYPE="submit" NAME="action_login" VALUE="Login" SELECTED>
   	    </TD>
     	  </TR>
       </TABLE>
 </FORM> 

<CENTER>

    <FONT COLOR="--DARK_COLOR--"><B>E-mail</B></FONT> es su dirección de correo.
    <FONT COLOR="--DARK_COLOR--"><B>Contraseña</B></FONT> es su contraseña.<BR><BR>

<TABLE border=0><TR>
<TD>
<I>Si usted no tiene una contraseña o la ha olvidado :</I>
</TD><TD>
<TABLE CELLPADDING="2" CELLSPACING="2" WIDTH="100%" BORDER="0">
  <TR ALIGN=center BGCOLOR="--DARK_COLOR--">
  <TD>
  <TABLE WIDTH="100%" BORDER="0" CELLSPACING="0" CELLPADDING="2">
     <TR> 
      <TD NOWRAP BGCOLOR="--LIGHT_COLOR--" ALIGN="center"> 
      <A HREF="[path_cgi]/nomenu/remindpasswd/referer/[referer]" 
      onClick="window.open('','wws_login','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes,resizable=yes,copyhistory=no,width=450,height=300')" TARGET="wws_login">
     <FONT SIZE=-1><B>Enviarme una contraseña</B></FONT></A>
     </TD>
    </TR>
  </TABLE>
</TR>
</TABLE>
</TD></TR></TABLE>
</CENTER>




