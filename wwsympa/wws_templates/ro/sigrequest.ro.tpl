<!-- RCS Identication ; $Revision$ ; $Date$ -->
[IF status=auth] 
Ai cerut sa fii dezabonat de pe lista [list]. <BR> Pentru a confirma aceasta cerere, da click pe butonul de mai jos:<BR>
	<BR>

	<FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[user->email]">
	  
  <INPUT TYPE="submit" NAME="action_signoff" VALUE="Ma dezabonez de pe lista [list]">
	</FORM>

  [ELSIF not_subscriber] 
Nu esti inscris pe lista [list] cu adresa email [email]. 
<BR>
<BR>
Poate te-ai inscris cu o alta adresa. Contacteaza proprietarul listei pentru a 
te ajuta sa te dezabonezi: <A HREF="mailto:[list]-request@[conf->host]">[list]-request@[conf->host]</A> 
[ELSIF init_passwd] 
Ai cerut sa te dezabonezi de la lista [list]. <BR>
<BR>
Pentru confirmarea identitatii si pentru a preveni sa fii dezbonat de o alta persoana 
vei primi un mesaj care va contine un URL. <BR>
<BR>
Verifica-ti contul daca ai mesaje noi si introdu mai jos parola din mesajul trimis 
de Sympa. Astfel poti sa confirmi dezabonarea de la lista [list]. 
<FORM ACTION="[path_cgi]" METHOD=POST>
  <FONT COLOR="[dark_color]"><B> adresa e-mail </B></FONT>[email]<BR>
  <FONT COLOR="[dark_color]"><B>parola</B> </FONT> 
  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
        &nbsp; &nbsp; &nbsp;
  <INPUT TYPE="submit" NAME="action_signoff" VALUE="Dezabonare">
        </FORM>

      	This password, associated to your email address, will
	allow you to access your custom environment.

  [ELSIF ! email]
      Please gives your email address for your unsubscription request from list [list].

      <FORM ACTION="[path_cgi]" METHOD=POST>
  <B>Adresa ta de e-mail:</B> 
  <INPUT NAME="email"><BR>
          <INPUT TYPE="hidden" NAME="action" VALUE="sigrequest">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  
  <INPUT TYPE="submit" NAME="action_sigrequest" VALUE="Dezabonare">
         </FORM>


  [ELSE] 
Pentru a confirma dezabonarea de la lista [list], introdu mai jos parola: 
<FORM ACTION="[path_cgi]" METHOD=POST>
  <FONT COLOR="[dark_color]"><B>adresa e-mail</B> </FONT>[email]<BR>
  <FONT COLOR="[dark_color]"><B>parola</B> </FONT> 
  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
         &nbsp; &nbsp; &nbsp;
  <INPUT TYPE="submit" NAME="action_signoff" VALUE="Dezabonare">

<BR><BR>
  <I>Daca nu ai avut niciodata parola pe acel server sau ai uitat-o :</I> 
  <INPUT TYPE="submit" NAME="action_sendpasswd" VALUE="Trimite-mi parola">

         </FORM>

  [ENDIF]      













