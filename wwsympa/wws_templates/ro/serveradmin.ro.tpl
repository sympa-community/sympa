<!-- RCS Identication ; $Revision$ ; $Date$ -->

   <TABLE WIDTH="100%" BORDER=0 CELLPADDING=0>
 
     [IF main_robot]
      <TR>
        <TH BGCOLOR="[dark_color]" COLSPAN="2">
          <TABLE WIDTH="100%" CELLPADDING="0" CELLSPACING="0">
            <TR>
             
          <TH BGCOLOR="[selected_color]" WIDTH="50%"> <FONT COLOR="[bg_color]"> 
            Roboti virtuali</FONT> </TH>
            </TR>
           </TABLE>
         </TH>
     </TR>

     <TR>
    <TD> 
[IF robots]
 Urmatorii roboti virtuali ruleaza pe acest server: 
      <UL>
         [FOREACH vr IN robots]
	    <LI><A HREF="[vr->wwsympa_url]/serveradmin">[vr->NAME]</A>
	 [END]
      </UL>
    [ELSE] 
Pe acest server nu a fost definit nici un robot virtual 
[ENDIF]
 <BR>
     </TD></TR>
    [ENDIF]

      <TR>
        <TH BGCOLOR="[dark_color]" COLSPAN="2">
          <TABLE WIDTH="100%" CELLPADDING="0" CELLSPACING="0">
            <TR>
             
          <TH BGCOLOR="[selected_color]" WIDTH="50%"> <FONT COLOR="[bg_color]"> 
            Liste</FONT> </TH>
            </TR>
           </TABLE>
         </TH>
     </TR><TR>
     <TD>
     [PARSE '/home/sympa/bin/etc/wws_templates/button_header.tpl']
       
    <TD BGCOLOR="[light_color]" ALIGN="center" VALIGN="top"> <A HREF="[path_cgi]/get_pending_lists">Liste 
      in asteptare</A> </TD>
     [PARSE '/home/sympa/bin/etc/wws_templates/button_footer.tpl']

     [PARSE '/home/sympa/bin/etc/wws_templates/button_header.tpl']
       
    <TD BGCOLOR="[light_color]" ALIGN="center" VALIGN="top"> <A HREF="[path_cgi]/get_latest_lists">Ultima 
      lista</A> </TD>
     [PARSE '/home/sympa/bin/etc/wws_templates/button_footer.tpl']

     [PARSE '/home/sympa/bin/etc/wws_templates/button_header.tpl']
       
    <TD BGCOLOR="[light_color]" ALIGN="center" VALIGN="top"> <A HREF="[path_cgi]/get_closed_lists">Liste 
      inchise</A></TD>
     [PARSE '/home/sympa/bin/etc/wws_templates/button_footer.tpl']

    <BR></TD></TR>

    <TR>
        <TH BGCOLOR="[dark_color]" COLSPAN="2">
          <TABLE WIDTH="100%" CELLPADDING="0" CELLSPACING="0">
            <TR>
             
          <TH BGCOLOR="[selected_color]" WIDTH="50%"> <FONT COLOR="[bg_color]"> 
            Utilizatori</FONT> </TH>
            </TR>
           </TABLE>
         </TH>
    </TR>
      <TR><TD NOWRAP>
        <FORM ACTION="[path_cgi]" METHOD="POST">
	  <INPUT NAME="email" SIZE="30" VALUE="[email]">
	  <INPUT TYPE="hidden" NAME="action" VALUE="search_user">
	    <INPUT TYPE="submit" NAME="action_search_user" VALUE="Cauta utilizator">
	</FORM>     
      <BR></TD></TR>

      <TR VALIGN="top">

        <TH BGCOLOR="[dark_color]" COLSPAN="2">
          <TABLE WIDTH="100%" CELLPADDING="0" CELLSPACING="0">
            <TR>
             
          <TH BGCOLOR="[selected_color]" WIDTH="50%"> <FONT COLOR="[bg_color]"> 
            Templateuri</FONT> </TH>
            </TR>
           </TABLE>
         </TH>
      </TR>
      <TR>
        <TD NOWRAP>
	  <FORM ACTION="[path_cgi]" METHOD=POST>
        <FONT COLOR="[dark_color]"><B>Configurare template-uri default pentru 
        lista</B></FONT><BR>
	     <SELECT NAME="file">
	      [FOREACH f IN lists_default_files]
	        <OPTION VALUE='[f->NAME]' [f->selected]>[f->complete]
	      [END]
	    </SELECT>
	    <INPUT TYPE="submit" NAME="action_editfile" VALUE="Editeaza">
	  </FORM>

	  <FORM ACTION="[path_cgi]" METHOD=POST>
        <FONT COLOR="[dark_color]"><B>Configurare template-uri de site</B></FONT><BR>
	     <SELECT NAME="file">
	      [FOREACH f IN server_files]
	        <OPTION VALUE='[f->NAME]' [f->selected]>[f->complete]
	      [END]
	    </SELECT>
	    <INPUT TYPE="submit" NAME="action_editfile" VALUE="Editeaza">
	  </FORM>
	</TD>
      </TR>
      <TR><TD>
     [PARSE '/home/sympa/bin/etc/wws_templates/button_header.tpl']
       
    <TD BGCOLOR="[light_color]" ALIGN="center" VALIGN="top"> <A HREF="[path_cgi]/view_translations">Customizeaza 
      template-uri</A> </TD>
      [PARSE '/home/sympa/bin/etc/wws_templates/button_footer.tpl']
      <BR></TD></TR>

    <TR>
        <TH BGCOLOR="[dark_color]" COLSPAN="2">
          <TABLE WIDTH="100%" CELLPADDING="0" CELLSPACING="0">
            <TR>
             
          <TH BGCOLOR="[selected_color]" WIDTH="50%"> <FONT COLOR="[bg_color]"> 
            Arhive</FONT> </TH>
            </TR>
           </TABLE>
         </TH>
      </TR>

      <TR>
        
    <TD> <FONT COLOR="[dark_color]"><B>Refacere arhive HTML </B>utilizand directoare 
      <CODE>arctxt</CODE> ca si intrare.</font> </TD>
      </TR>
      <TR>
        <TD>
          <FORM ACTION="[path_cgi]" METHOD=POST>
	    <INPUT TYPE="submit" NAME="action_rebuildallarc" VALUE="TOTUL">
        <BR>
        Poate folosi mult din timpul processorului, a se folosi cu atentie! 
      </FORM>
	</TD>

    <TD ALIGN="CENTER"> 
          <FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="text" NAME="list" SIZE="20">
          
        <INPUT TYPE="submit" NAME="action_rebuildarc" VALUE="Refacere arhive">
          </FORM>
    </TD>


      </TR>

      <TR>
        
    <TD> <FONT COLOR="[dark_color]"> <A HREF="[path_cgi]/scenario_test"> <b>Modul 
      de test scenariu</b> </A> </FONT> </TD>
      </TR>
	
    </TABLE>

<BR><BR>
[IF loop_count] 
Procesul FastCGI ([process_id]) a servit[loop_count] din data 
de [start_time]. 
[ENDIF]