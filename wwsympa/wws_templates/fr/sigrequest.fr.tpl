<!-- RCS Identication ; $Revision$ ; $Date$ -->

  [IF status=auth]

        Vous avez demandé à vous désabonner de la liste [list], merci de confirmer
        cette demande :<BR>
	<BR>
	<FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[user->email]">
	  <INPUT TYPE="submit" NAME="action_signoff" VALUE="Je me désabonne de [list]">
	</FORM>

  [ELSIF not_subscriber]
      Vous n'êtes pas abonné à la liste [list], en tout cas pas avec l'adresse [email].
      <BR><BR>
	Peut-être êtes vous abonné avec une autre adresse ? Dans ce cas connectez
        vous avec celle-ci. En cas de difficultés, contactez le propriétaire de la
        liste : <A HREF="mailto:[list]-request@[conf->host]">[list]-request@[conf->host]</A>
      
  [ELSIF init_passwd]
	Vous avez demandé un désabonnement de la liste [list]. 
	<BR><BR>
	Pour confirmer votre identité et empêcher un tiers de vos désabonner, le
        serveur vient de vous poster un message avec un mot de passe
        de confirmation à l'adresse [email].

	Relevez votre boîte aux lettres pour renseigner votre mot de passe. Cela confirmera
        votre demande de désabonnement de [list].
	
        <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="[dark_color]"><B>adresse e-mail</B> </FONT>[email]<BR>
            <FONT COLOR="[dark_color]"><B>mot de passe</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
        &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_signoff" VALUE="Désabonnement">
        </FORM>

      	Ce mot de passe associé à votre adresse [email] permettra d'accéder complètement
        à votre environement personnel.

  [ELSIF ! email]
      Indiquez votre adresse pour votre demande de désabonnement de
      la liste [list].

      <FORM ACTION="[path_cgi]" METHOD=POST>
          <B>Votre adresse :</B> 
          <INPUT NAME="email"><BR>
          <INPUT TYPE="hidden" NAME="action" VALUE="sigrequest">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="submit" NAME="action_sigrequest" VALUE="désabonnement">
         </FORM>


  [ELSE]

	Pour confirmer votre demande de désabonnement de la liste [list],
        merci de renseigner votre mot de passe ci-dessous :

         <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="[dark_color]"><B>adresse e-mail</B> </FONT>[email]<BR>
            <FONT COLOR="[dark_color]"><B>mot de passe</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
         &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_signoff" VALUE="désabonnement">
<BR><BR>

<I>Si vous n'avez jamais eu de mot de passe ou si vous l'avez oublié :</I>
<INPUT TYPE="submit" NAME="action_sendpasswd" VALUE="envoyez moi mon mot de passe">
         </FORM>


  [ENDIF]      



