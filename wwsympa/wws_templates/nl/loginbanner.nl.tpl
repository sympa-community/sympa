<!-- RCS Identication ; $Revision$ ; $Date$ -->

<BR>
[IF password_sent]
  Uw wachtwoord is verstuurd naar uw emailadres [init_email].<BR>
  Controleer uw email om het wachtwoord hieronder in te kunnen geven.
  <BR><BR>
[ENDIF]

[IF action=loginrequest]
  U dient in te loggen om uw eigen WWSympa omgeving te benaderen of om een
  opdracht uit laten voeren waar uw emailadres voor nodig is.
[ELSE]
  Voor de meeste funkties van deze websites is uw emailadres nodig. Sommige
  lijsten zijn bijvoorbeeld verborgen voor niet ingelogde personen.<BR>
  Logt u a.u.b. in om volledig gebruik te kunnen maken van deze site.
  <BR>
[ENDIF]

    <FORM ACTION="[path_cgi]" METHOD=POST> 
        <INPUT TYPE="hidden" NAME="previous_action" VALUE="[previous_action]">
        <INPUT TYPE="hidden" NAME="previous_list" VALUE="[previous_list]">
	<INPUT TYPE="hidden" NAME="referer" VALUE="[referer]">
	<INPUT TYPE="hidden" NAME="action" VALUE="inloggen">
	<INPUT TYPE="hidden" NAME="nomenu" VALUE="[nomenu]">

        <TABLE BORDER=0 width=100% CELLSPACING=0 CELLPADDING=0>
         <TR BGCOLOR="[light_color]">
          <TD NOWRAP align=center>
     	      <INPUT TYPE=hidden NAME=list VALUE="[list]">
     	      <FONT SIZE=-1 COLOR="[selected_color]"><b>email <INPUT TYPE=text NAME=email SIZE=20 VALUE="[init_email]">
      	      password : </b>
              <INPUT TYPE=password NAME=passwd SIZE=8>&nbsp;&nbsp;
              <INPUT TYPE="submit" NAME="action_login" VALUE="Inloggen" SELECTED>
   	    </TD>
     	  </TR>
       </TABLE>
 </FORM> 

<CENTER>

    <B>email</B>, dit is uw abonnements emailadres<BR>
    <B>wachtwoord</B>, dit is uw wachtwoord.<BR><BR>

<TABLE border=0><TR>
<TD>
<I>Wanneer u nog nooit een wachtwoord van de server heeft ontvangen of wanneer u hem niet meer weet :</I>
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
     <FONT SIZE=-1><B>Stuur me een wachtwoord</B></FONT></A>
     </TD>
    </TR>
  </TABLE>
</TR>
</TABLE>
</TD></TR></TABLE>
</CENTER>




