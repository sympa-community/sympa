<!-- RCS Identication ; $Revision$ ; $Date$ -->

   <TABLE WIDTH="100%" BORDER=0 CELLPADDING=0>
 
     [IF main_robot]
      <TR>
        <TH BGCOLOR="[dark_color]" COLSPAN="2">
          <TABLE WIDTH="100%" CELLPADDING="0" CELLSPACING="0">
            <TR>
             <TH BGCOLOR="[selected_color]" WIDTH="50%">
              <FONT COLOR="[bg_color]">
	        Virtuele Robots
              </FONT>
             </TH>
            </TR>
           </TABLE>
         </TH>
     </TR>

     <TR><TD>
    [IF robots]
      De volgende virtuele robots draaien op deze server :<UL>
         [FOREACH vr IN robots]
	    <LI><A HREF="[vr->wwsympa_url]/serveradmin">[vr->NAME]</A>
	 [END]
      </UL>
    [ELSE]
      Geen virtuele robots zijn gedefinieerd op deze server.
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
	        Lijsten
              </FONT>
             </TH>
            </TR>
           </TABLE>
         </TH>
     </TR><TR>
     <TD>
     [PARSE '--ETCBINDIR--/wws_templates/button_header.tpl']
       <TD BGCOLOR="[light_color]" ALIGN="center" VALIGN="top">
      <A HREF="[path_cgi]/get_pending_lists">Wachtende lijsten</A>
       </TD>
     [PARSE '--ETCBINDIR--/wws_templates/button_footer.tpl']

     [PARSE '--ETCBINDIR--/wws_templates/button_header.tpl']
       <TD BGCOLOR="[light_color]" ALIGN="center" VALIGN="top">
      <A HREF="[path_cgi]/get_latest_lists">Nieuwste lijsten</A>
       </TD>
     [PARSE '--ETCBINDIR--/wws_templates/button_footer.tpl']

     [PARSE '--ETCBINDIR--/wws_templates/button_header.tpl']
       <TD BGCOLOR="[light_color]" ALIGN="center" VALIGN="top">
      <A HREF="[path_cgi]/get_closed_lists">Gesloten lijsten</A>
       </TD>
     [PARSE '--ETCBINDIR--/wws_templates/button_footer.tpl']

    <BR></TD></TR>

    <TR>
        <TH BGCOLOR="[dark_color]" COLSPAN="2">
          <TABLE WIDTH="100%" CELLPADDING="0" CELLSPACING="0">
            <TR>
             <TH BGCOLOR="[selected_color]" WIDTH="50%">
              <FONT COLOR="[bg_color]">
	        Users
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
	  <INPUT TYPE="submit" NAME="action_search_user" VALUE="Zoek Gebruiker">
	</FORM>     
      <BR></TD></TR>

      <TR VALIGN="top">

        <TH BGCOLOR="[dark_color]" COLSPAN="2">
          <TABLE WIDTH="100%" CELLPADDING="0" CELLSPACING="0">
            <TR>
             <TH BGCOLOR="[selected_color]" WIDTH="50%">
              <FONT COLOR="[bg_color]">
	        Templates 
              </FONT>
             </TH>
            </TR>
           </TABLE>
         </TH>
      </TR>
      <TR>
        <TD NOWRAP>
	  <FORM ACTION="[path_cgi]" METHOD=POST>
	    <FONT COLOR="[dark_color]"><B>Zet de standaard lijst sjablonen</B></FONT><BR>
	     <SELECT NAME="file">
	      [FOREACH f IN lists_default_files]
	        <OPTION VALUE='[f->NAME]' [f->selected]>[f->complete]
	      [END]
	    </SELECT>
	    <INPUT TYPE="submit" NAME="action_editfile" VALUE="Edit">
	  </FORM>

	  <FORM ACTION="[path_cgi]" METHOD=POST>
	    <FONT COLOR="[dark_color]"><B>Zet de site sjablonen</B></FONT><BR>
	     <SELECT NAME="file">
	      [FOREACH f IN server_files]
	        <OPTION VALUE='[f->NAME]' [f->selected]>[f->complete]
	      [END]
	    </SELECT>
	    <INPUT TYPE="submit" NAME="action_editfile" VALUE="Wijzig">
	  </FORM>
	</TD>
      </TR>
      <TR><TD>
     [PARSE '--ETCBINDIR--/wws_templates/button_header.tpl']
       <TD BGCOLOR="[light_color]" ALIGN="center" VALIGN="top">
        <A HREF="[path_cgi]/view_translations">Wijzig sjablonen</A>
       </TD>
      [PARSE '--ETCBINDIR--/wws_templates/button_footer.tpl']
      <BR></TD></TR>

    <TR>
        <TH BGCOLOR="[dark_color]" COLSPAN="2">
          <TABLE WIDTH="100%" CELLPADDING="0" CELLSPACING="0">
            <TR>
             <TH BGCOLOR="[selected_color]" WIDTH="50%">
              <FONT COLOR="[bg_color]">
	        Archives
              </FONT>
             </TH>
            </TR>
           </TABLE>
         </TH>
      </TR>

      <TR>
        <TD>
<FONT COLOR="[dark_color]"><B>Herbouw de HTML archieven</B> waarbij de <CODE>arctxt</CODE> mappen gebruikt worden als input.</FONT>
        </TD>
      </TR>
      <TR>
        <TD>
          <FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="submit" NAME="action_rebuildallarc" VALUE="ALL"><BR>
	Dit kan een hoop rekenkracht vergen van de computer. Let op!
          </FORM>
	</TD>

    <TD ALIGN="CENTER"> 
          <FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="text" NAME="list" SIZE="20">
          <INPUT TYPE="submit" NAME="action_rebuildarc" VALUE="Herbouw archief">
          </FORM>
    </TD>


      </TR>

      <TR>
        <TD>
	  <FONT COLOR="[dark_color]">
	  <A HREF="[path_cgi]/scenario_test">
	     <b>Scenari test module</b>
          </A>
          </FONT>
	</TD>
      </TR>
	
    </TABLE>

<BR><BR>

[IF loop_count]
This FastCGI process ([process_id]) has served [loop_count] since [start_time].
[ENDIF]
