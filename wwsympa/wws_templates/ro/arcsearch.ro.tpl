<!-- RCS Identication ; $Revision$ ; $Date$ -->

<H2>Rezultatul cautarii in arhiva listei <A HREF="[path_cgi]/arc/[list]/[archive_name]"><FONT COLOR="[dark_color]">[list]</font></a> 
  : </H2>

<P>Cautare : 
[FOREACH u IN directories]
 <A HREF="[path_cgi]/arc/[list]/[u]"><FONT COLOR="[dark_color]">[u]</font></a> 
  - 
[END] </P>

Parametrii cautarii pe cuvintele <b> &quot;[key_word]&quot;</b> <I> 
[IF how=phrase] 
(Propozitie, 
[ELSIF how=any] 
(Toate cuvintele, 
[ELSE] 
(Fiecare din aceste cuvinte, 
[ENDIF] 
<i> 
[IF case] 
caz senzitiv 
[ELSE] 
caz senzitiv 
[ENDIF] 
[IF match] 
si verificare 
pe parte din cuvant)</i> 
[ELSE] 
si verificare pe intreg cuvant)</i> 
[ENDIF] 
<p>

<HR>
[IF age] 
<B>Ordonate dupa mesaje noi</b> 
<P> 
[ELSE] 
<B>Ordonate dupa mesaje vechi</b>
<P>
[ENDIF]

[FOREACH u IN res]
	<DT><A HREF=[u->file]>[u->subj]</A> -- <EM>[u->date]</EM>
<DD>[u->from] 
  <PRE>[u->body_string]</PRE>
  [END] 
  <DL> <B>Resultat</b> 
    <DT><B>[searched] mesaje selectate dintr-un numar de [num]...</b><BR>
      [IF body] 
    <DD><B>[body_count]</b> cautate in <i>mesaje Body</i><BR>
      [ENDIF] 
      [IF subj] 
    <DD><B>[subj_count]</b> cautate in <i></i><i>mesaje Subject</i> <BR>
      [ENDIF] 
      [IF from] 
    <DD><B>[from_count]</b> <i>cautate in <i></i>mesaje From</i> <BR>
      [ENDIF] 
      [IF date] 
    <DD><B>[date_count]</b> <i>cautate in <i></i>mesaje Date</i><BR>
      [ENDIF] 
  </dl>
  <FORM METHOD=POST ACTION="[path_cgi]">
    <INPUT TYPE=hidden NAME=list		 VALUE="[list]">
    <INPUT TYPE=hidden NAME=archive_name VALUE="[archive_name]">
    <INPUT TYPE=hidden NAME=key_word     VALUE="[key_word]">
    <INPUT TYPE=hidden NAME=how          VALUE="[how]">
    <INPUT TYPE=hidden NAME=age          VALUE="[age]">
    <INPUT TYPE=hidden NAME=case         VALUE="[case]">
    <INPUT TYPE=hidden NAME=match        VALUE="[match]">
    <INPUT TYPE=hidden NAME=limit        VALUE="[limit]">
    <INPUT TYPE=hidden NAME=body_count   VALUE="[body_count]">
    <INPUT TYPE=hidden NAME=date_count   VALUE="[date_count]">
    <INPUT TYPE=hidden NAME=from_count   VALUE="[from_count]">
    <INPUT TYPE=hidden NAME=subj_count   VALUE="[subj_count]">
    <INPUT TYPE=hidden NAME=previous     VALUE="[searched]">
    [IF body] 
    <INPUT TYPE=hidden NAME=body Value="[body]">
    [ENDIF] 
    [IF subj] 
    <INPUT TYPE=hidden NAME=subj Value="[subj]">
    [ENDIF] 
    [IF from] 
    <INPUT TYPE=hidden NAME=from Value="[from]">
    [ENDIF] 
    [IF date] 
    <INPUT TYPE=hidden NAME=date Value="[date]">
    [ENDIF] 
    [FOREACH u IN directories] 
    <INPUT TYPE=hidden NAME=directories Value="[u]">
    [END] 
    [IF continue] 
    <INPUT NAME=action_arcsearch TYPE=submit VALUE="Continua cautarea">
    [ENDIF] 
    <INPUT NAME=action_arcsearch_form TYPE=submit VALUE="Cautare noua">
  </FORM>
  <HR>
  Bazat pe <Font size=+1 color="[dark_color]"><i><A HREF="http://www.mhonarc.org/contrib/marc-search/">Marc-Search</a></i></font>, 
  search engine al <B>MHonArc</B>
  <p> <A HREF="[path_cgi]/arc/[list]/[archive_name]"><B>Inapoi in arhiva [archive_name] 
    </B></A><br>
  
