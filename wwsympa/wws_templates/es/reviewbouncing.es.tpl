<!-- RCS Identication ; $Revision$ ; $Date$ -->

<SCRIPT LANGUAGE="JavaScript">
<!-- for other browsers
  function remind_confirm(my_form, my_total){
    var message;
    message = "¿Confirma la emisión de un recordatorio de suscripción a "+ my_total +" suscriptores?";
    if (window.confirm(message)) {
      my_form.submit();
    }
  }
// end borwsers -->
</SCRIPT>

<TABLE width=100% border="0" VALIGN="top">
<TR><TD>
    <FORM ACTION="[path_cgi]" METHOD=POST> 
      <INPUT TYPE="hidden" NAME="previous_action" VALUE="reviewbouncing">
      <INPUT TYPE=hidden NAME=list VALUE=[list]>
      <INPUT TYPE="hidden" NAME="action" VALUE="search">

      <INPUT SIZE=25 NAME=filter VALUE=[filter]>
      <INPUT TYPE="submit" NAME="action_search" VALUE="Buscar">
    </FORM>
</TD>
<TD>
  <FORM METHOD="post" ACTION="[path_cgi]">
    <INPUT TYPE="button" VALUE="Recordatorio a los suscriptores" NAME="action_remind" onClick="remind_confirm(this.form,[total])">
    <INPUT TYPE="hidden" NAME="action" VALUE="remind">
    <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
  </FORM>	
</TD>

</TR></TABLE>
    <FORM ACTION="[path_cgi]" METHOD=POST>
    <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
    <INPUT TYPE="hidden" NAME="previous_action" VALUE="reviewbouncing">

    <TABLE WIDTH=100% BORDER=0>
    <TR><TD ALIGN="left" NOWRAP>
        <BR>
        <INPUT TYPE="submit" NAME="action_del" VALUE="Borrar email's seleccionados">
        <INPUT TYPE="checkbox" NAME="quiet"> silencioso

	<INPUT TYPE="hidden" NAME="sortby" VALUE="[sortby]">
	<INPUT TYPE="submit" NAME="action_reviewbouncing" VALUE="Tamaño Pag.">
	        <SELECT NAME="size">
                  <OPTION VALUE="[size]" SELECTED>[size]
		  <OPTION VALUE="25">25
		  <OPTION VALUE="50">50
		  <OPTION VALUE="100">100
		   <OPTION VALUE="500">500
		</SELECT>
   </TD>

 <TD ALIGN="right">
        [IF prev_page]
	  <A HREF="[path_cgi]/reviewbouncing/[list]/[prev_page]/[size]"><IMG SRC="/icons/left.png" BORDER=0 ALT="Pág. previa"></A>
        [ENDIF]
        [IF page]
  	  pág [page] / [total_page]
        [ENDIF]
        [IF next_page]
	  <A HREF="[path_cgi]/reviewbouncing/[list]/[next_page]/[size]"><IMG SRC="/icons/right.png" BORDER=0ALT="Pág. sig."></A>
        [ENDIF]
    </TD></TR>
    <TR><TD><INPUT TYPE="submit" NAME="action_resetbounce" VALUE="Inicializar errores de los usuarios seleccionados">
    </TD></TR>
    </TABLE>

    <TABLE WIDTH="100%" BORDER=1>
      <TR BGCOLOR="[error_color]" NOWRAP>
	<TH><FONT COLOR="[bg_color]">X</FONT></TH>
        <TH><FONT COLOR="[bg_color]">E-mail</FONT></TH>
	<TH><FONT COLOR="[bg_color]">Nro. Errores</FONT></TH>
	<TH><FONT COLOR="[bg_color]">Período</FONT></TH>
	<TH NOWRAP><FONT COLOR="[bg_color]">tipo</FONT></TH>
      </TR>
      
      [FOREACH u IN members]
	[IF dark=1]
	  <TR BGCOLOR="[shaded_color]">
	[ELSE]
          <TR>
	[ENDIF]

	  <TD>
	    <INPUT TYPE=checkbox name="email" value="[u->escaped_email]">
	  </TD>
	  <TD NOWRAP><FONT SIZE=-1>
	      <A HREF="[path_cgi]/editsubscriber/[list]/[u->escaped_email]/reviewbouncing">[u->email]</A>

	  </FONT></TD>
          <TD ALIGN="center"><FONT SIZE=-1>
  	      [u->bounce_count]
	    </FONT></TD>
	  <TD NOWRAP ALIGN="center"><FONT SIZE=-1>
	    du [u->first_bounce] au [u->last_bounce]
	  </FONT></TD>
	  <TD NOWRAP ALIGN="center"><FONT SIZE=-1>
	    [IF u->bounce_class=2]
	    	success
	    [ELSIF u->bounce_class=4]
		temporary
	    [ELSIF u->bounce_class=5]
		permanent
	    [ENDIF]
	  </FONT></TD>
        </TR>
        [IF dark=1]
	  [SET dark=0]
	[ELSE]
	  [SET dark=1]
	[ENDIF]

        [END]


      </TABLE>
    <TABLE WIDTH=100% BORDER=0>
    <TR><TD ALIGN="left" NOWRAP>
      [IF is_owner]
        <BR>
        <INPUT TYPE="submit" NAME="action_del" VALUE="Borrar email's seleccionados">
        <INPUT TYPE="checkbox" NAME="quiet"> silencioso
    <INPUT TYPE="submit" NAME="action_resetbounce" VALUE="Inicializar errores de los usuarios seleccionados">
      [ENDIF]
    </TD><TD ALIGN="right" NOWRAP>
        [IF prev_page]
	  <A HREF="[path_cgi]/reviewbouncing/[list]/[prev_page]/[size]"><IMG SRC="/icons/left.png" BORDER=0 ALT="Pg. previa"></A>
        [ENDIF]
        [IF page]
  	  page [page] / [total_page]
        [ENDIF]
        [IF next_page]
	  <A HREF="[path_cgi]/reviewbouncing/[list]/[next_page]/[size]"><IMG SRC="/icons/right.png" BORDER=0ALT="Pág. sig."></A>
        [ENDIF]
    </TD></TR>
    </TABLE>


      </FORM>



