<!-- RCS Identication ; $Revision$ ; $Date$ -->

[FOREACH p IN param]
<A NAME="[p->NAME]">
<B>[p->title]</B> ([p->NAME]):
<DL>
<DD>
[IF p->NAME=add]
  Privileg jemanden zum Abonnenten einer Liste zu machen (ADD-Kommando).
[ELSIF p->NAME=anonymous_sender]
  Zum verheimlichen der Absenderadresse, vor der Verteilung einer EMail.
  Die Adresse wird durch die angegebene EMail-Adresse ersetzt.
[ELSIF p->NAME=archive]
  Privileg f&uuml;r den Zugriff auf die Mailarchive.
[ELSIF p->NAME=owner]
  Besitzer (owner) sind Abonnenten mit Verwaltungsaufgaben. Sie k&ouml;nnen
  die Liste der Abonnenten einsehen und ver&auml;ndern.
  <I>Privilegierte</I> Besitzer k&ouml;nnen andere zu Besitzern machen und
  k&ouml;nnen ein paar Optionen mehr setzen als normale owner.
  Es gibt immer nur einen Privilegierten Besitzer. Seine EMail-Adresse
  kann nicht &uuml;ber das Web ge&auml;ndert werden.
[ELSIF p->NAME=editor]
  Editoren sind f&uuml;r die Moderation einer Liste verantwortlich.
  Wenn eine Liste moderiert ist, gehen alle Nachrichten zu erst an
  diese, um zu entscheiden, ob die Nachricht weitergeleitet oder
  verworfen werden soll.<BR>
Achtung: Eine Liste wird nicht durch Definition von Editoren automatisch
zu einer moderierten Liste. Viel mehr wird dies den "send"-Parameter
gesteuert.<BR>
Achtung: Der erste Editor, der eine Nachricht akzepiert oder verwirft,
macht die Entscheidung f&uuml;r alle Editoren. Solange niemand entscheidet,
bleibt die Nachricht im Moderation-Bereich.
[ELSE]
  No Comment
[ENDIF]

</DL>
[END]
	
