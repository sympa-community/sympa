<!-- RCS Identication ; $Revision$ ; $Date$ -->

  [IF status=auth]
      You requested unsubscription from list [list]. <BR>To confirm
      your request, please click the button bellow :<BR>
	<BR>

	<FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[user->email]">
	  <INPUT TYPE="submit" NAME="action_signoff" VALUE="I unsubscribe from list [list]">
	</FORM>

  [ELSIF not_subscriber]

      You are not subscribed to list [list] with e-mail address
      [email].
      <BR><BR>
      You might have subscribed with another address.
      Please contact the list owner to help you unsubscribe :
      <A HREF="mailto:[list]-request@[conf->host]">[list]-request@[conf->host]</A>
      
  [ELSIF init_passwd]
    	You requested unsubscription from list [list]. 
	<BR><BR>
	To confirm your identity and avoid anyeone from unsubscribing you from 
	this list against your will, a message containing an URL
	will be sent to you. <BR><BR>

	Check your mailbox for new messages and enter below the
	password given in the message Sympa sent you. This will
	confirm your unsubscription from list [list].
	
        <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="[dark_color]"><B>e-mail address</B> </FONT>[email]<BR>
            <FONT COLOR="[dark_color]"><B>password</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
        &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_signoff" VALUE="Unsubscribe">
        </FORM>

      	This password, associated to your email address, will
	allow you to access your custom environment.

  [ELSIF ! email]
      Please gives your email adresse for your unsubscription request from list [list].

      <FORM ACTION="[path_cgi]" METHOD=POST>
          <B>Your e-mail address :</B> 
          <INPUT NAME="email"><BR>
          <INPUT TYPE="hidden" NAME="action" VALUE="sigrequest">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="submit" NAME="action_sigrequest" VALUE="Unsubscribe">
         </FORM>


  [ELSE]

	To confirm your unsubscription from list [list], please enter
	your password below :

         <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="[dark_color]"><B>e-mail address</B> </FONT>[email]<BR>
            <FONT COLOR="[dark_color]"><B>password</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
         &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_signoff" VALUE="Unsubscribe">

<BR><BR>
<I>If you never had a password from that server or if you don't remember it :</I>  <INPUT TYPE="submit" NAME="action_sendpasswd" VALUE="Send me my password">

         </FORM>

  [ENDIF]      













