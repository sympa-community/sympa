<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF help_topic]
 [PARSE help_template]

[ELSE]
<BR>
WWSympa provides  you access to your environment on mailing list server
<B>[conf->email]@[conf->host]</B>.
<BR><BR>
Functions, equivalent to Sympa robot commands, are accessible in
the higher part of the user interface's banner. WWSympa provides 
a customized environment with access to the following functions :

<UL>
<LI><A HREF="[path_cgi]/pref">Preferences</A> : user preferences. This proposed to identified users only.

<LI><A HREF="[path_cgi]/lists">Public lists</A> : directory of lists available on the server

<LI><A HREF="[path_cgi]/which">Your subscriptions</A> : your environment as a subscriber or as owner

<LI><A HREF="[path_cgi]/loginrequest">Login</A> / <A HREF="[path_cgi]/logout">Logout</A> : Login / Logout from WWSympa.
</UL>

<H2>Login</H2>

[IF ldap_auth=classic]
When authentifying (<A HREF="[path_cgi]/loginrequest">Login</A>), provide your email address and associated password.
<BR><BR>
Once are authentified, a <I>cookie</I> containing your login 
information make your connection to WWSympa last. The lifetime of this 
<I>cookie</I> is customizeable through your  
<A HREF="[path_cgi]/pref">preferences</A>. 

<BR><BR>
[ENDIF]

You can logout (deletion of the <I>cookie</I>) at any time using 
<A HREF="[path_cgi]/logout">logout</A>
function.

<H5>Login issues</H5>

<I>I am not a list subscriber </I><BR>
Your are therefore not registered in Sympa user database and you can't login.
If you subscribe to a list, WWSympa will give you an initial password.
<BR><BR>

<I>I am subscriber to at least one list but I have no password</I><BR>
To receive your password : 
<A HREF="[path_cgi]/remindpasswd">[path_cgi]/remindpasswd</A>
<BR><BR>

<I>I forgot my password</I><BR>

WWSympa can remind you your password by email :
<A HREF="[path_cgi]/remindpasswd">[path_cgi]/remindpasswd</A>

<P>

To contact this service administrator : <A HREF="mailto:listmaster@[conf->host]">listmaster@[conf->host]</A>
[ENDIF]













