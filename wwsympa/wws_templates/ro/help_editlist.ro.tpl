<!-- RCS Identication ; $Revision$ ; $Date$ -->

[FOREACH p IN param]
<A NAME="[p->NAME]"></a>
<B>[p->title]</B> ([p->NAME]):
<DL>
  <DD> 
    [IF p->NAME=add] 
	Privilegiu pentru adaugarea (comanda ADD) unui abonat 
    la lista 
    [ELSIF p->NAME=anonymous_sender] 
	Pentru a ascunde adresa email a 
    expeditorului inainte de distribuirea mesajului. Este inlocuita cu adresa 
    email scrisa. 
    [ELSIF p->NAME=archive] 
	Privilegii de citire a arhivelor de 
    mail si frecventa de arhivare 
    [ELSIF p->NAME=owner] 
     Proprietarii sunt abonati 
    de operare ai listei. Acestia pot revedea persoanele inscrise, adauga sau 
    sterge adrese email din lista. Daca esti proprietar privilegiat al listei 
    poti alege cine sa fie alti proprietari. Propritarii privilegiati au mai multe 
    optiuni de editare decat alti proprietari. A lista poate avea doar un singur 
    proprietar privilegiat; adresa email a acestei persoane probabil nu poate 
    fi editata de pe web. 
    [ELSIF p->NAME=editor] 
    Editorii sunt responsabili pentru 
    moderarea mesajelor. Daca lista este moderata, mesajele publicate pe lista 
    vor fi mai intai verificate de editori care vor decide daca mesajul va fi 
    publicat sau va fi respins.<BR>
    FYI: Delegarea de editori nu v-a determina ca lista sa fie considerata moderata; 
    va trebui sa configurezi parametrul "send".<BR>
    FYI: Daca lista este moderata, primul editor care accepta sau respinge un 
    mesaj va avea drept de decizie si asupra celorlalti editori. Daca nici unul 
    nu va lua vreo decizie atunci mesajul va ramane in sectiunea mesajelor nemoderate. 
    [ELSE] 
    Fara comentarii. 
   [ENDIF] 
</DL>
[END]
	
