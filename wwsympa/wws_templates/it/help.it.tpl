<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF help_topic]
 [PARSE help_template]

[ELSE]
<BR>
WWSympa ti fornisce l'accesso interattivo ai servizi della mailing list del server 
<B>[conf->email]@[conf->host]</B>.
<BR><BR>
I servizi, equivalenti ai comandi del robot Sympa, sono accessibili
nella parte alta della schermata. WWSympa ti fornisce un ambiente
personalizzato con l'accesso alle seguenti funzioni:

<UL>
<LI><A HREF="[path_cgi]/pref">Preferenze</A> : viene proposto agli utenti che si identificano.

<LI><A HREF="[path_cgi]/lists">Liste pubbliche</A> : Directory delle liste disponibili

<LI><A HREF="[path_cgi]/which">Le mie liste</A> : Le liste di cui sei utente o editore

<LI><A HREF="[path_cgi]/loginrequest">Login</A> / <A HREF="[path_cgi]/logout">Logout</A> : Entra od esci da WWSympa.
</UL>

<H2>Login</H2>

All'autenticazione (<A HREF="[path_cgi]/loginrequest">Login</A>), inserisci il tuo indirizzo e-mail
e la password associata.
<BR><BR>
Una volta autenticato, un <I>cookie</I> contenente le tue informazioni di login ti 
permetter&agrave; di lavorare con WWSympa per un certo periodo.<BR>
Il periodo &egrave; di validit&agrave; di questo <I>cookie</I> &egrave; definibile nelle tue
<A HREF="[path_cgi]/pref">preferenze</A>. 

<BR><BR>
Puoi uscire (cancellare il tuo<I>cookie</I>) in qualsiasi momento usando la funzione <A HREF="[path_cgi]/logout">logout</A>.

<H5>Risposte al Login</H5>

<I>Non sono iscritto ad alcuna lista</I><BR>
Non sei quindi registrato nel database Sympa e non puoi entrare.
Se ti iscrivi ad una lista, ti verr&agrave; fornita una password.
<BR><BR>

<I>Sono iscritto ad almeno una lista ma non ho alcuna password per questo servizio</I><BR>
Per ricevere la tua password :
<A HREF="[path_cgi]/remindpasswd">[path_cgi]/remindpasswd</A>
<BR><BR>

<I>Ho dimenticato la mia password</I><BR>

WWSympa pu&ograve; ricordarti la tua password per email:

<A HREF="[path_cgi]/remindpasswd">[path_cgi]/remindpasswd</A>

<P>

To contact this service administrator : <A HREF="mailto:listmaster@[conf->host]">listmaster@[conf->host]</A>
[ENDIF]


