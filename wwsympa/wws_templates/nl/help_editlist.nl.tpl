<!-- RCS Identication ; $Revision$ ; $Date$ -->

[FOREACH p IN param]
<A NAME="[p->NAME]">
<B>[p->title]</B> ([p->NAME]):
<DL>
<DD>
[IF p->NAME=add]
  Toegangsnivo voor het toevoegen van (ADD commando) een gebruiker aan de lijst
[ELSIF p->NAME=anonymous_sender]
  Om het emailadres van de afzender te verbergen voor het distribueren van
  een bericht. Het wordt vergangen door het ingegeven emailadres.
[ELSIF p->NAME=archive]
  Toegangsrecht voor het lezen van het mailarchief en de frequentie van het archiveren.
[ELSIF p->NAME=owner]
  Eigenaren zijn managende abonnees van de lijst. Ze mogen abonnees reviewen
en emailadressen toevoegen of verwijderen van de lijst. Wanneer u de
privleged eigenaar bent van een lijst, kunt u andere eigenaren kiezen voor
de mailinglijst. Privileged eigenare mogen iets meer dan andere eigenaren.
Er kan slechts 1 privliged eigenaar per lijst zijn; zijn/haar email adres
kan niet vanaf het web veranderd worden.
[ELSIF p->NAME=editor]
  Editors zijn verantwoordelijk voor het modereren van berichten. Wanneer de
mailinglijst gemodereerd wordt, worden bericht die op de lijst geplaatst
worden eerst doorgestuurd naar de editors, en die beslissen of een bericht
wordt gedistribueerd of geweigers. <BR>
 Ter info: Editors aanwijzen zorgt er niet voor dat een lijst moderatoed
wordt; u moet de "send" parameter veranderen.
  Wanneer de lijst gemodereerd wordt kan elke editor een bericht verspreiden
of weigeren zonder de kennis of toestemming van andere editors. Berichten
die niet zijn geweigerd of verspreid blijven in de moderatie lijst totdat
iemand actie onderneemd.
[ELSE]
  No Comment
[ENDIF]

</DL>
[END]
	
