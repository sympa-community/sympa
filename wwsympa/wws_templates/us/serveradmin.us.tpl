<!-- RCS Identication ; $Revision$ ; $Date$ -->

   <TABLE WIDTH="100%" BORDER=0 CELLPADDING=0>
 
     [IF main_robot]
      <TR>
        <TH BGCOLOR="[dark_color]" COLSPAN="2">
          <TABLE WIDTH="100%" CELLPADDING="0" CELLSPACING="0">
            <TR>
             <TH BGCOLOR="[selected_color]" WIDTH="50%">
              <FONT COLOR="[bg_color]">
	        Virtual Robots
              </FONT>
             </TH>
            </TR>
           </TABLE>
         </TH>
     </TR>

     <TR><TD>
    [IF robots]
      The following virtual robots are running on this server :<UL>
         [FOREACH vr IN robots]
	    <LI><A HREF="[vr->wwsympa_url]/serveradmin">[vr->NAME]</A>
	 [END]
      </UL>
    [ELSE]
      No Virtual Robot defined on this server
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
	        Lists
              </FONT>
             </TH>
            </TR>
           </TABLE>
         </TH>
     </TR><TR>
     <TD>
     [PARSE '--ETCBINDIR--/wws_templates/button_header.tpl']
       <TD BGCOLOR="[light_color]" ALIGN="center" VALIGN="top">
      <A HREF="[path_cgi]/get_pending_lists">Pending lists</A>
       </TD>
     [PARSE '--ETCBINDIR--/wws_templates/button_footer.tpl']

     [PARSE '--ETCBINDIR--/wws_templates/button_header.tpl']
       <TD BGCOLOR="[light_color]" ALIGN="center" VALIGN="top">
      <A HREF="[path_cgi]/get_latest_lists">Latest lists</A>
       </TD>
     [PARSE '--ETCBINDIR--/wws_templates/button_footer.tpl']

     [PARSE '--ETCBINDIR--/wws_templates/button_header.tpl']
       <TD BGCOLOR="[light_color]" ALIGN="center" VALIGN="top">
      <A HREF="[path_cgi]/get_inactive_lists">Inactive lists</A>
       </TD>
     [PARSE '--ETCBINDIR--/wws_templates/button_footer.tpl']

     [PARSE '--ETCBINDIR--/wws_templates/button_header.tpl']
       <TD BGCOLOR="[light_color]" ALIGN="center" VALIGN="top">
      <A HREF="[path_cgi]/get_closed_lists">Closed lists</A>
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
	  <INPUT TYPE="submit" NAME="action_search_user" VALUE="Search User">
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
	    <FONT COLOR="[dark_color]"><B>Setting defaults list templates</B></FONT><BR>
	     <SELECT NAME="file">
	      [FOREACH f IN lists_default_files]
	        <OPTION VALUE='[f->NAME]' [f->selected]>[f->complete]
	      [END]
	    </SELECT>
	    <INPUT TYPE="submit" NAME="action_editfile" VALUE="Edit">
	  </FORM>

	  <FORM ACTION="[path_cgi]" METHOD=POST>
	    <FONT COLOR="[dark_color]"><B>Setting site templates</B></FONT><BR>
	     <SELECT NAME="file">
	      [FOREACH f IN server_files]
	        <OPTION VALUE='[f->NAME]' [f->selected]>[f->complete]
	      [END]
	    </SELECT>
	    <INPUT TYPE="submit" NAME="action_editfile" VALUE="Edit">
	  </FORM>
	</TD>
      </TR>
      <TR><TD>
     [PARSE '--ETCBINDIR--/wws_templates/button_header.tpl']
       <TD BGCOLOR="[light_color]" ALIGN="center" VALIGN="top">
        <A HREF="[path_cgi]/view_translations">Customize templates</A>
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
<FONT COLOR="[dark_color]"><B>Rebuild HTML archives</B> using <CODE>arctxt</CODE> directories as input.</FONT>
        </TD>
      </TR>
      <TR>
        <TD>
          <FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="submit" NAME="action_rebuildallarc" VALUE="ALL"><BR>
	May take a lot of CPU time,  be careful !
          </FORM>
	</TD>

    <TD ALIGN="CENTER"> 
          <FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="text" NAME="list" SIZE="20">
          <INPUT TYPE="submit" NAME="action_rebuildarc" VALUE="Rebuild archive">
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