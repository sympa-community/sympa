<!-- RCS Identication ; $Revision$ ; $Date$ -->

   <TABLE WIDTH="100%" BORDER=0 CELLPADDING=0>
 
     [IF main_robot]
      <TR>
        <TH BGCOLOR="[dark_color]" COLSPAN="2">
          <TABLE WIDTH="100%" CELLPADDING="0" CELLSPACING="0">
            <TR>
             <TH BGCOLOR="[selected_color]" WIDTH="50%">
              <FONT COLOR="[bg_color]">
	        Virtuaali Robotit
              </FONT>
             </TH>
            </TR>
           </TABLE>
         </TH>
     </TR>

     <TR><TD>
    [IF robots]
      Seuraavat Virtuaali robotit pyörivät tällä palvelimella :<UL>
         [FOREACH vr IN robots]
	    <LI><A HREF="[vr->wwsympa_url]/serveradmin">[vr->NAME]</A>
	 [END]
      </UL>
    [ELSE]
      Ei Virtuaali robotteja määriteltynä tällä palvelimella
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
	        Listat
              </FONT>
             </TH>
            </TR>
           </TABLE>
         </TH>
     </TR><TR>
     [PARSE '--ETCBINDIR--/wws_templates/button_header.tpl']
       <TD BGCOLOR="[light_color]" ALIGN="center" VALIGN="top">
      <A HREF="[path_cgi]/get_pending_lists">Odottavat listat</A>
       </TD>
     [PARSE '--ETCBINDIR--/wws_templates/button_footer.tpl']

     [PARSE '--ETCBINDIR--/wws_templates/button_header.tpl']
       <TD BGCOLOR="[light_color]" ALIGN="center" VALIGN="top">
      <A HREF="[path_cgi]/get_latest_lists">Uusimmat listat</A>
       </TD>
     [PARSE '--ETCBINDIR--/wws_templates/button_footer.tpl']

     [PARSE '--ETCBINDIR--/wws_templates/button_header.tpl']
       <TD BGCOLOR="[light_color]" ALIGN="center" VALIGN="top">
      <A HREF="[path_cgi]/get_closed_lists">Suljetut listat</A>
       </TD>
     [PARSE '--ETCBINDIR--/wws_templates/button_footer.tpl']

    <BR></TR>

    <TR>
        <TH BGCOLOR="[dark_color]" COLSPAN="2">
          <TABLE WIDTH="100%" CELLPADDING="0" CELLSPACING="0">
            <TR>
             <TH BGCOLOR="[selected_color]" WIDTH="50%">
              <FONT COLOR="[bg_color]">
	        Käyttäjät
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
	  <INPUT TYPE="submit" NAME="action_search_user" VALUE="Etsi käyttäjä">
	</FORM>     
      <BR></TD></TR>

      <TR VALIGN="top">

        <TH BGCOLOR="[dark_color]" COLSPAN="2">
          <TABLE WIDTH="100%" CELLPADDING="0" CELLSPACING="0">
            <TR>
             <TH BGCOLOR="[selected_color]" WIDTH="50%">
              <FONT COLOR="[bg_color]">
	        Oletusmallit 
              </FONT>
             </TH>
            </TR>
           </TABLE>
         </TH>
      </TR>
      <TR>
        <TD NOWRAP>
	  <FORM ACTION="[path_cgi]" METHOD=POST>
	    <FONT COLOR="[dark_color]"><B>Asetetaan lista oletusmallit</B></FONT><BR>
	     <SELECT NAME="file">
	      [FOREACH f IN lists_default_files]
	        <OPTION VALUE='[f->NAME]' [f->selected]>[f->complete]
	      [END]
	    </SELECT>
	    <INPUT TYPE="submit" NAME="action_editfile" VALUE="Muuta">
	  </FORM>

	  <FORM ACTION="[path_cgi]" METHOD=POST>
	    <FONT COLOR="[dark_color]"><B>Asetetaan sivuston oletusmallit</B></FONT><BR>
	     <SELECT NAME="file">
	      [FOREACH f IN server_files]
	        <OPTION VALUE='[f->NAME]' [f->selected]>[f->complete]
	      [END]
	    </SELECT>
	    <INPUT TYPE="submit" NAME="action_editfile" VALUE="Muuta">
	  </FORM>
	</TD>
      </TR>
      <TR><TD>
     [PARSE '--ETCBINDIR--/wws_templates/button_header.tpl']
       <TD BGCOLOR="[light_color]" ALIGN="center" VALIGN="top">
        <A HREF="[path_cgi]/view_translations">Muuta malleja</A>
       </TD>
      [PARSE '--ETCBINDIR--/wws_templates/button_footer.tpl']
      <BR></TD></TR>

    <TR>
        <TH BGCOLOR="[dark_color]" COLSPAN="2">
          <TABLE WIDTH="100%" CELLPADDING="0" CELLSPACING="0">
            <TR>
             <TH BGCOLOR="[selected_color]" WIDTH="50%">
              <FONT COLOR="[bg_color]">
	        Arkistot
              </FONT>
             </TH>
            </TR>
           </TABLE>
         </TH>
      </TR>

      <TR>
        <TD>
<FONT COLOR="[dark_color]"><B>Luo HTML arkistot uudelleen</B> käyttäen <CODE>arctxt</CODE> hakemistoja syöttönä.</FONT>
        </TD>
      </TR>
      <TR>
        <TD>
          <FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="submit" NAME="action_rebuildallarc" VALUE="KAIKKI"><BR>
	Saattaa viedä paljon CPU aikaa, ole varovainen !
          </FORM>
	</TD>

    <TD ALIGN="CENTER"> 
          <FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="text" NAME="list" SIZE="20">
          <INPUT TYPE="submit" NAME="action_rebuildarc" VALUE="Luo arkisto uudelleen">
          </FORM>
    </TD>


      </TR>

      <TR>
        <TD>
	  <FONT COLOR="[dark_color]">
	  <A HREF="[path_cgi]/scenario_test">
	     <b>Skenaario testi moduuli</b>
          </A>
          </FONT>
	</TD>
      </TR>
	
    </TABLE>

<BR><BR>

[IF loop_count]
Tämä FastCGI prosessi ([process_id]) on ollut ajossa [loop_count] [start_time] asti.
[ENDIF]
