<!-- RCS Identication ; $Revision$ ; $Date$ -->

[FOREACH p IN param]
<A NAME="[p->NAME]">
<B>[p->title]</B> ([p->NAME]):
<DL>
<DD>
[IF p->NAME=add]
  Oprávnìní pro pøidání (pøíkaz ADD) èlena do konference
[ELSIF p->NAME=anonymous_sender]
  Pro skrytí emailové adresy odesílatele pøed distribucí zprávy. Tato adresa
  je nahrazena poskytnutou adresou.
[ELSIF p->NAME=archive]
  Oprávnìní èíst archívy zpráv a frekvenci archivování  
[ELSIF p->NAME=owner]
  Vlastníci spravují èleny konference. Mohou si prohlí¾et seznam èlenù, pøidávat
  nebo mazat adresy ze seznamu. Pokud jste oprávnìným správcem konference,
  mù¾ete urèit jiné vlastníky konference.

  Privilegovaní vlastníci mohou upravovat více parametrù ne¾ jiní vlastníci. Pro
  konferenci mù¾e být pouze jeden prvilogovaný vlastník, jeho adresa se 
  nedá mìnit z webu.
[ELSIF p->NAME=editor]
Editoøi jsou zodpovìdní za moderování zpráv. Pokud je konference moderovaná,
zprávy poslané do konference jsou nejøív poslané editorùm, kteøí rozhodnou,
jestli se zpráva roze¹le nebo odmítne. <BR>
FYI: Urèení editorù nenastaví konferenci jako moderovanou; musíte zmìnit 
parametr "send".<BR>
FYI: Pokud je konference moderovaná, první editor, který potvrdí 
nebo odmítne zprávu rozhodne za ostatní editory. Pokud se nikdo nerozhodne,
zprava zùstane ve frontì nemoderovaných zpráv.
[ELSE]
  Bez komentáøe
[ENDIF]

</DL>
[END]

