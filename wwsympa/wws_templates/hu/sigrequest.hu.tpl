<!-- RCS Identication ; $Revision$ ; $Date$ -->

  [IF status=auth]
      Le szeretnél iratkozni a(z) [list] listáról. <BR>Leiratkozásod
      megerõsítéséhez kattints a lenti gombra:<BR>
	<BR>

	<FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[user->email]">
	  <INPUT TYPE="submit" NAME="action_signoff" VALUE="[list] listáról leiratkozom">
	</FORM>

  [ELSIF not_subscriber]

      Nem vagy a(z) [list] listán nyílvántartva [email] 
      email címmel.
      <BR><BR>
      Lehet, hogy a listára másik címmel iratkoztál fel.
      Kérlek ez esetben keresd fel a lista tulajdonosát leiratkozásodhoz:
      <A HREF="mailto:[list]-request@[conf->host]">[list]-request@[conf->host]</A>
      
  [ELSIF init_passwd]
	Le szeretnél iratkozni a(z) [list] listáról.
	<BR><BR>
	Azonosításodhoz és hogy mások tudtod nélkül ne tudjanak leiratni 
	levélben kapsz egy pontos internet címet (URL).<BR><BR>

	A Sympa által küldött levélben található jelszót kell itt megadnod
	a(z) [list] listáról való leiratkozásodhoz.
	
        <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="#330099"><B>Email cím</B> </FONT>[email]<BR>
            <FONT COLOR="#330099"><B>Jelszó</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
        &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_signoff" VALUE="Leiratkozás">
        </FORM>

	A jelszavaddal és email címeddel az egyéni beállításaidat
	tudod késöbb megváltoztatni.

  [ELSIF ! email]
      Kérlek add meg az email címedet a(z) [list] listáról való leiratkozási kérelemhez.

      <FORM ACTION="[path_cgi]" METHOD=POST>
          <B>Email címed:</B> 
          <INPUT NAME="email"><BR>
          <INPUT TYPE="hidden" NAME="action" VALUE="sigrequest">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
         </FORM>


  [ELSE]

	A(z) [list] listaról való leiratkozás megerõsítéséhez add meg
	lent a jelszavadat:

         <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="#330099"><B>e-mail address</B> </FONT>[email]<BR>
            <FONT COLOR="#330099"><B>password</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
         &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_signoff" VALUE="Leiratkozás">

<BR><BR>
<I>Ha a szerveren nincsen jelszavad, vagy elfelejtetted, akkor klikk ide:</I>  <INPUT TYPE="submit" NAME="action_sendpasswd" VALUE="Küldd el a jelszavamat">

         </FORM>

  [ENDIF]      













