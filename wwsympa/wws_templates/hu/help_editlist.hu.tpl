<!-- RCS Identication ; $Revision$ ; $Date$ -->

[FOREACH p IN param]
<A NAME="[p->NAME]">
<B>[p->title]</B> ([p->NAME]):
<DL>
<DD>
[IF p->NAME=add]
  Jog tag feliratásához (ADD parancs) a listára
[ELSIF p->NAME=anonymous_sender]
  Az üzenet eredeti feladójának elrejtése a levél listán megjelenésekor.
  A megadott email cím kerül a feladó helyére.
[ELSIF p->NAME=archive]
  Jog a levél archívum olvasásához és annak frissítéséhez.
[ELSIF p->NAME=owner]
  A tulajdonosok a listatagokat kezelhetik. Tagokat ellenõrízhetnek, felírhatnak
  vagy törölhetnek a listán. Ha tulajdonosa vagy a listának, akkor újabb gazdákat
  is rendelhetsz a listához.
  A tulajdonos kicsivel több joggal rendelkezik, mint a többi tag. Egyszerre csak
  egy tulajdonosa lehet a listának; email címet weben keresztül nem lehet megváltoztatni.
[ELSIF p->NAME=editor]
A szerkesztõk a megjelenõ leveleket kezelik. Ha a levelezõlista moderált, akkor az üzenetek elõször a szerkesztõkhöz jutnak el, 
akik döntenek annak megjelenésérõl vagy törlésérõl. <BR>
BIZ: Szerkesztõk megadásával még nem válik a lista moderálttá, ahhoz a
"send" paramétert is be kell állítani.<BR>
BIZ: Ha a lista moderált, akkor a szerkesztõ aki legelõször dönt a levél
sorsáról a többi szerkesztõ nevében is dönt. Amíg senki sem bírálja el a
levelet, addíg a moderálásra váró levelek között marad.
[ELSE]
  Nincs megjegyzés
[ENDIF]

</DL>
[END]
	