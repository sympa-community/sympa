<!-- RCS Identication ; $Revision$ ; $Date$ -->

  [IF status=auth]
      Soovisite lahkuda listist [list]. <BR>Kinnitamaks oma soovi, palun
      klikkige allolevale nupule:<BR><BR>

	<FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[user->email]">
	  <INPUT TYPE="submit" NAME="action_signoff" VALUE="Soovin lahkuda listist [list]">
	</FORM>

  [ELSIF not_subscriber]

      Te ei ole listi [list] liige e-posti aadressilt
      [email].
      <BR><BR>
      Te võite olla listi liige mõne teise e-postiaadressiga.
      Listist lahkumiseks võtke ühendust listiomanikega:
      <A HREF="mailto:[list]-request@[conf->host]">[list]-request@[conf->host]</A>
      
  [ELSIF init_passwd]
	Soovisite lahkuda listist [list].
	<BR><BR>
	Selleks, et keegi teine ei saaks teid listist vastu teie tahtmist
	eemaldada, saadetakse teile kiri, milles on parool. <BR><BR>

	Sisestage siia saadud parool. See kinnitab teie soovi lahkuda listist
	[list].
	
        <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="[dark_color]"><B>e-posti aadress</B> </FONT>[email]<BR>
            <FONT COLOR="[dark_color]"><B>parool</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
        &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_signoff" VALUE="Lahkun">
        </FORM>

	Seesama parool koos e-postiaadressiga võimaldab teil kasutada Sympa
	veebikeskkonna kõiki võimalusi.

  [ELSIF ! email]
	Palun sisestage oma e-postiaadress listist [list] lahkumiseks.

      <FORM ACTION="[path_cgi]" METHOD=POST>
          <B>Teie e-postiaadress :</B> 
          <INPUT NAME="email"><BR>
          <INPUT TYPE="hidden" NAME="action" VALUE="sigrequest">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="submit" NAME="action_sigrequest" VALUE="Lahkun">
         </FORM>


  [ELSE]

	Listist [list] lahkumiseks sisestage siia oma parool:

         <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="[dark_color]"><B>e-posti aadress</B> </FONT>[email]<BR>
            <FONT COLOR="[dark_color]"><B>parool</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
         &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_signoff" VALUE="Lahkun">

<BR><BR>
<I>Kui teil ei ole parooli või te ei suuda seda meenutada:</I>  <INPUT TYPE="submit" NAME="action_sendpasswd" VALUE="Palun saatke mulle mu parool">

         </FORM>

  [ENDIF]      













