<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF status = done]
<b>Operace úspì¹nì dokonèena</b>. 
Zpráva bude odstranìna co nejdøíve. Tento proces bude mo¾ná nìkolik minut trvat,
nezapomìòte naèíst znovu danou stránku.
[ELSIF status = no_msgid]
<b>Nelze najít zprávu ke smazání, pravdìpodobnì tato zpráva pøi¹la bez parametru
"Message-Id:". Po¹lete prosím správci kompletní odkaz na inkriminovanou zprávu.
</b>
[ELSIF status = not_found]
<b>Nelze najít zprávu ke smazání</b>
[ELSE]
<b>Chyba pøi výmazu zprávy, po¹lete prosím sprvci kompletní odkaz na
na inkriminovanou zprávu.</b>
[ENDIF]

