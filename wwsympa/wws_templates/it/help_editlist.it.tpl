<!-- RCS Identication ; $Revision$ ; $Date$ -->

[FOREACH p IN param]
<A NAME="[p->NAME]">
<B>[p->title]</B> ([p->NAME]):
<DL>
<DD>
[IF p->NAME=add]
  Privilegio per aggiungere (comando ADD) un utente alla lista
[ELSIF p->NAME=anonymous_sender]
  Per nascondere il nome del mittente prima di distribuire il messaggio.
  Viene sostituito a quello fornito.
[ELSIF p->NAME=archive]
  Privilegio per leggere gli archivi e frequenza di archiviazione
[ELSIF p->NAME=owner]
  I creatori gestiscono le iscrizioni. Possono vedere la lista, aggiungere, cancellare indirizzi dalla lista.
  Se sei un creatore privilegiato, puoi aggiungere altri creatori della mailing list.
  I creatori privilegiati posso editare pi&ugrave; opzioni degli altri. Ci pu&ograve; essere un solo creatore
  privilegiato per lista. Il suo indirizzo non pu&ograve; essere cambiato dall'interfaccia Web.
[ELSIF p->NAME=editor]
Gli editori sono responsabili della moderazione dei messaggi. Se la mailing list &egrave; moderata, i messaggi postati alla lista vengono prima
mandati agli editori che possono decidere di distribuirli o rifiutarli.<BR>
Nota bene: definire gli editori non significa che la lista sar&agrave; moderata, per agire in tal senso devi modificare
il paramentro "send".<BR>
Nota bene: se la lista &egrave; moderata, il primo editore che risponde agisce anche per gli altri; se non risponde nessuno, il messaggio
rimane da moderare.

[ELSE]
  Nessun commento
[ENDIF]

</DL>
[END]
	