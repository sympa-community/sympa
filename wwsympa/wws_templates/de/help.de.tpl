<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF help_topic]
 [PARSE help_template]

[ELSE]
<BR>
WWSympa erm&ouml;glicht Ihnen Zugang zu Ihren Mailing-Listen-Einstellungen
auf dem Server
<B>[conf->email]@[conf->host]</B>.
<BR><BR>
Funktionen, welche den Sympa Robot-Kommandos entsprechen, sind im
oberen Teil der Benutzerschnittstelle zu finden. WWSympa stellt
folgende Funktionen zur Verf&uuml;gung:

<UL>
<LI><A HREF="[path_cgi]/pref">Einstellungen</A>: Benutzerspezifische
Einstellungen

<LI><A HREF="[path_cgi]/lists">&Ouml;ffentliche Listen</A>: Verzeichnis
von Mailing-Listen, welche &uuml;ber diese Maschine verteilt werden.

<LI><A HREF="[path_cgi]/which">Ihre Abonnements</A> : Ihre Listen, welche Sie
als Besitzer oder Abonnent empfangen.

<LI><A HREF="[path_cgi]/loginrequest">Anmelden</A> / <A HREF="[path_cgi]/logout">Abmelden</A> : An/abmelden bei WWSympa.
</UL>

<H2>Anmelden</H2>

Um sich gegen&uuml;ber dem WWSympa-System zu authentifizieren
(<A HREF="[path_cgi]/loginrequest">Anmelden</A>), geben Sie Ihre
EMail-Adresse und Ihr zugeh&ouml;riges WWSympa-Passwort an.
<BR><BR>
Wenn Sie einmal authentifiert sind, h&auml;lt ein <I>cookie</I> 
mit Ihren Login-Informationen die Verbindung zu WWSympa am Leben.
Wie lange die Verbindung maximal besteht, k&ouml;nnen Sie
in Ihren <A HREF="[path_cgi]/pref">Einstellungen</A> festlegen. 

<BR><BR>
Sie k&ouml;nnen sich jederzeit abmelden (Ihr <I>cookie</I> l&ouml;schen)
indem Sie die <A HREF="[path_cgi]/logout">Abmelden</A>-Funktion
benutzen.

<H5>Anmelde-Probleme</H5>

<I>Ich bin kein Listen-Abonnent </I><BR>
Sie sind deshalb auch nicht in der Sympa-Benutzer-Datenbank registriert
und k&ouml;nnen sich nicht anmelden. Wenn Sie das erste Mal eine
Mailing-Liste abonnieren, wird WWSympa Ihnen Ihr erstes Passwort zuteilen. 
<BR><BR>

<I>Ich bin Abonnent von mindestens einer Liste, aber ich habe trotzdem kein
Passwort </I><BR>
Um Ihr Passwort per EMail zu erhalten, besuchen Sie bitte die Seite:
<A HREF="[path_cgi]/remindpasswd">[path_cgi]/remindpasswd</A>
<BR><BR>

<I>Ich habe mein Passwort vergessen</I><BR>

WWSympa kann Ihnen Ihr Passwort auch noch einmal schicken:
<A HREF="[path_cgi]/remindpasswd">[path_cgi]/remindpasswd</A>

<P>

Wenn Sie den Administrator kontaktieren wollen, schicken Sie eine EMail an: <A HREF="mailto:listmaster@[conf->host]">listmaster@[conf->host]</A>
[ENDIF]


