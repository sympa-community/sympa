

Kokkuvõte teie listidest, mille olete tellinud aadressile
[user->email]
Kui soovite mõnest listist lahkuda, salvestage see kiri.

Iga listi kohta on rida, mille abil saate listist lahkuda. 

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
[FOREACH l IN lists]
[l]	mailto:[conf->sympa]?subject=sig%20[l]%20[user->email]
[END]
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

[IF user->password]

Sympa veebiliidese ( [conf->wwsympa_url] ) kasutamiseks
on teie kasutajanimi [user->email] ja parool [user->password]


