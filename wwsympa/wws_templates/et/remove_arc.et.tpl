<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF status = done]
<b>Tegevus õnnestus</b>. Kiri kustutatakse niipea, kui võimalik. See
võib võtta mõned minutid, uuendage muudetud lehte oma brauseris. 
[ELSIF status = no_msgid]
<b>Ei saa kustutada kirja, tõenäoliselt selle tõttu, et kirjal ei olnud
päises "Message-Id:" rida. Palun saatke listmasterile kirja täielik 
URL.
</b>
[ELSIF status = not_found]
<b>Ei leia kirja, mida kustutada soovite</b>
[ELSE]
<b>Viga kirja kustutamisel, palun saatke listmasterile kirja arhiivi 
täielik URL.
</b>
[ENDIF]
