<!-- RCS Identication ; $Revision$ ; $Date$ -->

[FOREACH p IN param]
<A NAME="[p->NAME]">
<B>[p->title]</B> ([p->NAME]):
<DL>
<DD>
[IF p->NAME=add]
  ’igus lisada kasutajaid listi (ADD k‰suga)
[ELSIF p->NAME=anonymous_sender]
  Saatja aadress eemaldatakse kirjast ning asendatakse sisestatud
  aadressiga.
[ELSIF p->NAME=archive]
  ’igus lugeda arhiive ning arhiveerimise sagedus.
[ELSIF p->NAME=owner]
  Omanikud haldavad listi liikmeid. Nad vıivad vaadata, kes on listis,
  lisada ning kustutada aadresse listist. Privilegeeritud omanik saab 
  listi ka teisi omanikke lisada. Privilegeeritud omanikud saavad listi
  seadistamisel rohkem asju seada. Listil saab olla korraga vaid 1 
  privilegeeritud omaik. Tema aadressi ei saa veebist muuta. 
[ELSIF p->NAME=editor]
Moderaatorid otsustavad, millised kirjad listi p‰‰sevad ning millised 
mitte. Kui list on modereeritud, saadetakse kirjad esmalt moderaatoritele
ning nemad otsustavad, kas kiri saadetakse listi vıi ei.<BR>
NB! Selleks, et list oleks modereeritud tuleb muuta ka listi saatmise
meetodit seadistustest.<BR>
[ELSE]
  Kommentaare ei ole.
[ENDIF]

</DL>
[END]
	
