<!-- RCS Identication ; $Revision$ ; $Date$ -->

<FORM ACTION="[path_cgi]" METHOD="POST">

[IF file]
  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
  <INPUT TYPE="hidden" NAME="file" VALUE="[file]">
<TEXTAREA NAME="content" COLS=80 ROWS=25>
[INCLUDE filepath]
</TEXTAREA>
  <INPUT TYPE="submit" NAME="action_savefile" VALUE="Ulo¾it">

[ELSE]
<DD><INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	     <SELECT NAME="file">
	      [FOREACH f IN files]
	        <OPTION VALUE="[f->NAME]" [f->selected]>[f->complete]
	      [END]
	    </SELECT>
	    <INPUT TYPE="submit" NAME="action_editfile" VALUE="Upravit">

<P>
[PARSE '/home/sympa/bin/etc/wws_templates/help_editfile.cz.tpl']

[ENDIF]
</FORM>

