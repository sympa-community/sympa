<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF help_topic]
 [PARSE help_template]

[ELSE]
<BR>
WWSympa geeft u toegang tot uw omgeving op de mailinglijst server
<B>[conf->email]@[conf->host]</B>.
<BR><BR>
Funkties, zoals ook beschikbaar als Sympa Robot commando's, zijn
toegankelijk via de web userinterface. WWSympa geeft een omgeving met
toegang tot de volgende funkties:

<UL>
<LI><A HREF="[path_cgi]/pref">Preferences</A> : gebruikers voorkeuren. Dit alleen voor ingelogde gebruikers.

<LI><A HREF="[path_cgi]/lists">Public lists</A> : inhoudsopgave van alle lijsten toegankelijk op deze server

<LI><A HREF="[path_cgi]/which">Your subscriptions</A> : uw omgeving als geabonneerde of eigenaar

<LI><A HREF="[path_cgi]/loginrequest">Inloggen</A> / <A HREF="[path_cgi]/logout">Uitloggen</A> : In- of uitloggen bij WWSympa.
</UL>

<H2>Inloggen</H2>

[IF auth=classic]
Wanneer u wilt inloggen (<A HREF="[path_cgi]/loginrequest">Login</A>), geef uw emailadres en bijbehorend wachtwoord.
<BR><BR>
Wanneer u bent geauthenticeerd, wordt een <I>cookie</I> met uw logininformatie 
weggeschreven om uw inlog vast te houden. De levensduur van dit 
<I>cookie</I> is veranderbaar door uw
<A HREF="[path_cgi]/pref">voorkeursinstellingen</A>. 

<BR><BR>
[ENDIF]

U kan uitloggen (weghalen van het <I>cookie</I>) op elk moment door de 
<A HREF="[path_cgi]/logout">logout</A>
funktie.

<H5>Login problemen</H5>

<I>Ik ben geen abonnee </I><BR>
U bent nog niet bekend in de Sympa gebruikersdatabase en u kan dus niet
inloggen. Wanneer u zich abonneerd op een lijst, zals Sympa u een initieel
wachtwoord geven.
<BR><BR>

<I>Ik ben op minimaal een lijst geabonneerd maar ik heb geen wachtwoord</I><BR>
Om uw wachtwoord te ontvangen : 
<A HREF="[path_cgi]/remindpasswd">[path_cgi]/remindpasswd</A>
<BR><BR>

<I>Ik ben mijn wachtwoord vergeten</I><BR>

WWSympa kan u herinneren aan uw wachtwoord per email :
<A HREF="[path_cgi]/remindpasswd">[path_cgi]/remindpasswd</A>

<P>

Om in contact te komen met uw lijst beheerder : <A HREF="mailto:listmaster@[conf->host]">listmaster@[conf->host]</A>
[ENDIF]













