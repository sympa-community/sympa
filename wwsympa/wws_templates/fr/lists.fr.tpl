<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF action=search_list]
  [occurrence] occurrences sélectionnées<BR><BR>
[ELSIF action=search_user]
  <B>[email]</B> est abonné aux listes suivantes
[ENDIF]

<TABLE BORDER="0" WIDTH="100%">
   [FOREACH l IN which]
     <TR>
      [IF l->admin]
       <TD BGCOLOR="[dark_color]">
          <TABLE BORDER="0" WIDTH="100%" CELLSPACING="0" CELLPADDING="1">
           <TR><TD BGCOLOR="[light_color]" ALIGN="center" VALIGN="top">
             <FONT COLOR="[selected_color]" SIZE="-1">
              <A HREF="[base_url][path_cgi]/admin/[l->NAME]" ><b>admin</b></A>
         </FONT>
       </TD>
     </TR>
 </TABLE>
</TD>
     [ELSE]
       <TD>&nbsp;</TD>
     [ENDIF]


    <TD WIDTH="100%" ROWSPAN="2">
     [IF l->export=yes] 
       <A HREF="[l->urlinfo]" >[l->list_address]</A>
       <BR>
       [l->subject]         
     [ELSE]  
     <A HREF="[path_cgi]/info/[l->NAME]" ><B>[l->NAME]@[l->host]</B></A>
     <BR>
     [l->subject]
     [ENDIF]
     </TD></TR> 
     <TR><TD>&nbsp;</TD></TR>
    
     [END] 
</TABLE>
<BR>

[IF action = which]

[IF ! which]
&nbsp;&nbsp;<FONT COLOR="[dark_color]">Pas d'abonnements avec l'adresse
<B>[user->email]</B> !</FONT>
<BR>
[ENDIF]

[IF unique <> 1]

<TABLE>
&nbsp;&nbsp;<FONT COLOR="[dark_color]">Voir les abonnements avec adresses</FONT>

<BR><BR>

 <TR> 
    <FORM METHOD=POST ACTION="[path_cgi]">
     
    [FOREACH email IN alt_emails]
    <INPUT NAME="email"  TYPE=hidden VALUE="[email->NAME]">
    &nbsp;&nbsp;<A HREF="[path_cgi]/change_identity/[email->NAME]/which">[email->NAME]</A> 
  <BR>
    [END]  
    </FORM>
  </TR>
</TABLE>

<BR> 


<TABLE>
<TR>
&nbsp;&nbsp;<FONT COLOR="[dark_color]">Unifier vos abonnements avec l'adresse <B>[user->email]</B></FONT><BR>
&nbsp;&nbsp;<FONT COLOR="[dark_color]">C'est à dire utiliser une unique adresse dans Sympa pour vos abonnements et préferences</FONT>
<TR>
<TD>
    <FORM ACTION="[path_cgi]" METHOD=POST>
  
&nbsp;&nbsp;<INPUT TYPE="submit" NAME="action_unify_email" VALUE="Valider"></FONT>
    </FORM>
</TD>
</TR>
<BR>
</TABLE>

[ENDIF]
[ENDIF]
