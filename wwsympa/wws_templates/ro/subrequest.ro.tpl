<!-- RCS Identication ; $Revision$ ; $Date$ -->
[IF status=auth] 
Ai cerut inscrierea in lista[list]. <BR> Pentru a confirma cererea da click pe butonul de mai jos:<BR>
	<BR>

	<FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[user->email]">
	  
  <INPUT TYPE="submit" NAME="action_subscribe" VALUE="Ma inscriu pe lista [list]">
	</FORM>

  [ELSIF status=notauth_passwordsent] 
Ai cerut inscrierea pe lista [list]. <BR>
<BR>
Pentru confirmarea identitatii tale si a preveni sa fi inscris impotriva vointei 
tale, vei primi un mesaj care va contine parola ta. <BR>
<BR>
Verifica-ti contul de mail si introdu mai jos parola. Astfel iti vei confirma 
iscrierea pe lista [list]. 
<FORM ACTION="[path_cgi]" METHOD=POST>
  <FONT COLOR="[dark_color]"><B>adresa email</B> </FONT>[email]<BR>
  <FONT COLOR="[dark_color]"><B>parola</B> </FONT> 
  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
	  <INPUT TYPE="hidden" NAME="previous_list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="previous_action" VALUE="subrequest">
        &nbsp; &nbsp; &nbsp;
  <INPUT TYPE="submit" NAME="action_subscribe" VALUE="Inscrie-te">
        </FORM>

      	Aceasta parola, impreuna cu adresa de email, iti va permite accesul la 
un mediu cusomizabil. 
[ELSIF status=notauth_noemail] 
<FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="[dark_color]"><B>Your e-mail address</B> </font>
	  <INPUT  NAME="email" SIZE="30"><BR>
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="action" VALUE="subrequest">
	  
  <INPUT TYPE="submit" NAME="action_subrequest" VALUE="Trimite">
         </FORM>


  [ELSIF status=notauth] 
Pentru a confirma inscrierea la lista [list], te rog 
scrie-ti parola mai jos : 
<FORM ACTION="[path_cgi]" METHOD=POST>
  <FONT COLOR="[dark_color]"><B>adresa e-mail</B> </FONT>[email]<BR>
  <FONT COLOR="[dark_color]"><B>parola</B> </FONT> 
  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
	  <INPUT TYPE="hidden" NAME="previous_list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="previous_action" VALUE="subrequest">
         &nbsp; &nbsp; &nbsp;
  <INPUT TYPE="submit" NAME="action_subscribe" VALUE="Inscrie-te">
  <input type="submit" name="action_sendpasswd" value="Parola mea ?">
</FORM>

  [ELSIF status=notauth_subscriber] 
<FONT COLOR="[dark_color]"><B>Esti deja inscris 
pe aceasta lista [list].</b> </FONT> <BR>
<BR>
[PARSE '/home/sympa/bin/etc/wws_templates/loginbanner.ro.tpl'] 
[ENDIF] 
