<!-- RCS Identication ; $Revision$ ; $Date$ -->

Emailben elküldésre kerül a jelszavad. Email címedet csak<br>
akkor tudod megváltoztatni, ha a lejebb található jelszót
is megadod:

<FORM ACTION="[path_cgi]" METHOD=POST>
    <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
    <FONT COLOR="[dark_color]">[email] jelszava: </FONT>
    <BR>&nbsp;&nbsp;&nbsp;<INPUT TYPE="password" NAME="password" SIZE=15>
    <BR><BR><INPUT TYPE="submit" NAME="action_change_email" VALUE="Változtasd meg az email címemet">
</FORM>
