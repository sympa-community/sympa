<!-- RCS Identication ; $Revision$ ; $Date$ -->

<BR>
[IF password_sent] 
Parola ti-a fost trimisa la adresa[init_email].<BR>
Verifica contul pentru a scrie mai jos parola.<BR>
<BR>
[ENDIF] 
[IF action=loginrequest] 
Trebuie sa te autentifici pentru a accesa mediul 
tau customizabil WWSympa sau pentru a opera modificari (care necesita adresa ta 
de email). 
[ELSE] 
Majoritatea caracteristicilor de lista necesita adresa ta de 
email. Unele liste se pot vizializa doar de ctre utilizatorii autentificati.<BR>
Pentru a beneficia de toate serviciile oferite pe acest server, trebui mai intai 
sa te autentifici. <BR>
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
     	      <FONT SIZE=-1 COLOR="[selected_color]"><b>email <INPUT TYPE=text NAME=email SIZE=20 VALUE="[init_email]">
      	      password : </b>
              <INPUT TYPE=password NAME=passwd SIZE=8>&nbsp;&nbsp;
              <INPUT TYPE="submit" NAME="action_login" VALUE="Login" SELECTED>
   	    </TD>
     	  </TR>
       </TABLE>
 </FORM> 

<CENTER>
  <B>email</B>, este adresa cu care te-ai inscris<B><br>
  password</B>, este parola.<BR>
  <BR>

<TABLE border=0><TR>
      <TD> <I>Daca nu ai avut parola deloc pentru acest server sau nu ti-o amintesti:</I> 
      </TD>
      <TD>
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
                    <FONT SIZE=-1><B>Trimite-mi parola</B></FONT></A></TD>
    </TR>
  </TABLE>
</TR>
</TABLE>
</TD></TR></TABLE>
</CENTER>




