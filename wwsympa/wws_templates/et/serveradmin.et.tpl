<!-- RCS Identication ; $Revision$ ; $Date$ -->

   <TABLE WIDTH="100%" BORDER=0 CELLPADDING=0>
 
     [IF main_robot]
      <TR>
        <TH BGCOLOR="[dark_color]" COLSPAN="2">
          <TABLE WIDTH="100%" CELLPADDING="0" CELLSPACING="0">
            <TR>
             <TH BGCOLOR="[selected_color]" WIDTH="50%">
              <FONT COLOR="[bg_color]">
	        Virtuaalsed serverid
              </FONT>
             </TH>
            </TR>
           </TABLE>
         </TH>
     </TR>

     <TR><TD>
    [IF robots]
      Teie serveris k‰ivad virtuaalsed listserverid:<UL>
         [FOREACH vr IN robots]
	    <LI><A HREF="[vr->wwsympa_url]/serveradmin">[vr->NAME]</A>
	 [END]
      </UL>
    [ELSE]
      Siin serveris ei ole virtuaalseid listservereid.
    [ENDIF]
     <BR>
     </TD></TR>
    [ENDIF]

      <TR>
        <TH BGCOLOR="[dark_color]" COLSPAN="2">
          <TABLE WIDTH="100%" CELLPADDING="0" CELLSPACING="0">
            <TR>
             <TH BGCOLOR="[selected_color]" WIDTH="50%">
              <FONT COLOR="[bg_color]">
	        Listid
              </FONT>
             </TH>
            </TR>
           </TABLE>
         </TH>
     </TR><TR>
     <TD>
     [PARSE '--ETCBINDIR--/wws_templates/button_header.tpl']
       <TD BGCOLOR="[light_color]" ALIGN="center" VALIGN="top">
      <A HREF="[path_cgi]/get_pending_lists">Tegemisel listid</A>
       </TD>
     [PARSE '--ETCBINDIR--/wws_templates/button_footer.tpl']

     [PARSE '--ETCBINDIR--/wws_templates/button_header.tpl']
       <TD BGCOLOR="[light_color]" ALIGN="center" VALIGN="top">
      <A HREF="[path_cgi]/get_latest_lists">Uusimad listid</A>
       </TD>
     [PARSE '--ETCBINDIR--/wws_templates/button_footer.tpl']

     [PARSE '--ETCBINDIR--/wws_templates/button_header.tpl']
       <TD BGCOLOR="[light_color]" ALIGN="center" VALIGN="top">
      <A HREF="[path_cgi]/get_closed_lists">Suletud listid</A>
       </TD>
     [PARSE '--ETCBINDIR--/wws_templates/button_footer.tpl']

    <BR></TD></TR>

    <TR>
        <TH BGCOLOR="[dark_color]" COLSPAN="2">
          <TABLE WIDTH="100%" CELLPADDING="0" CELLSPACING="0">
            <TR>
             <TH BGCOLOR="[selected_color]" WIDTH="50%">
              <FONT COLOR="[bg_color]">
		Kasutajad
              </FONT>
             </TH>
            </TR>
           </TABLE>
         </TH>
    </TR>
      <TR><TD NOWRAP>
        <FORM ACTION="[path_cgi]" METHOD="POST">
	  <INPUT NAME="email" SIZE="30" VALUE="[email]">
	  <INPUT TYPE="hidden" NAME="action" VALUE="search_user">
	  <INPUT TYPE="submit" NAME="action_search_user" VALUE="Otsi kasutajat">
	</FORM>     
      <BR></TD></TR>

      <TR VALIGN="top">

        <TH BGCOLOR="[dark_color]" COLSPAN="2">
          <TABLE WIDTH="100%" CELLPADDING="0" CELLSPACING="0">
            <TR>
             <TH BGCOLOR="[selected_color]" WIDTH="50%">
              <FONT COLOR="[bg_color]">
		Mallid
              </FONT>
             </TH>
            </TR>
           </TABLE>
         </TH>
      </TR>
      <TR>
        <TD NOWRAP>
	  <FORM ACTION="[path_cgi]" METHOD=POST>
	    <FONT COLOR="[dark_color]"><B>Listimallidele vaikev‰‰rtuste kohandamine</B></FONT><BR>
	     <SELECT NAME="file">
	      [FOREACH f IN lists_default_files]
	        <OPTION VALUE='[f->NAME]' [f->selected]>[f->complete]
	      [END]
	    </SELECT>
	    <INPUT TYPE="submit" NAME="action_editfile" VALUE="Redigeeri">
	  </FORM>

	  <FORM ACTION="[path_cgi]" METHOD=POST>
	    <FONT COLOR="[dark_color]"><B>Veebimallide kohandamine</B></FONT><BR>
	     <SELECT NAME="file">
	      [FOREACH f IN server_files]
	        <OPTION VALUE='[f->NAME]' [f->selected]>[f->complete]
	      [END]
	    </SELECT>
	    <INPUT TYPE="submit" NAME="action_editfile" VALUE="Redigeeri">
	  </FORM>
	</TD>
      </TR>
      <TR><TD>
     [PARSE '--ETCBINDIR--/wws_templates/button_header.tpl']
       <TD BGCOLOR="[light_color]" ALIGN="center" VALIGN="top">
        <A HREF="[path_cgi]/view_translations">Mallide kohandamine</A>
       </TD>
      [PARSE '--ETCBINDIR--/wws_templates/button_footer.tpl']
      <BR></TD></TR>

    <TR>
        <TH BGCOLOR="[dark_color]" COLSPAN="2">
          <TABLE WIDTH="100%" CELLPADDING="0" CELLSPACING="0">
            <TR>
             <TH BGCOLOR="[selected_color]" WIDTH="50%">
              <FONT COLOR="[bg_color]">
	        Arhiivid
              </FONT>
             </TH>
            </TR>
           </TABLE>
         </TH>
      </TR>

      <TR>
        <TD>
<FONT COLOR="[dark_color]"><B>Genereeri HTML arhiivid uuesti</B> kasutades sisendina <CODE>arctxt</CODE> katalooge.
        </TD>
      </TR>
      <TR>
        <TD>
          <FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="submit" NAME="action_rebuildallarc" VALUE="Kıik"><BR>
	T‰helepanu: see vajab palju protsessoriaega!
          </FORM>
	</TD>

    <TD ALIGN="CENTER"> 
          <FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="text" NAME="list" SIZE="20">
          <INPUT TYPE="submit" NAME="action_rebuildarc" VALUE="Uuenda arhiivi">
          </FORM>
    </TD>


      </TR>

      <TR>
        <TD>
	  <FONT COLOR="[dark_color]">
	  <A HREF="[path_cgi]/scenario_test">
	     <b>Scenari test moodul</b>
          </A>
          </FONT>
	</TD>
      </TR>
	
    </TABLE>

<BR><BR>

[IF loop_count]
See FastCGI protsess ([process_id]) on t‰itnud [loop_count] p‰ringut alates [start_time].
[ENDIF]
