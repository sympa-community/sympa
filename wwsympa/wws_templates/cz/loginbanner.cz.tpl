<!-- RCS Identication ; $Revision$ ; $Date$ -->

<BR>
[IF password_sent]
  Va¹e heslo bylo odesláno na Va¹i emailovou adresu [init_email].<BR>
  Prosím prohlédnìte si Va¹i emailovou schránku a napi¹te dolù Va¹e heslo.
  <BR><BR>
[ENDIF]

[IF action=loginrequest]
 Pro pøístup k Va¹emu prostøedí na WWSympa nebo k provádìní privilegovaných 
operaci (ty, které vy¾adují emailovou adresu) se musíte pøihlásit.
[ELSE]
Vìt¹ina mo¾ností konference vy¾aduje Va¹i emailovou adresu. Nìkteré konference
jsou skryté neznámým osobám.<BR>
Abyste mohli vyu¾ít v¹echny slu¾by, které nabízí tento server, musíte se
nejprve identifikovat. <BR>
[ENDIF]

    <FORM ACTION="[path_cgi]" METHOD=POST> 
        <INPUT TYPE="hidden" NAME="previous_action" VALUE="[previous_action]">
        <INPUT TYPE="hidden" NAME="previous_list" VALUE="[previous_list]">
	<INPUT TYPE="hidden" NAME="referer" VALUE="[referer]">
	<INPUT TYPE="hidden" NAME="action" VALUE="login">
	<INPUT TYPE="hidden" NAME="nomenu" VALUE="[nomenu]">

        <TABLE BORDER=0 width=100% CELLSPACING=0 CELLPADDING=0>
         <TR BGCOLOR="[light_color]">
          <TD NOWRAP align=center>
     	      <INPUT TYPE=hidden NAME=list VALUE="[list]">
     	      <FONT SIZE=-1 COLOR="[selected_color]"><b>emailová adresa <INPUT TYPE=text NAME=email SIZE=20 VALUE="[init_email]">
      	      heslo : </b>
              <INPUT TYPE=password NAME=passwd SIZE=8>&nbsp;&nbsp;
              <INPUT TYPE="submit" NAME="action_login" VALUE="Pøihlásit se" SELECTED>
   	    </TD>
     	  </TR>
       </TABLE>
 </FORM> 

<CENTER>

    <B>emailová adresa</B>, je Va¹e èlenská emailová adresa<BR>
    <B>heslo</B>, je Va¹e heslo.<BR><BR>

<TABLE border=0><TR>
<TD>
<I>Pokud na tomto serveru nemáte heslo nebo si ho nepamatujete :</I>
</TD><TD>
<TABLE CELLPADDING="2" CELLSPACING="2" WIDTH="100%" BORDER="0">
  <TR ALIGN=center BGCOLOR="[dark_color]">
  <TD>
  <TABLE WIDTH="100%" BORDER="0" CELLSPACING="0" CELLPADDING="2">
     <TR> 
      <TD NOWRAP BGCOLOR="[light_color]" ALIGN="center"> 
      [IF escaped_init_email]
         <A HREF="[path_cgi]/nomenu/sendpasswd/[escaped_init_email]"
      [ELSE]
         <A HREF="[path_cgi]/nomenu/remindpasswd/referer/[referer]"
      [ENDIF]
       onClick="window.open('','wws_login','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes,resizable=yes,copyhistory=no,width=450,height=300')" TARGET="wws_login">
     <FONT SIZE=-1><B>Za¹lete mi heslo</B></FONT></A>
     </TD>
    </TR>
  </TABLE>
</TR>
</TABLE>
</TD></TR></TABLE>
</CENTER>
