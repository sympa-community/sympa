<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF help_topic]
 [PARSE help_template]

[ELSE]
<BR>
WWSympa le permite el acceso a su configuración en el servidor de listas de correo
<B>[conf->email]@[conf->host]</B>.
<BR><BR>
Funciones, equivalentes a los comandos del robot Sympa, son accesibles desde la parte superior del interfaz de usario.
WWSympa le facilita un entorno personalizado con acceso a las siguientes funciones :

<UL>
<LI><A HREF="[path_cgi]/pref">Preferencias</A> : preferencias del usuario. Esto es sólo para usuarios ya identificados.

<LI><A HREF="[path_cgi]/lists">Listas Públicas </A> : directorio de las listas disponibles en este servidor

<LI><A HREF="[path_cgi]/which">Sus suscripciones</A> : su entorno como suscriptor o propietario

<LI><A HREF="[path_cgi]/loginrequest">Login</A> / <A HREF="[path_cgi]/logout">Logout</A> : Entrar / Abandonar de WWSympa.
</UL>

<H2>Login</H2>

Durante la autentificación (<A HREF="[path_cgi]/loginrequest">Login</A>), entre su email y su contraseña.
<BR><BR>
Una vez autentificado, una <I>cookie</I> conteniendo su información del login permite el acceso a WWSympa. La duración de esta <I>cookie</I> se puede cambiar desde <A HREF="[path_cgi]/pref">sus preferencias</A>. 

<BR><BR>
Puede abandonar (logout) en cualquier momento usando la función de <A HREF="[path_cgi]/logout">logout</A>

<H5>Problemas con Login issues</H5>

<I>Yo no soy suscriptor de ninguna lista</I><BR>
Vd. no está registrado en la base de datos de Sympa y por tanto no puede hacer un login.
Si se suscribe a una lista, WWSympa le asignará una contraseña inicial.
<BR><BR>

<I>Yo soy suscriptor de al menos una lista pero no tengo contraseña</I><BR>
Para recibir su contraseña : 
<A HREF="[path_cgi]/remindpasswd">[path_cgi]/remindpasswd</A>
<BR><BR>

<I>Olvidé mi contraseña</I><BR>

WWSympa le puede recordar su contraseña por correo :
<A HREF="[path_cgi]/remindpasswd">[path_cgi]/remindpasswd</A>

<P>
Para contactar con el administrador de este sistema : <A HREF="mailto:listmaster@[conf->host]">listmaster@[conf->host]</A>
[ENDIF]










