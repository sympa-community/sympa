<!-- RCS Identication ; $Revision$ ; $Date$ -->

<TABLE WIDTH="100%" BORDER=0 CELLPADDING=10>
      <TR VALIGN="top">
        <TD NOWRAP>
          <FORM ACTION="[path_cgi]" METHOD=POST>
            <FONT COLOR="--DARK_COLOR--"><B>Editer les "templates" par défaut des listes</B></FONT><BR>
             <SELECT NAME="file">
              [FOREACH f IN lists_default_files]
                <OPTION VALUE='[f->NAME]' [f->selected]>[f->complete]
              [END]
            </SELECT>
            <INPUT TYPE="submit" NAME="action_editfile" VALUE="Editer">
          </FORM>

          <FORM ACTION="[path_cgi]" METHOD=POST>
            <FONT COLOR="--DARK_COLOR--"><B>Editer les "templates" du serveur</B></FONT><BR>
             <SELECT NAME="file">
              [FOREACH f IN server_files]
                <OPTION VALUE='[f->NAME]' [f->selected]>[f->complete]
              [END]
            </SELECT>
            <INPUT TYPE="submit" NAME="action_editfile" VALUE="Editer">
          </FORM>
        </TD>
      </TR>
      <TR><TD><A HREF="[path_cgi]/get_pending_lists"><B>Listes en attente</B></A></TD></TR>

      <TR><TD NOWRAP>
        <FORM ACTION="[path_cgi]" METHOD="POST">
	  <INPUT NAME="email" SIZE="30" VALUE="[email]">
	  <INPUT TYPE="submit" NAME="action_search_user" VALUE="Rechercher un utilisateur">
	</FORM>     
      </TD></TR>

      <TR><TD><A HREF="[path_cgi]/view_translations"><B>Voir les traductions des "templates"</B></A></TD></TR>
      <TR>
        <TD>
<FONT COLOR="--DARK_COLOR--"><B>>Reconstruire les archives HTML</B> en utilisant les répertoires  <CODE>arctxt</CODE>.
        </TD>
      </TR>
      <TR>
        <TD>
          <FORM ACTION="[path_cgi]" METHOD=POST>
          <INPUT TYPE="submit" NAME="action_rebuildallarc" VALUE="TOUTES"><BR>
        Attention, cela peut prendre beaucoup de temps CPU !
          </FORM>
        </TD>

    <TD ALIGN="CENTER"> 
          <FORM ACTION="[path_cgi]" METHOD=POST>
          <INPUT TYPE="text" NAME="list" SIZE="20">
          <INPUT TYPE="submit" NAME="action_rebuildarc" VALUE="Reconstruire l'archive">
          </FORM>
    </TD>


      </TR>

      <TR>
        <TD>
          <FONT COLOR="--DARK_COLOR--">
          <A HREF="[path_cgi]/scenario_test">
             <b>Module de test des scénarii</b>
          </A>
          </FONT>
        </TD>
      </TR>
        
    </TABLE>


