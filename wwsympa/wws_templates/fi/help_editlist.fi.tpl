<!-- RCS Identication ; $Revision$ ; $Date$ -->

[FOREACH p IN param]
<A NAME="[p->NAME]">
<B>[p->title]</B> ([p->NAME]):
<DL>
<DD>
[IF p->NAME=add]
  Oikeudet lisätä tilaajia (ADD komento) listalle
[ELSIF p->NAME=anonymous_sender]
  Lähettäjän email osoitteen piilottaminen ennen lähettämistä.
  Se korvataan annetulla email osoitteella.
[ELSIF p->NAME=archive]
  Oikeudet arkistojen lukuun ja arkistoinnin aikaväli
[ELSIF p->NAME=owner]
 Omistajat hallitsevat listan tilaajia. He voivat tarkistaa, lisätä tai poistaa
 osoitteita listalta. Jos ole listan oikeutettu omistaja, voit valita listan 
 muut omistajat. Oikeutetut omistajat voivat muuttaa enemmän asetuksia kuin muut.
 Listalla voi olla vain yksi oikeutettu omistaja; hänen osoitettaan ei voi muuttaa
 WWW-liittymän kautta.	
[ELSIF p->NAME=editor]
  Tarkistajat ovat vastuussa viestien hallinnoinnista. Jos lista on hallittu,
  viestien menevät ensin tarkistajille jotka päättävät lähetetäänkö vai hylätäänkö
  viesti.<BR>
  HUOM: Tarkistajien määrittäminen ei tee listasta hallittua ; sinun täytyy muuttaa
  "send" parametria.<BR>
  HUOM: Jos lista on hallittu, kuka tahansa tarkistajista voi lähettää tai hylätä 
  viestin muiden tarkistajien hyväksynnästä huolimatta. Viestit joita ei ole 
  tarkistettu, jäävät jonoon kunnes ne on hyväksytty tai hylätty.
[ELSE]
  Ei kommenttia
[ENDIF]

</DL>
[END]
	
