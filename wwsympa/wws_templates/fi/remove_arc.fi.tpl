<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF status = done]
<b>Operaatio onnistui</b>. Viesti poistetaan mahdollisimman pian.
Tämä saattaa kestää muutaman minuutin, muista päivittää sivu.
[ELSIF status = no_msgid]
<b>Viestiä ei löydy poistettavaksi</b>, tod. näk. viesti
saaapui ilman "Message-Id:" Ota yhteyttä Listmasteriin
ja liitä mukaan viestin koko URL
[ELSIF status = not_found]
<b>Viestiä ei löydy poistettavaksi</b>
[ELSE]
<b>Virhe viestiä poistettaessa</b>, ota yhteyttä Listmasteriin
ja liitä mukaan viestin koko URL.
[ENDIF]
