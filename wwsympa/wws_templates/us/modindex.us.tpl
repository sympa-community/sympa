<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF mod_total ]
<!-- moderation of messages -->
  <FORM ACTION="[path_cgi]" METHOD=POST>
  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
  <h2> <B> Listing messages to moderate </B> </h2> 
<TABLE>
<TR BGCOLOR="[bg_color]"><TD>
  <INPUT TYPE="submit" NAME="action_distribute" VALUE="Distribute">
  <INPUT TYPE="submit" NAME="action_reject.quiet" VALUE="Reject">
  <INPUT TYPE="submit" NAME="action_reject" VALUE="Notified reject">
</TD></TR></TABLE>  
    <TABLE BORDER="1" WIDTH="100%">
      <TR BGCOLOR="[dark_color]">
	<TH><FONT COLOR="[bg_color]">X</FONT></TH>
        <TH><FONT COLOR="[bg_color]">Date</FONT></TH>
	<TH><FONT COLOR="[bg_color]">Author</FONT></TH>
	<TH><FONT COLOR="[bg_color]">Subject</FONT></TH>
	<TH><FONT COLOR="[bg_color]">Size</FONT></TH>
      </TR>	 
      [FOREACH msg IN spool]
        <TR>
         <TD>
            <INPUT TYPE=checkbox name="id" value="[msg->NAME]">
	 </TD>
	  <TD>
	    [IF msg->date]
	      <FONT SIZE=-1>[msg->date]</FONT>
	    [ELSE]
	      &nbsp;
	    [ENDIF]
	  </TD>
	  <TD><FONT SIZE=-1>[msg->from]</FONT></TD>
	  <TD>
	    [IF msg->subject=no_subject]
	      <A HREF="[path_cgi]/viewmod/[list]/[msg->NAME]"><FONT SIZE=-1>No subject</FONT></A>
	    [ELSE]
	      <A HREF="[path_cgi]/viewmod/[list]/[msg->NAME]"><FONT SIZE=-1>[msg->subject]</FONT></A>
	    [ENDIF]
	  </TD>
	  <TD><FONT SIZE=-1>[msg->size] kb</FONT></TD>
	</TR>
      [END] 
    </TABLE>
<TABLE>
<TR BGCOLOR="[bg_color]"><TD>
  <INPUT TYPE="submit" NAME="action_distribute" VALUE="Distribute">
  <INPUT TYPE="submit" NAME="action_reject.quiet" VALUE="Reject">
  <INPUT TYPE="submit" NAME="action_reject" VALUE="Notified reject">
</TD></TR></TABLE>
</FORM>
[ENDIF]


<!-- moderation of document shared -->
[IF mod_total_shared]
  <FORM ACTION="[path_cgi]" METHOD=POST>
  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
  <h2> <B> Listing of documents shared to moderate </B> </h2> 
<TABLE>
<TR BGCOLOR="[bg_color]"><TD>
  <INPUT TYPE="submit" NAME="action_d_install_shared" VALUE="Install">
  <INPUT TYPE="submit" NAME="action_d_reject_shared.quiet" VALUE="Reject">
  <INPUT TYPE="submit" NAME="action_d_reject_shared" VALUE="Notified reject">
</TD></TR></TABLE>  
    <TABLE BORDER="1" WIDTH="100%">
      <TR BGCOLOR="[dark_color]">
	<TH><FONT COLOR="[bg_color]">X</FONT></TH>
        <TH><FONT COLOR="[bg_color]">Date</FONT></TH>
	<TH><FONT COLOR="[bg_color]">Author</FONT></TH>
	<TH><FONT COLOR="[bg_color]">Path</FONT></TH>
	<TH><FONT COLOR="[bg_color]">Size</FONT></TH>
      </TR>	 
      [FOREACH f IN info_doc_mod]
        <TR>
         <TD>
            <INPUT TYPE=checkbox name="id" value="[f->visible_path][f->fname]">
	 </TD>
	  <TD>
	    [IF f->date]
	      <FONT SIZE=-1>[f->date]</FONT>
	    [ELSE]
	      &nbsp;
	    [ENDIF]
	  </TD>
	  <TD><FONT SIZE=-1>[f->author]</FONT></TD>
	  <TD>
	    <A HREF="[path_cgi]/d_read/[list][f->visible_path][f->fname]"><FONT SIZE=-1>[f->visible_path][f->visible_fname]</FONT></A>
	  </TD>
	  <TD><FONT SIZE=-1>[f->size] kb</FONT></TD>
	</TR>
      [END] 
    </TABLE>

<TABLE>
<TR BGCOLOR="[bg_color]"><TD>
  <INPUT TYPE="submit" NAME="action_d_install_shared" VALUE="Install">
  <INPUT TYPE="submit" NAME="action_d_reject_shared.quiet" VALUE="Reject">
  <INPUT TYPE="submit" NAME="action_d_reject_shared" VALUE="Notified reject">
</TD></TR></TABLE>

</FORM>

[ENDIF]











