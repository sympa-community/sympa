<!-- RCS Identication ; $Revision$ ; $Date$ -->
[IF status = done] 
<b>Operatie reusita</b>. Mesajul va fi sters cat mai repede. 
Aceasta operatie ar putea fi inaccesibila pentru cateva minute, nu uita sa reincarci 
pagina problema. 
[ELSIF status = no_msgid]
 <b> Mesajul care trebuie</B> sters 
nu poate fi sters, probabil mesajul a fost primit fara "Message-Id:" Trimite URL-ul 
complet al mesajului problema la administrator 
[ELSIF status = not_found]
 <b>Mesajul 
care urmeaza sa fie sters nu poate fi gasit</b> 
[ELSE]
 <b>Eroare aparuta in timpul 
stergerii acestui mesaj, trimite URL-ul complet al mesajului problema la administrator.</b> 
[ENDIF]
