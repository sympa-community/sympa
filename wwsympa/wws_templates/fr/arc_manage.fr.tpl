
<!-- begin arc_manage.fr.tpl -->
<Hr><b>Gestion des Archives</b>
<BR>
Sélectionnez ci-dessous les mois d'Archives que vous voulez supprimer ou télécharger (au format Zip) :
<DL>
<DT>Selection des Archives :
<FORM METHOD=POST ACTION="[path_cgi]">
<SELECT NAME="directories" MULTIPLE SIZE=4>    

	[FOREACH u IN yyyymm]

	<OPTION	VALUE="[u]">[u]

	[END] 
	
</SELECT>
<INPUT NAME=list TYPE=hidden VALUE="[list]">
<INPUT NAME="zip" TYPE=hidden VALUE="0">
<INPUT Type="submit" NAME="action_arc_download" VALUE="Télécharger le Zip">
<INPUT Type="submit" NAME="action_arc_delete" VALUE="Détruire les mois sélectionnés " onClick="return dbl_confirm(this.form,'Etes-vous sur(e) de vouloir supprimer les archives sélectionnées ?','Voulez-vous télécharger le Zip des archives Sélectionnées avant suppression?')">
</DL>
</FORM>
<Hr>
<!-- end  arc_manage.fr.tpl -->