
<!-- begin arc_manage.us.tpl -->
<Hr><b>Archive Management</b>
<BR>
Select bellow Archives months you want to delete or download (ZiP format):
<DL>
<DT>Archives Selection :
<FORM  NAME= "zip_form" METHOD=POST ACTION= "[path_cgi]">
<SELECT NAME="directories" MULTIPLE SIZE=4>    

	[FOREACH u IN yyyymm]

	<OPTION	VALUE="[u]">[u]

	[END] 
	
</SELECT>
<INPUT NAME="list" TYPE=hidden VALUE="[list]">
<INPUT NAME="zip" TYPE=hidden VALUE="0">
<INPUT Type="submit" NAME="action_arc_download" VALUE="DownLoad ZipFile">
<INPUT Type="submit" NAME="action_arc_delete" VALUE="Delete Selected Month(s)" onClick="return dbl_confirm(this.form,'Do you really want to delete Selected Archives?','Do you want to DownLoad a Zip of the selected Archives before?')">
</DL>
</FORM>
<Hr>
<!-- end  arc_manage.us.tpl -->