<!-- RCS Identication ; $Revision$ ; $Date$ -->

<FORM ACTION="[path_cgi]" METHOD="POST">

[IF file]
  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
  <INPUT TYPE="hidden" NAME="file" VALUE="[file]">
<TEXTAREA NAME="content" COLS=80 ROWS=25>
[INCLUDE filepath]
</TEXTAREA>
  <INPUT TYPE="submit" NAME="action_savefile" VALUE="Sauvegarder">

[ELSE]
Cette fonction vous permet d'éditer certains fichiers associés à votre liste (messages de service).
Par défaut, SYMPA utilise des messages de service par défaut.
Dans ce cas, le fichier correpondant spécifique à votre liste est vide.
<BR>
Pour modifier un message personnalisé, choisissez-le dans la liste déroulante située à gauche du bouton "Editer", puis cliquez sur ce bouton.
Si le message personnalisé n'existe pas encore, le plus simple est de coller le texte du message par défaut dans le champ d'édition, puis de le modifier.
<BR>
Dans les messages de services énumérés ci-dessous, vous pouvez utiliser des <A HREF="[path_cgi]/help/variables" onClick="window.open('','wws_help','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes,resizable=yes,copyhistory=no,width=400,height=200')" TARGET="wws_help">variables</A>.

Vous pouvez éditer ci-dessous les messages de services et d'autres fichiers associés
à votre liste :<BR><BR>

<INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	     <SELECT NAME="file">
	      [FOREACH f IN files]
	        <OPTION VALUE="[f->NAME]" [f->selected]>[f->complete]
	      [END]
	    </SELECT>
	    <INPUT TYPE="submit" NAME="action_editfile" VALUE="Editer">

<P>
[PARSE '--ETCBINDIR--/wws_templates/help_editfile.fr.tpl']

[ENDIF]
</FORM>
