<!-- RCS Identication ; $Revision$ ; $Date$ -->

<!-- begin title.fr.tpl -->
<!-- <TABLE WIDTH="100%" BORDER=0 cellpadding=2 cellspacing=0><TR><TD>-->
<TABLE WIDTH="100%" BORDER="0" BGCOLOR="[dark_color]" cellpadding="2" cellspacing="0">
  <TR VALIGN="bottom">
  <TD ALIGN="left" NOWRAP>
       <FONT size="-1" COLOR="[bg_color]">
         [IF user->email]
          <b>[user->email]</b>
         <CENTER>
 	 [IF is_listmaster]
	  Listmaster
	 [ELSIF is_privileged_owner]
          Gestionnaire privilégié
	 [ELSIF is_owner]
          Gestionnaire
         [ELSIF is_editor]
          Moderateur
         [ELSIF is_subscriber]
	  Abonné
	 [ENDIF]
	  </CENTER>
	 [ENDIF]
	</FONT>
   </TD>
   <TD ALIGN=center WIDTH="100%">
       <TABLE width=100% cellpadding=0>
          <TR><TD BGCOLOR="[selected_color]" NOWRAP align=center>
	    <FONT COLOR="[bg_color]" SIZE="+2"><B>[title]</B></FONT>
	     <BR><FONT COLOR="[bg_color]">[subtitle]</FONT>
            </TD>
           </TR>
        </TABLE>
   </TD>
   </TR>
</TABLE>
<!--  </TD></TR></TABLE> -->
<!-- end title.fr.tpl -->
