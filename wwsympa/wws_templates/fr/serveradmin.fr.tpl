<!-- RCS Identication ; $Revision$ ; $Date$ -->

<TABLE WIDTH="100%" BORDER=0 CELLPADDING=10>
      <TR VALIGN="top">
        <TD NOWRAP>
          <FORM ACTION="[path_cgi]" METHOD=POST>
            <FONT COLOR="[dark_color]"><B>Editer les "templates" par défaut des listes</B></FONT><BR>
             <SELECT NAME="file">
              [FOREACH f IN lists_default_files]
                <OPTION VALUE='[f->NAME]' [f->selected]>[f->complete]
              [END]
            </SELECT>
            <INPUT TYPE="submit" NAME="action_editfile" VALUE="Editer">
          </FORM>

          <FORM ACTION="[path_cgi]" METHOD=POST>
            <FONT COLOR="[dark_color]"><B>Editer les "templates" du serveur</B></FONT><BR>
             <SELECT NAME="file">
              [FOREACH f IN server_files]
                <OPTION VALUE='[f->NAME]' [f->selected]>[f->complete]
              [END]
            </SELECT>
            <INPUT TYPE="submit" NAME="action_editfile" VALUE="Editer">
          </FORM>
        </TD>
      </TR>
      <TR><TD>
     [PARSE '--ETCBINDIR--/wws_templates/button_header.tpl']
       <TD BGCOLOR="[light_color]" ALIGN="center" VALIGN="top">
      <A HREF="[path_cgi]/get_pending_lists">Listes en attente</A>
       </TD>
     [PARSE '--ETCBINDIR--/wws_templates/button_footer.tpl']

    </TD></TR>

      <TR><TD NOWRAP>
        <FORM ACTION="[path_cgi]" METHOD="POST">
	  <INPUT NAME="email" SIZE="30" VALUE="[email]">
	  <INPUT TYPE="hidden" NAME="action" VALUE="search_user">
	  <INPUT TYPE="submit" NAME="action_search_user" VALUE="Rechercher un utilisateur">
	</FORM>     
      </TD></TR>

      <TR><TD>
     [PARSE '--ETCBINDIR--/wws_templates/button_header.tpl']
       <TD BGCOLOR="[light_color]" ALIGN="center" VALIGN="top">
        <A HREF="[path_cgi]/view_translations">Voir les traductions des "templates"</A>
       </TD>
      [PARSE '--ETCBINDIR--/wws_templates/button_footer.tpl']
      </TD></TR>
      <TR>
        <TD>
<FONT COLOR="[dark_color]"><B>Reconstruire les archives HTML</B> en utilisant les répertoires  <CODE>arctxt</CODE>.
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
          <FONT COLOR="[dark_color]">
          <A HREF="[path_cgi]/scenario_test">
             <b>Module de test des scénarii</b>
          </A>
          </FONT>
        </TD>
      </TR>
        
    </TABLE>


