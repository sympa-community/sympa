<!-- RCS Identication ; $Revision$ ; $Date$ -->

<P>
<TABLE width=100% border="0" VALIGN="top">
<TR>
[IF is_owner]
<TD VALIGN="top" NOWRAP COLSPAN="3">
    <FORM ACTION="[path_cgi]" METHOD="POST">
      <INPUT TYPE="hidden" NAME="previous_action" VALUE="review">
      <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
      <INPUT TYPE="hidden" NAME="action" VALUE="add">
      <INPUT TYPE="text" NAME="email" SIZE="18">
      <INPUT TYPE="submit" NAME="action_add" VALUE="Hozzáad"> nincs értesítés<INPUT TYPE="checkbox" NAME="quiet">
    </FORM>
</TD>
</TR>
</TR>
<TR>
 <TD ALIGN="right">
   <TABLE BORDER="0" CELLPADDING="1" CELLSPACING="0"><TR><TD BGCOLOR="[dark_color]" VALIGN="top">
   <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
<TR>
 <TD BGCOLOR="[light_color]" ALIGN="center" VALIGN="top">
   <FONT COLOR="[selected_color]" SIZE="-1">
    <A HREF="[base_url][path_cgi]/subindex/[list]" ><b>Jóváhagyásra váró feliratkozások</b></A>
   </FONT>
</TD> 
</TR>
 </TABLE></TD></TR>
</TABLE>
</TD>
<TD>
 <TABLE BORDER="0" CELLPADDING="1" CELLSPACING="0"><TR><TD BGCOLOR="[dark_color]" VALIGN="top">
   <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
     <TR>
       <TD BGCOLOR="[light_color]" ALIGN="center" VALIGN="top">
         <FONT COLOR="[selected_color]" SIZE="-1">
         <A HREF="[base_url][path_cgi]/add_request/[list]" ><b>Tagok hozzáadása</b></A>
         </FONT>
       </TD>
     </TR>
   </TABLE></TD></TR>
 </TABLE>
</TD>

<TD>
 <TABLE BORDER="0" CELLPADDING="1" CELLSPACING="0"><TR><TD BGCOLOR="[dark_color]" VALIGN="top">
   <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
     <TR>
       <TD BGCOLOR="[light_color]" ALIGN="center" VALIGN="top">
         <FONT COLOR="[selected_color]" SIZE="-1">

         <A HREF="[base_url][path_cgi]/remind/[list]" onClick="request_confirm_link('[path_cgi]/remind/[list]', 'Tényleg szeretnél a(z) [total] új tagnak üdvözlõ szöveget küldeni?'); return false;"><b>Újak értesítése</b></A>

         </FONT>
       </TD>
     </TR>
   </TABLE></TD></TR>
 </TABLE>
</TD>

[ENDIF]
</TR>
<TR>
<TD VALIGN="top" NOWRAP>
<FORM ACTION="[path_cgi]" METHOD="POST"> 
<INPUT TYPE="hidden" NAME="previous_action" VALUE="review">
<INPUT TYPE=hidden NAME=list VALUE="[list]">
<INPUT TYPE="hidden" NAME="action" VALUE="search">
<INPUT SIZE="18" NAME=filter VALUE="[filter]">
<INPUT TYPE="submit" NAME="action_search" VALUE="Keresés">
[IF action=search]
<BR>[occurrence] találat<BR>
[IF too_many_select]
Túl sokat jelöltél ki, nem tudom megjeleníteni.
[ENDIF]
[ENDIF]
</FORM>
</TD>
</TR>
</TABLE>
<FORM NAME="myform" ACTION="[path_cgi]" METHOD="POST">
 <INPUT TYPE="hidden" NAME="previous_action" VALUE="[action]">
 <INPUT TYPE="hidden" NAME="previous_list" VALUE="[list]">
 <INPUT TYPE=hidden NAME=list VALUE="[list]">

<TABLE WIDTH="100%" BORDER="0">
  <TR><TD ALIGN="left" NOWRAP>
  [IF is_owner]

    <!--INPUT TYPE="button" NAME="action_del" VALUE="Töröld a kijelölt e-mail címeket" onClick="request_confirm(this.form,'Tényleg szeretnéd az ÖSSZES kijelölt tagot törölni?')"-->

    <INPUT TYPE="submit" NAME="action_del" VALUE="Kijelöltek törlése">

    <INPUT TYPE="checkbox" NAME="quiet"> nincs értesítés
  [ENDIF]
  </TD>
  <TD WIDTH="100%">&nbsp;</TD>
  [IF action<>search]
  <TD NOWRAP>
	<INPUT TYPE="hidden" NAME="sortby" VALUE="[sortby]">
	<INPUT TYPE="submit" NAME="action_review" VALUE="Kijelezve">
	        <SELECT NAME="size">
                  <OPTION VALUE="[size]" SELECTED>[size]
		  <OPTION VALUE="25">25
		  <OPTION VALUE="50">50
		  <OPTION VALUE="100">100
		   <OPTION VALUE="500">500
		</SELECT>
   </TD>
   <TD>
   [IF prev_page]
    <A HREF="[path_cgi]/review/[list]/[prev_page]/[size]/[sortby]"><IMG SRC="/icons/left.png" BORDER=0 ALT="Elõzõ oldal"></A>
   [ENDIF]
   [IF page]
     Oldalak [page] / [total_page]
   [ENDIF]
   [IF next_page]
     <A HREF="[path_cgi]/review/[list]/[next_page]/[size]/[sortby]"><IMG SRC="/icons/right.png" BORDER="0" ALT="Következõ oldal"></A>
   [ENDIF]
  [ENDIF]
  </TD></TR>
  </TABLE>

    <TABLE WIDTH="100%" BORDER="1">
      <TR BGCOLOR="[light_color]">
	[IF is_owner]
	   <TH><FONT SIZE="-1"><B>X</B></FONT></TH>
	[ENDIF]
        [IF sortby=email]
  	    <TH NOWRAP COLSPAN=2 BGCOLOR="[selected_color]">
	    <FONT COLOR="[bg_color]" SIZE="-1"><b>Email</b></FONT>
	[ELSE]
	    <TH NOWRAP COLSPAN=2>
	    <A HREF="[path_cgi]/review/[list]/1/[size]/email" >
	    <FONT SIZE="-1"><b>Email</b></A>
	[ENDIF]
	</TH>
        <TH><FONT SIZE="-1"><B>Név</B></FONT>
	</TH>
        [IF is_owner]
	  <TH><FONT SIZE="-1"><B>Kézbesítés típusa</B></FONT>
	  </TH>
	  [IF sortby=date]
  	    <TH NOWRAP BGCOLOR="[selected_color]">
	    <FONT COLOR="[bg_color]" SIZE="-1"><b>Feliratkozott</b></FONT>
	  [ELSE]
	    <TH NOWRAP><FONT SIZE="-1">
	    <A HREF="[path_cgi]/review/[list]/1/[size]/date" >
	    <b>Feliratkozott</b></A></FONT>
	  [ENDIF]
          </TH>
	  <TH><FONT SIZE="-1"><B>Utolsó módosítás</B></FONT></TH>
	[IF additional_fields]
	<TH><FONT SIZE="-1"><B>[additional_fields]</B></FONT></TH>
	[ENDIF]
        [ENDIF]
      </TR>
      
      [FOREACH u IN members]
	[IF dark=1]
	  <TR BGCOLOR="[shaded_color]">
	[ELSE]
          <TR>
	[ENDIF]

	 [IF is_owner]
	    <TD>
	        <INPUT TYPE=checkbox name="email" value="[u->escaped_email]">
	    </TD>
	 [ENDIF]
	 [IF u->bounce]
	  <TD NOWRAP><FONT SIZE=-1>
	 
	      [IF is_owner]
		<A HREF="[path_cgi]/editsubscriber/[list]/[u->escaped_email]/review">[u->email]</A>
	      [ELSE]
 	        [u->email]
 	      [ENDIF]
	  </FONT></TD>
            <TD ALIGN="right"BGCOLOR="[error_color]"><FONT SIZE=-1>
		<FONT COLOR="[bg_color]"><B>visszadobások</B></FONT>
	    </TD>

	 [ELSE]
	  <TD COLSPAN=2 NOWRAP><FONT SIZE=-1>
	      [IF is_owner]
		<A HREF="[path_cgi]/editsubscriber/[list]/[u->escaped_email]/review">[u->email]</A>
	      [ELSE]
	        [u->email]
	      [ENDIF]
	  </FONT></TD>
	 [ENDIF]

	  <TD>
             <FONT SIZE=-1>
	        [u->gecos]&nbsp;
	     </FONT>
          </TD>
	  [IF is_owner]
  	    <TD ALIGN="center"><FONT SIZE=-1>
  	      [u->reception]
	    </FONT></TD>
	    <TD ALIGN="center"NOWRAP><FONT SIZE=-1>
	      [u->date]
	    </FONT></TD>
	    <TD ALIGN="center"NOWRAP><FONT SIZE=-1>
	      [u->update_date]
	    </FONT></TD>
	  [IF additional_fields]
	    <TD ALIGN="center"NOWRAP><FONT SIZE=-1>
	      [u->additional]
	    </FONT></TD>
	  [ENDIF]

       	  [ENDIF]
        </TR>

        [IF dark=1]
	  [SET dark=0]
	[ELSE]
	  [SET dark=1]
	[ENDIF]

        [END]


      </TABLE>
    <TABLE WIDTH=100% BORDER=0>
    <TR><TD ALIGN="left">
      [IF is_owner]

        <!--INPUT TYPE="button" NAME="action_del" VALUE="Töröld a kijelölt e-mail címeket" onClick="request_confirm(this.form,'Tényleg szeretnéd az ÖSSZES kiejölt tagot törölni?')"-->

	<INPUT TYPE="submit" NAME="action_del" VALUE="Kijelöltek törlése">

        <INPUT TYPE="checkbox" NAME="quiet"> nincs értesítés
      [ENDIF]
    </TD>

   [IF action<>search]
    <TD ALIGN="right">
       [IF prev_page]
	 <A HREF="[path_cgi]/review/[list]/[prev_page]/[size]/[sortby]"><IMG SRC="/icons/left.png" BORDER=0 ALT="Elõzõ oldal"></A>
       [ENDIF]
       [IF page]
  	  Oldalak [page] / [total_page]
       [ENDIF]
       [IF next_page]
	  <A HREF="[path_cgi]/review/[list]/[next_page]/[size]/[sortby]"><IMG SRC="/icons/right.png" BORDER=0 ALT="Következõ oldal"></A>
       [ENDIF]
    </TD>
   [ENDIF]
    </TR>
    [IF is_owner]
    <TR><TD><input type=button value="Kijelölés megfordítása" onClick="toggle_selection(document.myform.email)">
    </TD></TR>
    [ENDIF]
    </TABLE>
    </FORM>






