<!-- RCS Identication ; $Revision$ ; $Date$ -->
<P> Iata o descriere a modalitatilor de primire a mesajelor in Sympa. Aceste sunt 
  exclusive, adica nu poti opta pentru doua moduri diferite in acelasi timp. Doar 
  un subset poate fi disponibil pentru lista. </P>
<UL>
  <LI>Digest<BR>
    In loc sa primeasca mailurile in mod normal abonatul va primi periodic un 
    Digest. Digest este o compilatie a mesajelor de pe lista, utilizand formatul 
    multipart/digest MIME. <BR>
    <BR>
    Perioada de trimitere a acestor compilatii este decisa de catre proprietarul 
    listei.<BR>
    <BR>
  <LI>Rezumat<BR>
    In loc sa primeasca mailurile in mod normal abonatul va primi o lista de mesaje. 
    Acest mod de trimitere este apropriat modului Digest cu exceptia faaptului 
    ca cei inscrisi vor primi doar o lista a mesajelor<BR>
    <BR>
  <LI>Nomail<BR>
    Acest mod este utilizat de catre un abonat care nu doreste sa mai primeasca 
    mesaje de la lista dar vrea sa aiba posibilitatea sa publice mesaje pe lista. 
    Acest mod previne dezabonarea si reinscrierea de mai apoi.<BR>
    <BR>
  <LI>Txt <BR>
    Acest mod este utilizat cand un abonat doreste sa primeasca mesaje trimise 
    atat in format format txt/html cat si txt/plain sau doar in format txt/plain.<BR>
    <BR>
  <LI>Html<BR>
    Acest mod este utilizat cand un abonat doreste sa primeasca mesaje trimise 
    atat in format format txt/html cat si txt/plain sau doar in format txt/html.<BR>
    <BR>
  <LI>Urlize<BR>
    Mod utilizat cand utilizatorul nu doreste sa primeasca fisiere atasate. Fisierele 
    atasate sunt inlocuite cu un URL care duce la fisierul atasat. <BR>
    <BR>
  <LI>Not_me<BR>
    Prin acest mod utilizatorul nu va primi inapoi pe care acesta l-a trimis catre 
    lista. <BR>
    <BR>
  <LI>Normal<BR>
    Acest mod este utilizat pentru a anula modurile nomail, summary or digest 
    modes. Daca abonatul a fost in mod nomail, acesta va primi din nou mail in 
    mod normal. <BR>
    <BR>
</UL>
