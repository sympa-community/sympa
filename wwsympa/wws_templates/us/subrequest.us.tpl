<!-- RCS Identication ; $Revision$ ; $Date$ -->

  [IF status=auth]

	You requested subscription to list [list]. <BR>To confirm
	your request, please click the button bellow :<BR>
	<BR>

	<FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[user->email]">
	  <INPUT TYPE="submit" NAME="action_subscribe" VALUE="I subscribe to list [list]">
	</FORM>

  [ELSIF status=notauth_passwordsent]

    	You requested a subscription to list [list]. 
	<BR><BR>
	To confirm your identity and avoid anyeone from subscribing you to 
	this list against your will, a message containing your password
	will be sent to you. <BR><BR>

	Check your mailbox for new messages and enter below the
	password. This will confirm your subrscription to list [list].
	
        <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="--DARK_COLOR--"><B>e-mail address</B> </FONT>[email]<BR>
	  <FONT COLOR="--DARK_COLOR--"><B>password</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
	  <INPUT TYPE="hidden" NAME="previous_list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="previous_action" VALUE="subrequest">
        &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_subscribe" VALUE="Subscribe">
        </FORM>

      	This password, associated to your email address, will
	allow you to access your custom environment.

  [ELSIF status=notauth_noemail]

         <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="--DARK_COLOR--"><B>Your e-mail address</B> 
	  <INPUT  NAME="email" SIZE="30"><BR>
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="action" VALUE="subrequest">
	  <INPUT TYPE="submit" NAME="action_subrequest" VALUE="submit">
         </FORM>


  [ELSIF status=notauth]

	To confirm your subscription to list [list], please enter
	your password below :

         <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="--DARK_COLOR--"><B>e-mail address</B> </FONT>[email]<BR>
            <FONT COLOR="--DARK_COLOR--"><B>password</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
	  <INPUT TYPE="hidden" NAME="previous_list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="previous_action" VALUE="subrequest">
         &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_subscribe" VALUE="Subscribe">
	<INPUT TYPE="submit" NAME="action_sendpasswd" VALUE="My password ?">
         </FORM>

  [ELSIF status=notauth_subscriber]

	<FONT COLOR="--DARK_COLOR--"><B>You are already subscriber of list [list].
	</FONT>
	<BR><BR>


	[PARSE '--ETCBINDIR--/wws_templates/loginbanner.us.tpl']

  [ENDIF]      



