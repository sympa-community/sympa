%
% Copyright (C) 1999, 2000, 2001 Comité Réseau des Universités & Serge Aumont, Olivier Salaün
%
% Historique
%   1999/04/12 : pda .AT. prism.uvsq.fr : conversion to latex2e
%

[STOPPARSE]
\documentclass [twoside,a4paper] {report}

    \usepackage {epsfig}
    \usepackage {xspace}
    \usepackage {makeidx}
    \usepackage {html}
    \usepackage[frenchb]{babel}

    \usepackage {palatino}
    \usepackage{graphics}
    \usepackage{float}
    \usepackage{fancyvrb}
    \usepackage{calc}
    \usepackage{latexsym}
    \usepackage{color}
    \usepackage{times}
    \usepackage[latin1]{inputenc}
    \usepackage{hyperref}
    \usepackage{graphicx} 

%    \hypersetup{pdfauthor={},%
%            pdftitle={},pdftex}
    \renewcommand {\ttdefault} {cmtt}

    \setlength {\parskip} {5mm}
    \setlength {\parindent} {0mm} 

    \pagestyle {headings}
    \makeindex

    \sloppy

    \usepackage [dvips] {changebar}
    % \begin {changebar} ... \end {changebar}
    % ou \cbstart ... \cbend   et \cbdelete

    %
    % Change bars are not well rendered by latex2html
    %

    \begin {htmlonly}
        \renewcommand {\cbstart} {}
        \renewcommand {\cbend} {}
        \renewcommand {\cbdelete} {}
    \end {htmlonly}

    % black text on a white background, links unread in red
    % \bodytext {TEXT="#000000" BGCOLOR="#ffffff" LINK="#ff0000"}
    % black text on a white background
    \bodytext {TEXT="#000000" BGCOLOR="#ffffff"}

    \newcommand {\fig} [2]
    {
        \begin {figure} [htbp]
            \hrule
            \vspace {3mm}
            \begin {center}
                \epsfig {figure=#1.ps}
%                \epsffile {figure=#1.ps}
            \end {center}
            \vspace {2mm}
            \caption {#2}
            \vspace {3mm}
            \hrule
            \label {fig:#1}
        \end {figure}
    }
[STARTPARSE]
    \newcommand {\version} {[version]}

    \newcommand {\samplelist} {mylist}

    \newcommand {\samplerobot} {my.domain.org}
[STOPPARSE]
    % #1 = text to index and to display
    \newcommand {\textindex} [1] {\index{#1}#1}

    % #1 = sort key, #2 displayed in text and index
    \newcommand {\textindexbis} [2] {\index{#1@#2}#2}

    \newcommand {\Sympa} {\textit {Sympa}\xspace}

    \newcommand {\WWSympa} {\textindexbis {WWSympa}{\textit {WWSympa}}\xspace}

    % #1 = sort key, #2 : displayed in text and index, #3 displayed in index
    \newcommand {\ttindex} [3]  {\index{#1@\texttt {#2} #3}\texttt {#2}}

    \newcommand {\example} [1] {Example: \texttt {#1}}

    \newcommand {\unixcmd} [1] {\ttindex {#1} {#1} {UNIX command}}

    \newcommand {\option} [1] {\ttindex {#1} {#1} {option}}

    \newcommand {\mailcmd} [1] {\ttindex {#1} {#1} {mail command}}

    \newcommand {\cfkeyword} [1] {\ttindex {#1} {#1} {configuration keyword}}

    \newcommand {\default} [1]  {(Default value: \texttt {#1})}

    \newcommand {\scenarized} [1] {\texttt {#1} parameter is defined by an authorization scenario (see~\ref {scenarios}, page~\pageref {scenarios})}

    \newcommand {\lparam} [1] {\ttindex {#1} {#1} {list parameter}}

    \newcommand {\perlmodule} [1] {\ttindex {#1} {#1} {perl module}}

    \newcommand {\file} [1] {\ttindex {#1} {#1} {file}}

    \newcommand {\dir} [1]  {\ttindex {#1} {#1} {directory}}

    \newcommand {\tildefile} [1] {\ttindex {#1} {\~{}#1} {file}}

    \newcommand {\tildedir} [1] {\ttindex {#1} {\~{}#1} {directory}}

    \newcommand {\rfcheader} [1] {\ttindex {#1:} {#1:} {header}}

    % Notice: use {\at} when using \mailaddr
    %\newcommand {\at} {\char64}
    \newcommand {\mailaddr} [1] {\texttt {#1}}   
% mail address
%        {\ttindex {#1} {#1} {mail address}}

[STARTPARSE]
\begin {document}

    \title {\Huge\bf Sympa \\ \huge\bf Mailing Lists Management Software \\ version [version]\\}
    \author {
        Serge Aumont,
        Olivier Sala\"un,
        Christophe Wolfhugel,
         }
    \date {[date]}
\begin {htmlonly}
For printing purpose, use the 
\htmladdnormallink {postscript format version} {sympa.ps} of this documentation.
\end {htmlonly}

\maketitle


{
    \setlength {\parskip} {0cm}



    \cleardoublepage

    \tableofcontents
    % \listoffigures
    % \listoftables
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Presentation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\cleardoublepage
\chapter {Presentation}

\Sympa is an electronic mailing list manager.  It is used to automate
list management functions such as subscription, moderation,
archive and shared document management. 
It also includes management functions which
would normally require a substantial amount of work (time-consuming
and costly for the list owner). These
functions include automatic management of subscription renewals,
list maintenance, and many others.

\Sympa manages many different kinds of lists. It includes
a web interface for all list functions including management. It allows
a precise definition of each list feature, such as sender authorization,
the moderating process, etc. \Sympa defines, for each feature of each list,
exactly who is authorized to perform the relevant operations, along with the
authentication method to be used. Currently, authentication can be based
on either an SMTP From header, a password, or an S/MIME signature.\\
\Sympa is also able to extract electronic
addresses from an \textindex {LDAP} directory or \textindex {SQL} server, and include them
dynamically in a list.

\Sympa manages the dispatching of messages, and makes it possible to
reduce the load on the computer system where it is installed. In
configurations with sufficient memory, \Sympa is especially well
adapted to handling large lists: for a list of 20,000 subscribers, it requires
less than 6 minutes to send a message to 95 percent of the subscribers,
assuming that the network is available (tested on a 300~MHz, 256~MB
i386 server with Linux).

This guide covers the installation, configuration and management of
the current release (\version) of
\htmladdnormallink {sympa} {http://www.sympa.org}.

\section {License}

\Sympa is free software; you may distribute it under the terms
of the
\htmladdnormallinkfoot {GNU General Public License Version 2}
        {http://www.gnu.org/copyleft/gpl.html}

You may make and give away verbatim copies of the source form of
this package without restriction, provided that you duplicate all
of the original copyright notices and associated disclaimers.

\section {Features}

\Sympa provides all the basic features that any mailing list management robot
should include. While most \Sympa features have their equivalents in other
mailing list applications, \Sympa is unique in including features
in a single software package, including:

\begin {itemize}
    \item \textbf {High speed distribution processing} and \textbf {load control}. \Sympa
        can be tuned to allow the system administrator to control
        the amount of computer resources used.  Its optimized algorithm
        allows:

        \begin {itemize}
            \item the use of your preferred SMTP engine, e.g.
                \unixcmd {sendmail}, \unixcmd {qmail} or \unixcmd
                {postfix}

            \item tuning of the maximum number of SMTP child processes

            \item grouping of messages according to recipients' domains,
	    	and tuning of the grouping factor

            \item detailed logging

        \end {itemize}

 \item \textbf {Multilingual} user interface. The full user/admin interface (mail and web)
      is internationalized. Translations are gathered in a standard PO file.

   \item \textbf {Template based} user interface. Every web page and service message can
    be customized via \textbf {TT2} template format.

    \item \textbf {MIME support}. \Sympa naturally respects
        \textindex {MIME} in the distribution process, and in addition
        allows list owners to configure their lists with
        welcome, goodbye and other predefined messages using complex
        \textindex {MIME} structures. For example, a welcome message can be in
        \textbf {multipart/alternative} format, using \textbf {text/html},
        \textbf {audio/x-wav}~:-), or whatever (Note that \Sympa
        commands in multipart messages are successfully processed, provided that
	one part is \textbf {text/plain }).

    \item The \textbf {sending process is controlled} on a per-list basis.
        The list definition allows a number of different actions for
        each incoming message. A \lparam {private} list is a list where
        only subscribers can send messages. A list configured using
        \lparam {privateoreditorkey} mode accepts incoming messages
        from subscribers, but will forward any other (i.e. non-subscriber) message
	to the editor with a one-time secret numeric key that will be used by the
        editor to \textit {reject} or \textit {distribute} it.
        For details about the different sending modes, refer to the
        \lparam {send} parameter (\ref {par-send}, page~\pageref {par-send}). 
	The sending process configuration (as well as most other list
	operations) is defined using  an \textbf {authorization scenario}. Any listmaster
        can define new authorization scenarios in order to complement the 20
	predefined configurations included in the distribution. \\
        Example : forward multipart messages to the list editor, while
	distributing others without requiring any further authorization.
        
    \item Privileged operations can be performed by list editors or
        list owners (or any other user category), as defined in the list
        \file {config} file or by
        the robot \textindex {administrator}, the listmaster, defined
        in the \file {[CONFIG]}  global configuration file (listmaster
        can also be defined for a particular virtual host).
        Privileged operations include the usual \mailcmd {ADD}, \mailcmd
        {DELETE} or \mailcmd {REVIEW} commands, which can be
        authenticated via a one-time password or an S/MIME signature.

    \label {wwsympa} 
    \item \textbf {Web interface} : {\WWSympa} is a global Web interface to all \Sympa functions
    	(including administration). It provides :

        \begin {itemize}

	    \item classification of lists, along with a search index

            \item access control to all functions, including the list of lists
                  (which makes WWSympa particularly well suited to be the main
		  groupware tool within an intranet)
 
       	    \item management of shared documents (download, upload, specific
		  access control for each document)

            \item an HTML document presenting each user with the list of
		  her current subscriptions, including access to archives, and
		  subscription options

            \item management tools for list managers (bounce processing, changing of
                  list parameters, moderating incoming messages)

            \item tools for the robot administrator (list creation, global robot
                  configuration) \index{administrator}

        \end {itemize}
	(See \ref {WWSympa}, page~ \pageref {WWSympa})

    \item \textbf {RDBMS} : the internal subscriber and administrative data structure can be stored in a
        database or, for compatibility with versions 1.x, in text
        files for subscriber data. The introduction of databases came out of the
        \WWSympa project.  The database ensures a secure access to
        shared data. The PERL database API \perlmodule {DBI}/\perlmodule {DBD} enables
        interoperability with various \textindex{RDBMS} (\textindex{MySQL}, \textindex{SQLite}, \textindex{PostgreSQL},
        \textindex{Oracle}, \textindex{Sybase}).
	(See ref {sec-rdbms}, page~\pageref {sec-rdbms})

    \item \textbf {Virtual hosting} : a single \Sympa installation
        can provide multiple virtual robots with both email and web interface
        customization (See \ref {virtual-robot}, page~\pageref {virtual-robot}).

    \item \textbf {\textindex {LDAP-based mailing lists}} : e-mail addresses can be retrieved dynamically from a database
    	accepting \textindex {SQL} queries, or from an \textindex {LDAP} directory. In the interest
	of reasonable response times, \Sympa retains the data source in an
	internal cache controlled by a TTL (Time To Live) parameter.
	(See \ref {include-ldap-query}, page~\pageref {include-ldap-query})

    \item \textbf {\textindex {LDAP authentication}}:  via uid and emails stored 
      	in LDAP Directories.  Alternative email addresses, extracted from LDAP 
        directory, may be used to "unify" subscriptions.
	(See ref {ldap-auth}, page~\pageref {ldap-auth})

    \item \textbf {Antivirus scanner} : \Sympa extracts attachements from incoming
	messages and run a virus scanner on them. Curently working with McAfee/uvscan,
	Fsecure/fsav, Sophos, AVP, Trend Micro/VirusWall and Clam Antivirus.
	(See ref {antivirus}, page~\pageref {antivirus})

    \item Inclusion of the subscribers of one list among the subscribers of
    	another. This is real inclusion, not the dirty, multi-level cascading
	one might otherwise obtain by simply "subscribing list B to list A".

%    \item Various task automatic processing. List master may use predefined 
%	task models to automate recurrent processings such as regurlaly 
%	reminding subscribers their belonging to a list or updating certificate
%	revocation lists. It is also possible to write one's own task models to meet 
%	particular needs. Unique actions may also be scheduled by this way.

     \item channel RSS.
 
\end {itemize}

\section {Project directions}

\Sympa is a very active project : check the release note 
\htmladdnormallinkfoot {release note} {http://www.sympa.org/release.html}.
So it is no longer possible to
maintain multiple document about Sympa project direction.
Please refer to \htmladdnormallinkfoot {in-the-futur document} {http://www.sympa.org/sympa/in-the-future.html}
for information about project direction.

\section {History}

\Sympa development started from scratch in 1995. The goal was to
ensure continuity with the \textindex {TULP} list manager, produced
partly by the initial author of \Sympa: Christophe Wolfhugel.

New features were required, which the TULP code was just not up to
handling. The initial version of \Sympa brought authentication,
the flexible management of commands, high performances in internal
data access, and object oriented code for easy code maintenance.

It took nearly two years to produce the first market releases.

Other date :

\begin {itemize}
   \item Mar 1999 Internal use of a database (Mysql), definition of list subscriber with external datasource (RDBMS or \textindex {LDAP}).
   \item Oct 1999 Stable version of WWsympa, introduction of authorization scenarios.
   \item Feb 2000 Web bounces management
   \item Apr 2000 Archives search engine and message removal
   \item May 2000 List creation feature from the web
   \item Jan 2001 Support for S/MIME (signing and encryption), list setup through the web interface, Shared document repository for each list. Full rewrite of HTML look and feel
   \item Jun 2001 Auto-install of aliases at list creation time, antivirus scanner plugging
   \item Jan 2002 Virtual hosting, \textindex {LDAP authentication}
   \item Aug 2003 Automatic bounces management
   \item Sep 2003 CAS-base and Shibboleth-based authentication
   \item Dec 2003 Sympa SOAP server
   \item Aug 2004 Changed for TT2 template format and PO catalogue format
   \item     2005 Changed HTML to XHTML + CSS, RSS, List families, ...
\end {itemize} 
	  

\section {Authors and credits}

Christophe Wolfhugel is the author of the first beta version of
\Sympa. He developed it while working for the
\htmladdnormallinkfoot {Institut Pasteur} {http://www.pasteur.fr}.

Later developments have mainly been driven by the
\htmladdnormallinkfoot {Comit\'e R\'eseaux des Universit\'es} {http://www.cru.fr}
(Olivier Sala\"un and Serge Aumont), who look after a large mailing
list service.

Our thanks to all contributors, including:

\begin {itemize}

  \item Virginie Paitrault,Université de Rennes 2, who wrote the excellent online user documentation.

  \item John-Paul Robinson, University of Alabama at Birmingham, who added to email verification procedure to the Shibboleth support.

  \item Gwenaelle Bouteille who joined the development team for a few months and produced a great job for various feature introduced in V5 (familly, RSS, shared document moderation, ...).

  \item Pierre David, who in addition to his help and suggestions
       in developing the code, participated more than actively in
       producing this manual.

  \item David Lewis who corrected this documentation

  \item Philippe Rivière for his persevering in tuning \Sympa for Postfix.

  \item Rapha\"el Hertzog (debian), Jerome Marant (debian) and St\'ephane Poirey (redhat) for
      Linux packages.

  \item Loic Dachary for guiding us through the \textit {GNU Coding Standards}

  \item Vincent Mathieu, Lynda Amadouche, John Dalbec for their integration
	of \textindex {LDAP} features in \Sympa.

  \item Olivier Lacroix, for all his perseverance in bug fixing.

  \item Hubert Ulliac for search in archive base on marcsearch.pm

  \item Florent Guilleux who wrote the Task Manager

  \item Nadia Euzen for developping the antivirus scanner pluggin.

  \item Fabien Marquois, who introduced many new features such as
      the digest.

  \item Valics Lehel, for his Romanian translations

  \item Vizi Szilard for his Hungarian translations

  \item Petr Prazak for his Czech translations

  \item Rodrigo Filgueira Prates for his Portuguese translations

  \item Lukasz Zalubski for his Polish translations

  \item Alex Nappa and Josep Roman for their Spanish translations

  \item Carsten Clasohm and Jens-Uwe Gaspar for their German translations

  \item Marco Ferrante for his Italian translations

  \item Tung Siu Fai, Wang Jian and Autrijus Tang for their Chinese translations

  \item and also: Manuel Valente, Dominique Rousseau,
    Laurent Ghys, Francois Petillon, Guy Brand, Jean Brange, Fabrice
    Gaillard, Herv\'e Maza, Harald Wilhelmi, 

   \item Anonymous critics who never missed a chance to
       remind us that \textit {smartlist} already did all that
       better.

   \item All contributors and beta-testers cited in the \file
       {RELEASE\_NOTES} file, who, by serving as guinea pigs and
       being the first to use it, made it possible to quickly and
       efficiently debug the \Sympa software.

  \item Ollivier Robert, Usenet Canal Historique and the good manners
      guru in the PERL program.

    \item Bernard Barbier, without whom \Sympa would not
        have a name.

\end {itemize}

We ask all those we have forgotten to thank to accept our apologies
and to let us know, so that we can correct this error in future
releases of this documentation.

\section {Mailing lists and support}
    \label {sympa@cru.fr}

If you wish to contact the authors of \Sympa, please use the address
\mailaddr {sympa-authors{\at}cru.fr}.

There are also a few \htmladdnormallinkfoot {mailing-lists about \Sympa} {http://listes.cru.fr/sympa/lists/informatique/sympa} :

	\begin {itemize}
	   \item  \mailaddr {sympa-users{\at}cru.fr} general info list
	   
	   \item   \mailaddr {sympa-fr{\at}cru.fr}, for French-speaking users
			   
	   \item   \mailaddr {sympa-announce{\at}cru.fr}, \Sympa announcements
			  
	   \item   \mailaddr {sympa-dev{\at}cru.fr}, \Sympa developers
			
	   \item   \mailaddr {sympa-translation{\at}cru.fr}, \Sympa translators
  
	\end {itemize}

To join, send the following message to \mailaddr {sympa{\at}cru.fr}:

\begin {quote}
    \texttt {subscribe} \textit {Listname} \textit {Firstname} \textit {Name}
\end {quote}

(replace \textit {Listname}, \textit {Firstname} and \textit {Name} by the list name, your first name and your family name).

You may also consult the \Sympa \htmladdnormallink {home page} {http://www.sympa.org},
you will find the latest version, \htmladdnormallink {FAQ} {http://www.sympa.org/distribution/} and so on.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Overview: what does \Sympa consist of ?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\cleardoublepage
\chapter {what does \Sympa consist of ?}

%\begin {htmlonly}
%<A NAME="overview">
%\end {htmlonly}

\section {Organization}
\label {organization}

Here is a snapshot of what \Sympa looks like once it has settled down
on your system. This also illustrates the \Sympa philosophy, I guess.
Almost all configuration files can be defined for a particular list, for
a virtual host or for the whole site.  
 
\begin {itemize}

	\item \dir {[DIR]}\\
	The root directory of \Sympa. You will find almost everything
	related to \Sympa under this directory, except logs and main
	configuration files.
	
	\item \dir {[BINDIR]}\\
	This directory contains the binaries, including the CGI. It
	also contains the default authorization scenarios, templates and configuration
	files as in the distribution.  \dir {[BINDIR]} may be completely
        overwritten by the \unixcmd {make install} so you must not customize
        templates and authorization scenarios under  \dir {[BINDIR]}.

	\item \dir {[ETCBINDIR]}\\
	Here \Sympa stores the default versions of what it will otherwise find
	in \dir {[ETCDIR]} (task models, authorization scenarios, templates and configuration
	files, recognized S/Mime certificates, families).

	\item \dir {[ETCDIR]}\\
	This is your site's configuration directory. Consult
	\dir {[ETCBINDIR]} when drawing up your own.

	\item \dir {[ETCDIR]/create\_list\_templates/}\\
	List templates (suggested at list creation time).

	\item \dir {[ETCDIR]/scenari/}\\
	This directory will contain your authorization scenarios.
	If you don't know what the hell an authorization scenario is, refer to \ref {scenarios},page~\pageref {scenarios}. Those authorization scenarios are default scenarios but you may look at
        \dir {[ETCDIR]/\samplerobot/scenari/} for default scenarios of \samplerobot
        virtual host and \dir {[EXPL_DIR]/\samplelist/scenari} for scenarios
        specific to a particular list 

	\item \dir {[ETCDIR]/data\_sources/}\\
	This directory will contain your .incl files (see \ref {data-inclusion-file}, page~\pageref {data-inclusion-file}). 
	For the moment it only deals with files requiered by paragraphs \lparam {owner\_include} and \lparam {editor\_include} in the config file.

	\item \dir {[ETCDIR]/list\_task\_models/}\\
	This directory will store your own list task models (see \ref {tasks}, page~\pageref {tasks}).	

	\item \dir {[ETCDIR]/global\_task\_models/}\\
	Contains global task models of yours (see \ref {tasks}, page~\pageref {tasks}).		
	
	\item \dir {[ETCDIR]/web\_tt2/} (used to be \dir {[ETCDIR]/wws\_templates/})\\
	The web interface (\WWSympa) is composed of template HTML
	files parsed by the CGI program. Templates can also 
        be defined for a particular list in \dir {[EXPL_DIR]/\samplelist/web\_tt2/}
        or in \dir {[ETCDIR]/\samplerobot/web\_tt2/}

	\item \dir {[ETCDIR]/mail\_tt2/} (used to be \dir {[ETCDIR]/templates/})\\
	Some of the mail robot's replies are defined by templates
	(\file{welcome.tt2} for SUBSCRIBE). You can overload
	these template files in the individual list directories or
        for each virtual host, but these are the defaults.

	\item \dir {[ETCDIR]/families/}\\
	Contains family directories of yours (see \ref {ml-creation}, page~\pageref {ml-creation}).
	Families directories can also be created in \dir {[ETCDIR]/\samplerobot/families/}

	\item \dir {[ETCDIR]/\samplerobot}\\
        The directory to define the virtual host \samplerobot dedicated to
        managment of all lists of this domain (list description of \samplerobot are stored
        in \dir {[EXPL_DIR]/\samplerobot}).
        Those directories for virtual hosts have the same structure as  \dir {[ETCDIR]} which is
        the configuration dir of the default robot. 

	\item \dir {[EXPL_DIR]}\\
	\Sympa's working directory.

	\item \dir {[EXPL_DIR]/\samplelist}\\
	The list directory (refer to \ref {ml-definition}, 
	page~\pageref {ml-definition}). Lists stored in this directory
        belong to the default robot as defined in sympa.conf file, but a list
        can be stored in \dir {[EXPL_DIR]/\samplerobot/\samplelist} directory and it
        is managed by \samplerobot virtual host.

	\item \dir {[EXPL_DIR]/X509-user-certs}\\
	The directory where Sympa stores all user's certificates

	\item \dir {[LOCALEDIR]}\\
	Internationalization directory. It contains message catalogues in the GNU .po format. 
%\Sympa has currently been translatedinto 14 different languages.

	\item \dir {[SPOOLDIR]}\\
	\Sympa uses 9 different spools (see \ref{spools}, page~\pageref{spools}).

	\item \dir {[DIR]/src/}\\
	\Sympa sources.

\end {itemize}

\section {Binaries}
\label {binaries}

\begin {itemize}

	\item \file {sympa.pl}\\
	The main daemon ; it processes commands and delivers
	messages. Continuously scans the \dir {msg/} spool.

	\item \file {sympa\_wizard.pl}\\
	A wizard to edit \file {sympa.conf} and \file {wwsympa.conf}.
	Maybe it is a good idea to run it at the beginning, but these
	file can also be edited with your favorite text editor. 

	\item \file {wwsympa.fcgi}\\
	The CGI program offering a complete web interface
	to mailing lists. It can work in both classical CGI and
	FastCGI modes, although we recommend FastCGI mode, being
	up to 10 times faster.

	\item \file {bounced.pl}\\
	This daemon processes bounces (non-delivered messages),
	looking for bad addresses. List owners will later
	access bounce information via \WWSympa. Continuously scans
	the \dir {bounce/} spool.

	\item \file {archived.pl}\\
	This daemon feeds the web archives, converting messages
	to HTML format and linking them. It uses the amazing 
	\file {MhOnArc}. Continuously scans the \dir {outgoing/} 
	spool.

	\item \file {task\_manager.pl}\\
	The daemon which manages the tasks : creation, checking, execution. 
	It regularly scans the \dir {task/} spool.

	\item \file {sympa\_soap\_server.fcgi}\\
	The server will process SOAP (web services) request. This server requires FastCGI ;
	it should be referenced from within your HTTPS config.

	\item \file {queue}\\
	This small program gets the incoming messages from the aliases
	and stores them in \dir {msg/} spool.

	\item \file {bouncequeue}\\
	Same as \file {queue} for bounces. Stores bounces in 
	\dir {bounce/} spool.

\end {itemize}

\section {Configuration files}

\begin {itemize}

	\item \file {[CONFIG]}\\
	The main configuration file.
	See \ref{exp-admin}, page~\pageref{exp-admin}.
	

	\item \file {[WWSCONFIG]}\\
	\WWSympa configuration file.
	See \ref{wwsympa}, page~\pageref{wwsympa}.
	
	\item \file {edit\_list.conf}\\
	Defines which parameters/files are editable by
	owners. See \ref{list-edition}, page~\pageref{list-edition}.

	\item \file {topics.conf}\\
	Contains the declarations of your site's topics (classification in
	\WWSympa), along with their titles. A sample is provided in the
	\dir {sample/} directory of the sympa distribution.
	See \ref{topics}, page~\pageref{topics}.

	\item \file {auth.conf}\\
	Defines authentication backend organisation ( \textindex {LDAP-based authentication},  \textindex {CAS-based authentication} and sympa internal )

	\item \file {robot.conf}\\
	It is a subset of \file {sympa.conf} defining a Virtual host 
	(one per Virtual host).

	\item \file {nrcpt\_by\_domain}\\
	\label {nrcptbydomain}
	This file is used to limit the number of recipients per SMTP session. Some ISPs trying to \textindex {block spams}
	rejects sessions with too many recipients. In such case you can set the  \ref {nrcpt} robot.conf parameter
        to a lower value but this will affect all smtp session with any remote MTA. This file is used to limit the number
        of receipient for some particular domains. the file must contain a list of domain followed by the maximum number
        of recipient per SMTP session. Example : 

	\item \file {data\_structure.version}\\
	This file is automatically created and maintained by Sympa itself. It contains the current version of your Sympa service
	and is used to detect upgrades and trigger maintenance procedures such as database structure changes.

\begin {quote}
\begin{verbatim}
     yohaa.com 3
     oal.com 5
\end{verbatim}
\end {quote}
\end {itemize}

\section {Spools}
\label {spools}

See \ref{spool-related}, page~\pageref{spool-related} for spool definition
in \file {sympa.conf}.

\begin {itemize}

	\item \dir {[SPOOLDIR]/auth/}\\
	For storing messages until they have been confirmed.

	\item \dir {[SPOOLDIR]/bounce/}\\
	For storing incoming bouncing messages.

	\item \dir {[SPOOLDIR]/digest/}\\
	For storing lists' digests before they are sent.

	\item \dir {[SPOOLDIR]/mod/}\\
	For storing unmoderated messages.

	\item \dir {[SPOOLDIR]/msg/}\\
	For storing incoming messages (including commands).

	\item \dir {[SPOOLDIR]/msg/bad/}\\
	\Sympa stores rejected messages in this directory

	\item \dir {[SPOOLDIR]/distribute/}\\
	For storing message ready for distribution. This spool is used only if the installation run 2 sympa.pl daemon, one for commands, one for messages. 

	\item \dir {[SPOOLDIR]/distribute/bad/}\\
	\Sympa stores rejected messages in this directory
	
	\item \dir {[SPOOLDIR]/task/}\\
	For storing all created tasks.

	\item \dir {[SPOOLDIR]/outgoing/}\\
	\file {sympa.pl} dumps messages in this spool to await archiving
	by \file {archived.pl}.

	\item \dir {[SPOOLDIR]/topic/}\\
	For storing topic information files. 

\end {itemize}

\section {Roles and privileges}
\label {roles}

You can assign roles to users (via their email addresses) at different level in Sympa ; privileges are associated (or can be associated) to these roles.
We list these roles below (from the most powerful to the less), along with the relevent privileges.

\subsection {(Super) listmasters}

These are the persons administrating the service, defined in the \file {sympa.conf} file. They inherit the listmaster role in virtual hosts and are the default set
of listmasters for virtual hosts.

\subsection {(Robot) listmasters}

You can define a different set of listmasters at a virtual host level (in the \file {robot.conf} file). They are responsible for moderating mailing lists creation (if list creation is configured this way), editing default templates, providing help to list owners and moderators. Users defined as listmasters get a privileged access to Sympa web interface. Listmasters also inherit the privileges of list owners (for any list defined in the virtual host), but not the moderator privileges.

\subsection {Privileged list owners}

The first defined privileged owner is the person who requested the list creation. Later it can be changed or extended. They inherit (basic) owners privileges and are also responsible for managing the list owners and editors themselves (via the web interface). With Sympa'd default behavior, privileged owners can edit more list parameters than (basic) owners can do ; but this can be customized via the \file {edit-list.conf} file.

\subsection {(Basic) list owners}

They are responsible for managing the members of the list, editing the list configuration and templates. Owners (and privileged owners) are defined in the list config file.

\subsection {Moderators (also called Editors)}

Moderators are responsible for the messages distributed in the mailing list (as opposed to owners who look after list members). Moderators are active if the list has been setup as a moderated mailing list. If no moderator is defined for the list, then list owners will inherit the moderator role.

\subsection {Subscribers (or list members)}

Subscribers are the persons who are member of a mailing list ; they either subscribed, or got added directly by the listmaster or via a datasource (LDAP, SQL, another list,...). These subscribers receive messages posted in the list (unless they have set the \texttt {nomail} option) and have special privileges to post in the mailing list (unless it is a newsletter). Most privileges a subscriber may have is not hardcoded in Sympa but expressed via the so-called authorization scenarios (see \ref {scenarios}, page ~\pageref {scenarios}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Installing Sympa
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\cleardoublepage
\chapter {Installing \Sympa}

%\begin {htmlonly}
%<A NAME="installsympa">
%\end {htmlonly}

\Sympa is a program written in PERL. It also calls a short
program written in C for tasks which it would be unreasonable to
perform via an interpreted language.

\section {Obtaining \Sympa, related links}

The \Sympa distribution is available from
\htmladdnormallink {\texttt {http://www.sympa.org}}
    {http://www.sympa.org}.
All important resources are referenced there:

\begin {itemize}
    \item sources
    \item \file {RELEASE\_NOTES}
    \item .rpm and .deb packages for Linux
    \item user mailing list
        (see~\ref {sympa@cru.fr}, page~\pageref {sympa@cru.fr})
    \item contributions
    \item ...
\end {itemize}


\section {Prerequisites}

\Sympa installation and configuration are relatively easy
tasks for experienced UNIX users who have already installed PERL packages.

Note that most of the installation time will
involve putting in place the prerequisites, if they are not
already on the system. No more than a handful of ancillary tools are needed,
and on recent UNIX systems their installation is normally very
straightforward. We strongly advise you to perform installation steps and
checks in the order listed below; these steps will be explained in
detail in later sections.

\begin {itemize}
    \item identification of host system characteristics

    \item installation of DB Berkeley module (already installed on
      most UNIX systems)

    \item installing a \textindex{RDBMS} (\textindex{Oracle}, \textindex{MySQL}, \textindex{SQLite}, \textindex{Sybase} or \textindex{PostgreSQL}) and creating \Sympa's Database. This is required for using the web interface for \Sympa. Please refers to \Sympa and its database section (\ref {sec-rdbms}, page~\pageref {sec-rdbms}).

   \item installation of \htmladdnormallinkfoot {libxml 2}{http://xmlsoft.org/}, required by the \textindex {LibXML} perl module.

    \item installation of
	\textindex{CPAN}
        \htmladdnormallinkfoot {CPAN (Comprehensive PERL Archive Network)}
                {http://www.perl.com/CPAN}
        modules

    \item creation of a UNIX user

\end {itemize}

\subsection {System requirements}

You should have a UNIX system that is more or less recent in order
to be able to use \Sympa. In particular, it is necessary
that your system have an ANSI C compiler (in other words, your compiler
should support prototypes);

\Sympa has been installed and tested on the following
systems, therefore you should not have any special problems:

\begin {itemize}
    \item Linux (various distributions)
    \item FreeBSD 2.2.x and 3.x
    \item NetBSD
    \item Digital UNIX 4.x
    \item Solaris 2.5 and 2.6
    \item AIX 4.x
    \item HP-UX 10.20
\end {itemize}

Anyone willing to port it to NT ? ;-)

Finally, most UNIX systems are now supplied with an ANSI C compiler;
if this is not the case, you can install the \unixcmd {gcc} compiler,
which you will find on the nearest GNU site, for example
\htmladdnormallinkfoot {in France} {ftp://ftp.oleane.net/pub/mirrors/gnu/}.

To complete the installation, you should make sure that you have a
sufficiently recent release of the \unixcmd {sendmail} MTA, i.e. release
\htmladdnormallinkfoot {8.9.x} {ftp://ftp.oleane.net/pub/mirrors/sendmail-ucb/}
or a more recent release. You may also use \unixcmd {postfix} or
\unixcmd {qmail}.

\subsection {Install Berkeley DB (NEWDB)}

UNIX systems often include a particularly unsophisticated mechanism to
manage indexed files.  This consists of extensions known as \texttt {dbm}
and \texttt {ndbm}, which are unable to meet the needs of many more recent
programs, including \Sympa, which uses the \textindex {DB package}
initially developed at the University of California in Berkeley,
and which is now maintained by the company \htmladdnormallinkfoot
{Sleepycat software} {http://www.sleepycat.com}.  Many UNIX  systems
like Linux, FreeBSD or Digital UNIX 4.x have the DB package in the
standard version. If not you should install this tool if you have not 
already done so.

You can retrieve DB on the
\htmladdnormallinkfoot {Sleepycat site} {http://www.sleepycat.com/},
where you will also find clear installation instructions.

\subsection {Install PERL and CPAN modules}
\label{Install PERL and CPAN modules}
	\index{CPAN}

To be able to use \Sympa you must have release 5.004\_03 or later of the
PERL language, as well as several CPAN modules.

At \texttt {make} time, the \unixcmd {check\_perl\_modules.pl} script is run to
check for installed versions of required PERL and CPAN modules. If a CPAN module is
missing or out of date, this script will install it for you. 

You can also download and install CPAN modules yourself. You will find 
a current release of the PERL interpreter in the nearest CPAN archive. 
If you do not know where to find a nearby site, use the
\htmladdnormallinkfoot {CPAN multiplexor} {http://www.perl.com/CPAN/src/latest.tar.gz};
it will find one for you.

\subsection {Required CPAN modules}

The following CPAN modules required by \Sympa are not included in the standard
PERL distribution. At \unixcmd {make} time, Sympa will prompt you for missing
Perl modules and will attempt to install the missing ones automatically ; this 
operation requires root privileges.

Because Sympa features evolve from one relaease to another, the following list 
of modules might not be up to date :

\begin {itemize}
   \item \perlmodule {DB\_File} (v. 1.50 or later)
   \item \perlmodule {Digest-MD5}
   \item \perlmodule {MailTools} (version 1.13 o later)
   \item \perlmodule {IO-stringy}
   \item \perlmodule {MIME-tools} (may require IO/Stringy)
   \item \perlmodule {MIME-Base64}
   \item \perlmodule {CGI}
   \item \perlmodule {File-Spec}
   \item \perlmodule {libintl-perl}
   \item \perlmodule {Template-Toolkit}
\end {itemize}

Since release 2, \Sympa requires an RDBMS to work properly. It stores 
users' subscriptions and preferences in a database. \Sympa is also
able to extract user data from within an external database. 
These features require that you install database-related PERL libraries.
This includes the generic Database interface (DBI) and a Database Driver
for your RDBMS (DBD) :

\begin {itemize}
   \item \perlmodule {DBI} (DataBase Interface)

   \item \perlmodule {DBD} (DataBase Driver) related to your RDBMS (e.g.
       Msql-Mysql-modules for MySQL)

\end {itemize}

If you plan to interface \Sympa with an \textindex {LDAP} directory to build
dynamical mailing lists, you need to install PERL LDAP libraries :

\begin {itemize}
    \item \perlmodule {Net::LDAP} (perlldap).

\end {itemize}

Passwords in Sympa database can be crypted ; therefore you need to
install the following reversible cryptography library :

\begin {itemize}

    \item \perlmodule {CipherSaber}

\end {itemize}

For performence concerns, we recommend using \WWSympa as a persistent CGI,
using \textindex {FastCGI}. Therefore you need to install the following Perl module :

\begin {itemize}

    \item \perlmodule {FCGI}

\end {itemize}

If you want to Download Zip files of list's Archives, you'll need to install
perl Module for Archive Management : 

\begin {itemize}

    \item \perlmodule {Archive::Zip}

\end {itemize}


\subsection {Create a UNIX user}

The final step prior to installing \Sympa: create a UNIX user (and
if possible a group) specific to the program. Most of the installation
will be carried out with this account. We suggest that you use the
name \texttt {sympa} for both user and group. 

Numerous files will be located in the \Sympa user's login directory.
Throughout the remainder of this documentation we shall refer to this
login directory as \dir {[DIR]}.

\section {Compilation and installation }

Before using \Sympa, you must customize the sources in order to
specify a small number of parameters specific to your installation.

First, extract the sources from the archive file, for example
in the \tildedir {sympa/src/} directory: the archive will create a
directory named \dir {sympa-\version/} where all the useful files
and directories will be located. In particular, you will have a
\dir {doc/} directory containing this documentation in various
formats; a \dir {sample/} directory containing a few examples of
configuration files; a \dir {locale/} directory where multi-lingual
messages are stored; and, of course, the \dir {src/} directory for the
mail robot and \dir {wwsympa} for the web interface.

Example:

\begin {quote}
\tt
\# su - \\
\$ gzip -dc sympa-\version.tar.gz | tar xf -
\end {quote}

\label {makefile}

Now you can run the installation process :

\begin {quote}
\tt
\$ ./configure\\
\$ make\\
\$ make install\\
\end {quote}


\unixcmd {configure} will build the \file {Makefile} ; it recognizes the following 
command-line arguments :

\begin {itemize}

\item \option {- - prefix=PREFIX}, the \Sympa homedirectory (default /home/sympa/)

\item \option {- - with-bindir=DIR}, user executables in DIR (default /home/sympa/bin/)\\
\file {queue} and \file {bouncequeue} programs will be installed in this directory.
If sendmail is configured to use smrsh (check the mailer prog definition in your sendmail.cf),
this should point to \dir {/etc/smrsh}.  This is probably the case if you are using Linux RedHat.

\item \option {- - with-sbindir=DIR}, system admin executables in DIR (default /home/sympa/bin)

\item \option {- - with-libexecdir=DIR}, program executables in DIR (default /home/sympa/bin)

\item \option {- - with-cgidir=DIR}, CGI programs in DIR (default /home/sympa/bin)

\item \option {- - with-iconsdir=DIR}, web interface icons in DIR (default /home/httpd/icons)

\item \option {- - with-datadir=DIR}, default configuration data in DIR (default /home/sympa/bin/etc)

\item \option {- - with-confdir=DIR}, Sympa main configuration files in DIR (default /etc)\\
\file {sympa.conf} and \file {wwsympa.conf} will be installed there.

\item \option {- - with-expldir=DIR}, modifiable data in DIR (default /home/sympa/expl/)

\item \option {- - with-libdir=DIR},  code libraries in DIR (default /home/sympa/bin/)

\item \option {- - with-mandir=DIR}, man documentation in DIR (default /usr/local/man/)

\item \option {- - with-docdir=DIR}, man files in DIR (default /home/sympa/doc/)

\item \option {- - with-initdir=DIR}, install System V init script in DIR  (default /etc/rc.d/init.d)

\item \option {- - with-lockdir=DIR}, create lock files in DIR  (default /var/lock/subsys)

\item \option {- - with-piddir=DIR}, create .pid files in DIR  (default /home/sympa/)

\item \option {- - with-etcdir=DIR}, Config directories populated by the user are in DIR (default /home/sympa/etc)

\item \option {- - with-localedir=DIR}, create language files in DIR (default /home/sympa/locale)

\item \option {- - with-scriptdir=DIR}, create script files in DIR (default /home/sympa/script)

\item \option {- - with-sampledir=DIR}, create sample files in DIR (default /home/sympa/sample)

\item \option {- - with-spooldir=DIR}, create directory in DIR (default /home/sympa/spool)

\item \option {- - with-perl=FULLPATH}, set full path to Perl interpreter (default /usr/bin/perl)

\item \option {- - with-openssl=FULLPATH}, set path to OpenSSL (default /usr/local/ssl/bin/openssl)

\item \option {- - with-user=LOGI}, set sympa user name (default sympa)\\
\Sympa daemons are running under this UID.

\item \option {- - with-group=LOGIN}, set sympa group name (default sympa)\\
\Sympa daemons are running under this UID.

\item \option {- - with-sendmail\_aliases=ALIASFILE}, set aliases file to be used by Sympa (default /etc/mail/sympa\_aliases). Set to 'none' to disable alias management (You can overright this value at runtime giving its value in \file {sympa.conf})\\

\item \option {- - with-virtual\_aliases=ALIASFILE}, set postfix virtual file to be used by Sympa (default /etc/mail/sympa\_virtual)\\

This is used by the \file {alias\_manager.pl} script :

\item \option {- - with-newaliases=FULLPATH}, set path to sendmail newaliases command (default /usr/bin/newaliases)

\item \option {- - with-newaliases\_arg=ARGS}, set arguments to newaliases command (default NONE)

This is used by the \file {postfix\_manager.pl} script :

\item \option {- - with-postmap=FULLPATH}, set path to postfix postmap command (default /usr/sbin/postmap)

\item \option {- - with-postmap\_arg=ARGS}, set arguments to postfix postmap command (default NONE)

\item \option {- - enable-secure}, install wwsympa to be run in a secure mode, without suidperl (default disabled)


\end {itemize}


\unixcmd {make} will build a few binaries (\file {queue}, \file {bouncequeue} and \file {aliaswrapper})
and help you install required CPAN modules.

\unixcmd {make install} does the installation job. It it recognizes the following option :

\begin {itemize}

\item DESTDIR, can be set in the main Makefile to install sympa in DESTDIR/DIR
(instead of DIR). This is useful for building RPM and DEB packages.

\end {itemize}

Since version 3.3 of Sympa colors are \file {sympa.conf} parameters (see
\ref {colors},  page~\pageref {colors})

If everything goes smoothly, the \tildedir {sympa/bin/} directory
will contain various PERL programs as well as the \file {queue}
binary.  You will remark that this binary has the \index{set-uid-on-exec
bit} \textit {set-uid-on-exec} bit set (owner is the \texttt {sympa}
user): this is deliberate, and indispensable if \Sympa is to run correctly.

\subsection {Choosing directory locations}

All directories are defined in the \file {/etc/sympa.conf} file, which
is read by \Sympa at runtime. If no \file {sympa.conf} file
was found during installation, a sample one will be created.
For the default organization of directories, please refer to \ref {organization}, 
page~\pageref {organization}.

It would, of course, be possible to disperse files and directories to a number of different
locations. However, we recommend storing all the directories and files in  the \texttt {sympa}
user's login directory.

These directories must be created manually now. You can use restrictive
authorizations if you like, since only programs running with the
\texttt {sympa} account will need to access them.


\section {Robot aliases}

See Robot aliases , \ref {robot-aliases},
page~\pageref {robot-aliases})
 
\section {Logs}

\Sympa keeps a trace of each of its procedures in its log file.
However, this requires configuration of the \unixcmd {syslogd}
daemon.  By default \Sympa will use the \texttt {local1} facility
(\lparam {syslog} parameter in \file {sympa.conf}).
WWSympa's logging behaviour is defined by the \lparam {log\_facility}
parameter in \file {wwsympa.conf} (by default the same facility as \Sympa).\\
To this end, a line must be added in the \unixcmd {syslogd} configuration file (\file
{/etc/syslog.conf}). For example:

\begin {quote}
\begin{verbatim}
local1.*       /var/log/sympa 
\end{verbatim}
\end {quote}

Then reload \unixcmd {syslogd}.

Depending on your platform, your syslog daemon may use either
a UDP or a UNIX socket. \Sympa's default is to use a UNIX socket;
you may change this behavior by editing \file {sympa.conf}'s
\lparam {log\_socket\_type} parameter (\ref{par-log-socket-type},
page~\pageref{par-log-socket-type}). You can test log feature by
using  \file {testlogs.pl}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Running Sympa
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\cleardoublepage
\chapter {Running \Sympa}

\section {sympa.pl}
\label{sympa.pl}

\file {sympa.pl} is the main daemon ; it processes mail commands and is in charge of
messages distribution.

\file {sympa.pl} recognizes the following command line arguments:

\begin {itemize}

\item \option {- - debug} | \option {-d} 
  
  Sets \Sympa in debug mode and keeps it attached to the terminal. 
  Debugging information is output to STDERR, along with standard log
  information. Each function call is traced. Useful while reporting
  a bug.

\item \option {\-\-service}  \textit {process\_command} | \textit {process\_message} | \textit {process\_creation}
  
  Sets \Sympa daemon in way it process only message distribution (process\_message) or in way it process only command (process\_command) or to process 
  list creation requests (process\_creation)
  
\item \option {- - config \textit {config\_file}} | \option {-f \textit {config\_file}}
  
  Forces \Sympa to use an alternative configuration file. Default behavior is
  to use the configuration file as defined in the Makefile (\$CONFIG).
  
\item \option {- - mail} | \option {-m} 
  
  \Sympa will log calls to sendmail, including recipients. Useful for
  keeping track of each mail sent (log files may grow faster though).
  
\item \option {- - lang \textit {catalog}} | \option {-l \textit {catalog}}
  
  Set this option to use a language catalog for \Sympa. 
  The corresponding catalog file must be located in \tildedir {sympa/locale}
  directory. 
  
\item \option {- - keepcopy \textit {recipient\_directory}} | \option {-k \textit {recipient\_directory}}

  This option tells Sympa to keep a copy of every incoming message,
  instead of deleting them. \textit {recipient\_directory} is the directory
  to store messages.

  
  \begin {quote}
\begin{verbatim}
/home/sympa/bin/sympa.pl
\end{verbatim}
  \end {quote}

\item \option {- - create\_list - - robot \textit {robotname} - - input\_file \textit {/path/to/list\_file.xml}}

Create the list described by the xml file, see \ref{list-creation-sympa}, 
page~\pageref{list-creation-sympa}.

\item \option {- - close\_list \textit {listname@robot}}

Close the list (changing its status to closed), remove aliases (if sendmail\_aliases
parameter was set) and remove
subscribers from DB (a dump is created in the list directory to allow restoring
the list). See \ref{family-close-list}, page~\pageref{family-close-list} when you
are in a family context.

\item \option {- - dump \textit {listname \texttt {|} ALL}}
  
  Dumps subscribers of a list or all lists. Subscribers are dumped
  in \file {subscribers.db.dump}.
 
\item \option {- - import \textit {listname}}
  
Import subscribers in the \textit {listname} list. Data are read from STDIN.
  
\item \option {- - lowercase}
  
Lowercases e-mail addresses in database.

\item \option {- - help} | \option {-h}
  
  Print usage of sympa.pl.
   
\item \option {- - make\_alias\_file}
  
Create an aliases file in /tmp/ with all list aliases (only list which status is 'open'). It uses the list\_aliases.tt2
template.

\item \option {- - version} | \option {-v}
  
  Print current version of \Sympa.

\item \option {- - instanciate\_family \textit {familyname} \textit {robotname} - - input\_file \textit {/path/to/family\_file.xml}}

Instantiate the family \textit {familyname}. See \ref{lists-families}, 
page~\pageref{lists-families}.

\item \option {- - close\_family \textit {familyname} - - robot \textit {robotname}}
   
   Close the \textit {familyname} family. See \ref{family-closure}, 
   page~\pageref{family-closure}.
 
 \item \option {- - add\_list \textit {familyname} - - robot \textit {robotname} - - input\_file \textit {/path/to/list\_file.xml}}
 
   Add the list described in the XML file to the \textit{familyname} family. See \ref{family-add-list}, 
   page~\pageref{family-add-list}.
 
 \item \option {- - modify\_list \textit {familyname} - - robot \textit {robotname} - - input\_file \textit {/path/to/list\_file.xml}}
 
   Modify the existing family list, with description contained in the XML file. See \ref{family-modify-list}, 
   page~\pageref{family-modify-list}.
    
 \item \option {- - sync\_include \textit {listaddress} }
 
   Trigger an update of list members, usefull if the list uses
   external data sources.

 \item \option {- - upgrade - - from=X - -to=Y }
 
   Runs Sympa maintenance script to upgrate from version X to version Y

 \item \option {- - reload\_list\_config - -list=mylist@dom }
 
   Recreates all \file {config\.bin} files. You should run this command if you edit authorization scenarios. The list parameter is optional.


\end {itemize}

\section {INIT script}
\label{init}
 
 The \unixcmd {make install} step should have installed a sysV init script in
 your \dir {/etc/rc.d/init.d/} directory (you can change this at \unixcmd {configure}
 time with the \option {--with-initdir} option). You should edit your runlevels to make
 sure \Sympa starts after Apache and MySQL. Note that \textindex{MySQL} should
 also start before \textindex{Apache} because of \file {wwsympa.fcgi}.
 
 This script starts these deamons : sympa.pl, task\_manager.pl, archived.pl and bounced.pl.
 
\section {Stopping \Sympa and signals}
 \label{stop-signals}
 \index{stop-signals}
 
 \subsubsection{\file{kill -TERM}}
 
 When this signal is sent to sympa.pl (\option {kill -TERM}), the daemon is stopped ending message distribution in progress 
 and this can be long (for big lists). If \option {kill -TERM} is used, sympa.pl will stop immediatly whatever a distribution 
 message is in progress. In this case, when sympa.pl restart, message will distributed many times.
 
 \subsubsection{\file{kill -HUP}}
 
 When this signal is sent to sympa.pl (\option {kill -HUP}), it switchs of the \option{--mail} logging option
 and continues current task.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Upgrading Sympa
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\cleardoublepage
\chapter {Upgrading Sympa}
    \label {upgrading-sympa}

Sympa upgrade is a relatively riskless operations, mainly because the install process preserves your
customizations (templates, configuration, authorization scenarios,...) and also because Sympa automates
a few things (DB update, CPAN modules installation). 

\section {Incompatible changes}
    \index{changes}

New features, changes and bug fixes are summarized in the \file {NEWS} file, part of the tar.gz (the 
\file {Changelog} file is a complete log file of CVS changes). 


Sympa is a long-term project, so some major changes may need some extra work. The following list is well kown changes that require some attention :
\begin {itemize}
\item version 5.1 (August 2005) use XHTML and CSS in web templates
\item version 4.2b3 (August 2004) introduce TT2 template format
\item version 4.0a5 (September 2003) change auth.conf (no default anymore so you may have the create this file)
\item version 3.3.6b2 (May 2002) the list parameter user\_data\_source as a new value include2 which is the recommended value for any list.
\end {itemize}


The file \file {NEWS} list all changes and of course, all changes that may require some attention from the installer. As mentionned at the beginning of this
file, incompatible changes are preceded by '*****'. While running the \unixcmd {make install} Sympa will
detect the previously installed version and will prompt you with incompatible changes between both versions
of the software. You can interrupt the install process at that stage if you are too frightened.
Output of the \unixcmd {make install} :
\begin {quote}
\begin{verbatim}
You are upgrading from Sympa 4.2
You should read CAREFULLY the changes listed below ; they might be incompatible changes :
<RETURN>

*****   require new perlmodule XML-LibXML

*****   You should update your DB structure (automatically performed by Sympa with MySQL), adding the following table (mySQL example) :
*****   CREATE TABLE admin_table (
*****   list_admin              varchar(50) NOT NULL,
*****   user_admin              varchar(100) NOT NULL,
*****   role_admin              enum('listmaster','owner','editor') NOT NULL,
*****   date_admin              datetime NOT NULL,
*****   update_admin            datetime,
*****   reception_admin         varchar(20),
*****   comment_admin           varchar(150),
*****   subscribed_admin        enum('0','1'),
*****   included_admin          enum('0','1'),
*****   include_sources_admin   varchar(50),
*****   info_admin              varchar(150),
*****   profile_admin           enum('privileged','normal'),
*****   PRIMARY KEY (list_admin, user_admin,role_admin),
*****   INDEX (list_admin, user_admin,role_admin)
*****   );

*****   Extend the generic_sso feature ; Sympa is now able to retrieve the user email address in a LDAP directory
<RETURN>
\end{verbatim}
\end {quote}

\section {CPAN modules update}
    \index{cpan update}

Required and optional perl modules (CPAN) installation is automatically handled at the \unixcmd {make} time. You are asked before each module is installed. For optional modules, associated features are listed.

Output of the \unixcmd {make} command :
\begin {quote}
\begin{verbatim}
Checking for REQUIRED modules:
------------------------------------------
perl module          from CPAN       STATUS
-----------          ---------       ------
Archive::Zip         Archive-Zip    OK (1.09   >= 1.05)
CGI                  CGI            OK (2.89   >= 2.52)
DB_File              DB_FILE        OK (1.806  >= 1.75)
Digest::MD5          Digest-MD5     OK (2.20   >= 2.00)
FCGI                 FCGI           OK (0.67   >= 0.67)
File::Spec           File-Spec      OK (0.83   >= 0.8)
IO::Scalar           IO-stringy     OK (2.104  >= 1.0)
LWP                  libwww-perl    OK (5.65   >= 1.0)
Locale::TextDomain   libintl-perl   OK (1.10   >= 1.0)
MHonArc::UTF8        MHonArc        version is too old ( < 2.4.6).
>>>>>>> You must update "MHonArc" to version "" <<<<<<.
Setting FTP Passive mode
Description: 
Install module MHonArc::UTF8 ? [y]n
MIME::Base64         MIME-Base64    OK (3.05   >= 3.03)
MIME::Tools          MIME-tools     OK (5.411  >= 5.209)
Mail::Internet       MailTools      OK (1.60   >= 1.51)
Regexp::Common       Regexp-Common  OK (2.113  >= 1.0)
Template             Template-ToolkitOK (2.13   >= 1.0)
XML::LibXML          XML-LibXML     OK (1.58   >= 1.0)

Checking for OPTIONAL modules:
------------------------------------------
perl module          from CPAN       STATUS
-----------          ---------       ------
Bundle::LWP          LWP            OK (1.09   >= 1.09)
Constant subroutine CGI::XHTML_DTD redefined at /usr/lib/perl5/5.8.0/constant.pm line 108, <STDIN> line 1.
CGI::Fast            CGI            CGI::Fast doesn't return 1 (check it).
Crypt::CipherSaber   CipherSaber    OK (0.61   >= 0.50)
DBD::Oracle          DBD-Oracle     was not found on this system.
Description: Oracle database driver, required if you connect to a Oracle database.
Install module DBD::Oracle ? [n]
\end{verbatim}
\end {quote}



\section {Database structure update}
    \index{db update}

Whatever RDBMS you are using (mysql, SQLite, Pg, Sybase or Oracle) Sympa will check every database tables and fields. If one is missing \file {sympa.pl}
will not start. If you are using \textindex{mysql} Sympa will also check field types and will try to change them (or create them) automatically ; 
assuming that the DB user configured has sufficient privileges. If You are not using Mysql or if the DB user configured in \file {sympa.conf} 
does have sufficient privileges, then you should change the database structure yourself, as mentionned in the \file {NEWS} file.

Output of Sympa logs :
\begin {quote}
\begin{verbatim}
Table admin_table created in database sympa
Field 'comment_admin' (table 'admin_table' ; database 'sympa') was NOT found. Attempting to add it...
Field comment_admin added to table admin_table
Field 'date_admin' (table 'admin_table' ; database 'sympa') was NOT found. Attempting to add it...
Field date_admin added to table admin_table
Field 'include_sources_admin' (table 'admin_table' ; database 'sympa') was NOT found. Attempting to add it...
Field include_sources_admin added to table admin_table
Field 'included_admin' (table 'admin_table' ; database 'sympa') was NOT found. Attempting to add it...
Field included_admin added to table admin_table
Field 'info_admin' (table 'admin_table' ; database 'sympa') was NOT found. Attempting to add it...
Field info_admin added to table admin_table
Field 'list_admin' (table 'admin_table' ; database 'sympa') was NOT found. Attempting to add it...
Field list_admin added to table admin_table
Field 'profile_admin' (table 'admin_table' ; database 'sympa') was NOT found. Attempting to add it...
Field profile_admin added to table admin_table
Field 'reception_admin' (table 'admin_table' ; database 'sympa') was NOT found. Attempting to add it...
Field reception_admin added to table admin_table
Field 'role_admin' (table 'admin_table' ; database 'sympa') was NOT found. Attempting to add it...
Field role_admin added to table admin_table
Field 'subscribed_admin' (table 'admin_table' ; database 'sympa') was NOT found. Attempting to add it...
Field subscribed_admin added to table admin_table
Field 'update_admin' (table 'admin_table' ; database 'sympa') was NOT found. Attempting to add it...
Field update_admin added to table admin_table
Field 'user_admin' (table 'admin_table' ; database 'sympa') was NOT found. Attempting to add it...
Setting list_admin,user_admin,role_admin fields as PRIMARY
Field user_admin added to table admin_table
\end{verbatim}
\end {quote}

You might need, for some reason, to make Sympa run the migration procedure from version \textit {X} to version \textit {Y}.
This procedure is run automatically by \file {sympa.pl --upgrade} when it detects that \file {[ETCL_DIR]/data\_structure.version} is older 
than the current version, but you can also run trigger this procedure yourself :
\begin {quote}
\begin{verbatim}
sympa.pl --upgrade --from=4.1 --to=5.2
\end{verbatim}
\end {quote}


\section {Preserving your customizations}
    \index{preserve customizations}

Sympa comes with default configuration files (templates, scenarios,...) that will be installed in the \dir {[BINDIR]} directory. 
If you need to customize some of them, you should copy the file first in a safe place, ie in the \dir {[ETCDIR]} directory.
If you do so, the Sympa upgrade process will preserve your site customizations.


\section {Running 2 Sympa versions on a single server}
    \index{double installation}

This can be very convenient to have a stable version of Sympa and a fresh version for test purpose, both running on the same server.


Both sympa instances must be completely partitioned, unless you want the make production mailing lists visible through the
test service. 

The biggest part of the partitioning is achieved while running the \unixcmd {./configure}. Here is a sample call to \unixcmd {./configure}
on the test server side :

\begin {quote}
\begin{verbatim}
./configure --prefix=/home/sympa-dev \
            --with-confdir=/home/sympa-dev/etc \
            --with-mandir=/home/sympa-dev/man \
            --with-initdir=/home/sympa-dev/init \
	    --with-piddir=/home/sympa-dev/pid
            --with-lockdir=/home/sympa-dev/lock \
            --with-sendmail_aliases=/home/sympa-dev/etc/sympa_aliases 
\end{verbatim}
\end {quote}

You can also customize more parameters via the \file {/home/sympa-dev/etc/sympa.conf} file.

If you wish to share the same lists in both Sympa instances, then some parameters should have the same value :
\cfkeyword {home}, \cfkeyword {db\_name}, \cfkeyword {arc\_path}


\section {Moving to another server}
    \index{new server}

If you're upgrading and moving to another server at the same time, we recommend you first to stop the operational service, move your data and 
then upgrade Sympa on the new server. This will guarantee that Sympa upgrade procedures have been applied
on the data. 

The migration process requires that you move the following data from the old server to the new one :
\begin {itemize}

    \item the user database. If using mysql you can probably just stop \file {mysqld} and copy the \dir {/var/lib/mysql/sympa/}
      directory to the new server.

    \item the \dir {[EXPL_DIR]} directory that contains list config

    \item the \dir {[SPOOL_DIR]} directory that contains the spools

    \item the \dir {[ETCL_DIR]} directory and \file {[CONFIG]} and \file {wwsympa.conf}. Sympa new installation create a file \file {[CONFIG]} (see \ref {exp-admin}) and initialize randomly the cookie parameter. Changing this parameter will break all passwords.  When upgrading Sympa on a new server take care that you start with the same value of this parameter, otherwise you will have troubles !

    \item the web archives

\end {itemize}

In some case, you may want to install the new version and run it for a few days before switching
the existing service to the new Sympa server.  In this case perform a new installation with an empty
database and play with it. When you decide to move the existing service to the new server :
\begin {enumerate}
\item stop all sympa processus on both servers, 
\item transfert the database
\item edit the \file {[ETCL_DIR]/data\_structure.version} on the new server ; change the version value to reflect the old number
\item start \file {sympa.pl --upgrade}, it will upgrade the database structure according the hop you do. 
\end {enumerate}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Mail aliases 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\cleardoublepage
\chapter {Mail aliases}
    \label {aliases}
    \index{aliases}

Mail aliases are required in Sympa for \file {sympa.pl} to receive mail commands and 
list messages. Management of these aliases management will depend on the MTA (\unixcmd {sendmail}, \unixcmd {qmail},
\unixcmd {postfix}, \unixcmd {exim}) you're using, where you store aliases and whether
you are managing virtual domains or not.

\section {Robot aliases}
   \label{robot-aliases}
    \index{robot aliases}

An electronic list manager such as \Sympa is built around two processing steps:

\begin {itemize}
    \item a message sent to a list or to \Sympa itself
        (commands such as subscribe or unsubscribe) is received
        by the SMTP server. The SMTP server, on reception of this message, runs the
        \file {queue} program (supplied in this package) to store
        the message in a spool.

    \item the \file {sympa.pl} daemon, set in motion at
        system startup, scans this spool. As soon as it
        detects a new message, it processes it and performs the
        requested action (distribution or processing of a command).

\end {itemize}

To separate the processing of commands (subscription,
unsubscription, help requests, etc.) from the processing of messages destined for mailing
lists, a special mail alias is reserved for administrative requests, so
that \Sympa can be permanently accessible to users. The following
lines must therefore be added to the \unixcmd {sendmail} alias file
(often \file {/etc/aliases}):

\begin {quote}
sympa:             "| [MAILERPROGDIR]/queue sympa@\samplerobot"\\
listmaster: 	   "| [MAILERPROGDIR]/queue listmaster@\samplerobot"\\
bounce+*:          "| [MAILERPROGDIR]/bouncequeue sympa@\samplerobot"\\
abuse-feedback-report:       "| [MAILERPROGDIR]/bouncequeue sympa@\samplerobot"\\
sympa-request:     postmaster\\
sympa-owner:       postmaster\\
\end {quote}

Note: if you run \Sympa virtual hosts, you will need one \mailaddr {sympa}
alias entry per virtual host (see virtual hosts section, \ref {virtual-robot},
page~\pageref {virtual-robot}).

\mailaddr {sympa-request} should be the address of the robot
\textindex {administrator}, i.e. a person who looks after
\Sympa (here \mailaddr {postmaster{\at}cru.fr}).

\mailaddr {sympa-owner} is the return address for \Sympa error
messages.

The alias bounce+* is dedicated to collect bounces where VERP (variable envelope return path) was actived. It is useful
if \texttt { welcome\_return\_path unique } or \texttt { remind\_return\_path unique} or the
\cfkeyword {verp\_rate} parameter is no null for at least one list.

The alias abuse-feedback-report is used for processing automatically feedback that respect ARF format (Abuse Report Feedback) which is a draft to specify how end user can complain about spam. It is mainly used by AOL.


Don't forget to run \unixcmd {newaliases} after any change to
the \file {/etc/aliases} file!

Note: aliases based on \mailaddr {listserv} (in addition to those
based on \mailaddr {sympa}) can be added for the benefit of users
accustomed to the \mailaddr {listserv} and \mailaddr {majordomo} names.
For example:

\begin {quote}
\begin{verbatim}
listserv:          sympa
listserv-request:  sympa-request
majordomo:         sympa
listserv-owner:    sympa-owner
\end{verbatim}
\end {quote}

\section {List aliases}
\label {list-aliases}
    \index{aliases}
    \index{mail aliases}

For each new list, it is necessary to create up to six mail aliases (at least three).
If you managed to setup the alias manager (see next section) then \Sympa will
install automatically the following aliases for you.

For example, to create the \mailaddr {\samplelist} list, the following
aliases must be added:

\begin {quote}
    \tt
    \begin {tabular} {ll}
        \mailaddr {\samplelist}:         &
            "|[MAILERPROGDIR]/queue \samplelist@\samplerobot"
            \\
        \mailaddr {\samplelist-request}: &
            "|[MAILERPROGDIR]/queue \samplelist-request@\samplerobot"
            \\
        \mailaddr {\samplelist-editor}:  &
            "|[MAILERPROGDIR]/queue \samplelist-editor@\samplerobot"
            \\
        \mailaddr {\samplelist-owner}:   &
            "|[MAILERPROGDIR]/bouncequeue \samplelist@\samplerobot
            \\
        \mailaddr {\samplelist-subscribe}:   &
            "|[MAILERPROGDIR]/queue \samplelist-subscribe@\samplerobot"
            \\
        \mailaddr {\samplelist-unsubscribe}: &
            "|[MAILERPROGDIR]/queue \samplelist-unsubscribe@\samplerobot"
            \\

    \end {tabular}
\end {quote}

%This example demonstrates how to define a list with the low priority
%level 2. Messages for editor and owner will be processed by \Sympa
%with greater priority (level 1) than messages to the list itself.

The address \mailaddr {\samplelist-request} should correspond
to the person responsible for managing \mailaddr {\samplelist}
(the \textindex {owner}).  \Sympa will forward messages for
\mailaddr {\samplelist-request} to the owner of \mailaddr {\samplelist},
as defined in the \file {[EXPL_DIR]/\samplelist/config}
file.  Using this feature means you would not need to modify the
alias file if the owner of the list were to change.

Similarly, the address \mailaddr {\samplelist-editor} can be used
to contact the list editors if any are defined in
\file {[EXPL_DIR]/\samplelist/config}.  This address definition
is not compulsory.

The address \mailaddr {\samplelist-owner} is the address receiving
non-delivery reports (note that the -owner suffix can be customized, 
see~\ref {kw-return-path-suffix}, page~\pageref {kw-return-path-suffix}). 
The \file {bouncequeue} program stores these messages 
in the \dir {queuebounce} directory. \WWSympa ((see~\ref {wwsympa}, page~\pageref {wwsympa})
may then analyze them and provide a web access to them.

The address \mailaddr {\samplelist-subscribe} is an address enabling
users to subscribe in a manner which can easily be explained to them.
Beware: subscribing this way is so straightforward that you may find spammers
subscribing to your list by accident.

The address \mailaddr {\samplelist-unsubscribe} is the equivalent for
unsubscribing. By the way, the easier it is for users to unsubscribe, the easier it will
be for you to manage your list!

\section {Alias manager}
\label {alias-manager}	

The \file {alias\_manager.pl} script does aliases management. It is run by \WWSympa and
 will install aliases for a new list and delete aliases for closed lists. 
%You can use the following script distributed with 
%\Sympa: \tildefile {sympa/bin/alias\_manager.pl} for sendmail-style aliases with a single aliases file.
% or \tildefile {sympa/bin/postfix\_manager.pl} for postfix-like aliases using
%an additional \index{virtusertable}.

The script expects the following arguments :
\begin{enumerate}
  \item add | del
  \item \texttt{<}list name\texttt{>}
  \item \texttt{<}list domain\texttt{>}
\end{enumerate}
Example : \file {[BINDIR]/alias\_manager.pl add \samplelist cru.fr}

\file {[BINDIR]/alias\_manager.pl} works on the alias file as defined in \file {sympa.conf})
by the \cfkeyword {sendmail\_aliases} variable (default is \file {/etc/mail/sympa\_aliases}). You must refer to this aliases file in your \file {sendmail.mc} (if using sendmail) :
\begin {quote}
\begin{verbatim}
define(`ALIAS_FILE', `/etc/aliases,/etc/mail/sympa_aliases')dnl
\end{verbatim}
\end {quote}

Note that \unixcmd{sendmail} has requirements regarding the ownership and rights on both \file {sympa\_aliases} and \file {sympa\_aliases.db} files (the later being created by sendmail via the \unixcmd{newaliases} command). Anyhow these two files should be located in a directory, every path component of which being owned by and writable only by the root user.

\file {[BINDIR]/alias\_manager.pl} runs a \unixcmd{newaliases} command (via \file {aliaswrapper}), after any changes to aliases file.

If you manage virtual domains with your mail server, then you might want to change
the form of aliases used by the alias\_manager. You can customize the \file {list\_aliases}
template that is parsed to generate list aliases (see\ref {list-aliases-tpl},  
page~\pageref {list-aliases-tpl}).

\label {virtual-transport}

Note that you don't need alias management if you use MTA functionalities such as Postfix' \file {virtual\_transport}. You can then disable alias management in \Sympa by positioning the
\cfkeyword {sendmail\_aliases} parameter to \texttt{none}.

\label {ldap-aliases}
A L. Marcotte has written a version of \file {ldap\_alias\_manager.pl} that is LDAP enabled.
This script is distributed with Sympa distribution ; it needs to be customized with your LDAP parameters.

%\tildefile {sympa/bin/postfix\_manager.pl} also requires \index{VIRTUAL\_ALIASES}
%variable to be defined in the Makefile. It runs a \unixcmd{postmap} command (via
%\file {virtualwrapper}), after any changes to virtualtable file.

\section {Virtual domains}
\label {virtual-domains}	

When using virtual domains with \unixcmd {sendmail} or \unixcmd {postfix}, you can't
refer to  \mailaddr {\samplelist@\samplerobot} on the right-hand side of an 
\file {/etc/aliases} entry. You need to define an additional entry in a virtual table.
You can also add a unique entry, with a regular expression, for your domain. 

With Postfix, you should edit the \file {/etc/postfix/virtual.regexp} file as follows :
\begin {quote}
/\verb+^+(.*)@\samplerobot\$/	 \samplerobot-\${1}
\end {quote}
 Entries in the 'aliases' file will look like this :
\begin {quote}
    \samplerobot-sympa:   "|[MAILERPROGDIR]/queue sympa@\samplerobot"
    .....
    \samplerobot-listA:   "|[MAILERPROGDIR]/queue listA@\samplerobot"
\end {quote}

With Sendmail, add the following entry to \file {/etc/mail/virtusertable} file :
\begin {quote}
@\samplerobot  \ \      \samplerobot-\%1\%3
\end {quote}



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% sympa.conf params
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\cleardoublepage
\chapter {sympa.conf parameters}
    \label {exp-admin}
    \index{sympa.conf}
    \index{configuration file}

The \file {[CONFIG]} configuration file contains numerous
parameters which are read on start-up of \Sympa. If you change this file, do not forget
that you will need to restart \Sympa afterwards. 

The \file {[CONFIG]} file contains directives in the following
format:

\begin {quote}
    \textit {keyword    value}
\end {quote}

Comments start with the \texttt {\#} character at the beginning of
a line.  Empty lines are also considered as comments and are ignored.
There should only be one directive per line, but their order in
the file is of no importance.

\section {Site customization}

\subsection {\cfkeyword {domain}}

        This keyword is \textbf {mandatory}. It is the domain name
used in the \rfcheader {From} header in replies to administrative
requests. So the smtp engine (qmail, sendmail, postfix or whatever) must
recognize this domain as a local address. The old keyword \cfkeyword {host}
is still recognized but should not be used anymore.


        \example {domain cru.fr}

\subsection {\cfkeyword {email}} 
	
	\default {sympa}

        Username (the part of the address preceding the \texttt {@} sign) used
        in the \rfcheader {From} header in replies to administrative requests.

        \example {email           listserv}

\subsection {\cfkeyword {listmaster}} 

        The list of e-mail addresses  of listmasters (users authorized to perform
        global  server commands). Listmasters can be defined for each virtual host.

        \example {listmaster postmaster@cru.fr,root@cru.fr}

\subsection {\cfkeyword {listmaster\_email}} 

	\default {listmaster}

        Username (the part of the address preceding the \texttt {@} sign) used 
	in the listmaster email. This parameter is useful if you want to run
	more than one sympa on the same host (a sympa test for example).

	If you change the default value, you must modify the sympa aliases too.

	For example, if you put :

\begin {quote}
listmaster listmaster-test
\end {quote}

	you must modify the sympa aliases like this :

\begin {quote}
listmaster-test: 	"| /home/sympa/bin/queue listmaster@\samplerobot"
\end {quote}

 	See \ref {robot-aliases},page~\pageref {robot-aliases} for all aliases.

\subsection {\cfkeyword {wwsympa\_url}}  

	 \default {http://\texttt{<}host\texttt{>}/wws}

	This is the root URL of \WWSympa.

        \example {wwsympa\_url https://my.server/sympa}


\subsection {\cfkeyword {soap\_url}}  

	This is the root URL of Sympa's SOAP server. Sympa's WSDL document refer to this URL in its \texttt {service} section.

        \example {soap\_url http://my.server/sympasoap}

\subsection {\cfkeyword {spam\_protection}}  

    \textindex{spam\_protection}
	 \default {javascript}

	There is a need to protection Sympa web site against spambot which collect
        email adresse in public web site. Various method are availble into Sympa
        and you can choose it with \cfkeyword {spam\_protection} and
        \cfkeyword {web\_archive\_spam\_protection} parameters.
        Possible value are :
\begin {itemize}
\item javascript : the adresse is hidden using a javascript. User who enable javascript can
see a  nice mailto adresses where others have nothing.
\item at : the @ char is replaced by the string " AT ".
\item none : no protection against spammer.
\end{itemize}


\subsection {\cfkeyword {web\_archive\_spam\_protection}}
	  \default {cookie}

	Idem \cfkeyword {spam\_protection} but restricted to web archive.
        A additional value is available : cookie which mean that users
        must submit a small form in order to receive a cookie before
        browsing archives. This block all robot, even google and co.


\subsection {\cfkeyword {color\_0}, \cfkeyword {color\_1} ..  \cfkeyword {color\_15}}
  \label {colors}
 They are the color definition for web interface.  These parameters can be overwritten in each virtual host definition. 
 The color are used in the CSS file and unfortunitly they are also in use in some web templates. The sympa admin interface 
 show every colors in use.
 
 
 \subsection {\cfkeyword {dark\_color} \cfkeyword {light\_color} \cfkeyword {text\_color} \cfkeyword {bg\_color} \cfkeyword {error\_color} \cfkeyword {selected\_color} \cfkeyword {shaded\_color}}
 
 
 	Deprecated. They are the color definition for previous web interface. These parameters are unused in 5.1 and higher 
 version but still available.style.css, print.css, print-preview.css and fullPage.css
 
\subsection {\cfkeyword {logo\_html\_definition}}
This parameter allow you to insert in the left top page corner oa piece of html code, usually to insert la logo in the page. This is a very basic but easy customization.
\example {logo\_html\_definition <a href="http://www.mycompagnie.com"><img style="float: left; margin-top: 7px; margin-left: 37px;" src="http:/logos/mylogo.jpg" alt="my compagnie" /></a>}

\subsection {\cfkeyword {css\_path}}
 
Pre-parsed CSS files (let's say static css files) can be installed using Sympa server skins module. These CSS files are 
installed in a part of the web server that can be reached without using sympa web engine. In order to do this edit the 
robot.conf file and set the css\_path parameter. Then retart the server and use skins module from the "admin sympa" page 
to install preparsed CSS file. The in order to replace dynamic CSS by these static files 
set the \cfkeyword {css\_url} parameter.

\textbf {After an upgrade, \file {sympa.pl} automatically updates the static CSS files with the new installed css.tt2. Therefore it's not a good place to store customized CSS files.}

\subsection {\cfkeyword {css\_url}}

By default, CSS files style.css, print.css, print-preview.css and fullPage.css are delivred by Sympa web interface itself using a sympa action 
named css. URL look like http://foo.org/sympa/css/style.css . CSS file are made parsing a web\_tt2 file named css.tt2. This allow dynamique 
definition of colors and in a near futur a complete definition of the skin, user preference skins etc.
  
In order to make sympa web interface faster, it is strongly recommended to install static css file somewhere in your web site. This way sympa will deliver 
only one page insteed of one page and four css page at each clic. This can be done using css\_url parameter. The parameter must contain the URL of the 
directory where  style.css, print.css, print-preview.css and fullPage.css are installed. You can make your own a sophisticated new skin editing these 
files. The server admin module include a CSS administration page that can help you to install static CSS.


\subsection {\cfkeyword {static\_content\_path}}

Some content may be delivred by http server (apache) without any need to be controled or parserd by Sympa. They are stored in directory choosen with parameter static\_content\_dir. Current Sympa version store in this directory subscribers pictures. Later update will add style sheet, icons, ... The directory is created by Sympa.pl when started. This parameter can be defined also in robot.conf

\subsection {\cfkeyword {static\_content\_url}}

Content stored in directory specified by parameter \cfkeyword {static\_content\_url} must be served by http server under the URL specified by {\cfkeyword {static\_content\_url}}. Check apache configuration in order to make this directory available. This parameter can be defined in robot.conf.

\subsection {\cfkeyword {pictures\_feature}}

 \default {off}
 \example {pictures\_feature       on}

Subscribers can upload their picture (from the subscriber option page) so reviewing subsribers shows a gallery. This parameter defines the default for corresponding list parameter but it does NOT allow to disable the feature globaly. If you want to disable the feature for your whole site, you need to customize the \file {edit-list.conf} file to disallow edition of the corresponding list parameter.

Pictures are stored in a directory specified by {\cfkeyword {static\_content\_path}} parameter.

\subsection {\cfkeyword {pictures\_max\_size}}

The maximum size of the uploaded picture file (bytes)

\subsection {\cfkeyword {cookie}} 
 
	This string is used to generate MD5 authentication keys.
	It allows generated authentication keys to differ from one
	site to another. It is also used for reversible encryption of
        user passwords stored in the database. The presence of this string
	is one reason why access to \file {sympa.conf} needs to be restricted
	to the Sympa user. 
       
        Note that changing this parameter will break all
        http cookies stored in users' browsers, as well as all user passwords
	and lists X509 private keys. To prevent a catastroph, sympa.pl refuse to start if the cookie parameter was changed.
        


        \example {cookie gh869jku5}


\subsection {\cfkeyword {create\_list}}  

	\label{create-list}

	 \default {public\_listmaster}

	\scenarized {create\_list}

	Defines who can create lists (or request list creations).
	Sympa will use the corresponding authorization scenario.

        \example {create\_list intranet}

\subsection {\cfkeyword {automatic\_list\_feature}}

 \default {off}
 \example {automatic\_list\_feature       on}

        If set to \texttt {on}, Sympa will enable automatic list creation through family instantiation
	(see \ref {automatic-list-creation}, page~\pageref {automatic-list-creation}.

\subsection {\cfkeyword {automatic\_list\_creation}}  

	\label{automatic-list-creation-param}

	 \default {none}

	\scenarized {automatic\_list\_creation}

	If \cfkeyword {automatic\_list\_feature} is activated, this parameter (corresponding to an authorization scenario) 
	defines who is allowed to use the automatic list creation feature.
	
\subsection {\cfkeyword {automatic\_list\_removal}}

 \default {}
 \example {automatic\_list\_feature       if\_empty}

        If set to \texttt {if\_empty}, then Sympa will remove automatically created mailing lists just after their creartion, if they contain no list
	membe (see \ref {automatic-list-creation}, page~\pageref {automatic-list-creation}.


\subsection {\cfkeyword {global\_remind}}  

	\label{global-remind}

	 \default {listmaster}

	\scenarized {global\_remind}

	Defines who can run a \texttt {REMIND *} command.


\section {Directories}
\subsection {\cfkeyword {home}}

	 \default {\dir {[EXPL_DIR]}}

        The directory whose subdirectories correspond to the different lists.

        \example {home          /home/sympa/expl}

\subsection {\cfkeyword {etc}}

	 \default {\dir {[ETCDIR]}}

        This is the local directory for configuration files (such as
	\file {edit\_list.conf}. It contains 5 subdirectories:
	\dir {scenari} for local authorization scenarios; \dir {mail\_tt2}
	for the site's local mail templates and default list templates; \dir {web\_tt2}
        for the site's local html templates; \dir {global\_task\_models} for local
	global task models; and \dir {list\_task\_models} for local list task models

        \example {etc          /home/sympa/etc}

\section {System related}

\subsection {\cfkeyword {syslog}} 

	\default {LOCAL1}

        Name of the sub-system (facility) for logging messages.

        \example {syslog          LOCAL2}

\subsection {\cfkeyword {log\_level}} 

	\default {0}

        This parameter sets the verbosity of Sympa processes (including) in log files.
	With level 0 only main operations are logged, in level 3 almost everything is
	logged.

        \example {log\_level          2}

\subsection {\cfkeyword {log\_socket\_type}} 
    \label {par-log-socket-type}

	\default {unix}

        \Sympa communicates with \unixcmd {syslogd}
        using either UDP or UNIX sockets.  Set \cfkeyword
        {log\_socket\_type} to \texttt {inet} to use UDP, or \texttt
        {unix} for UNIX sockets.

\subsection {\cfkeyword {pidfile}} 

	\default {\file {[PIDDIR]/sympa.pid}}

        The file where the \file {sympa.pl} daemon stores its
        process number. Warning: the \texttt {sympa} user must be
        able to write to this file, and to create it if it doesn't
        exist.

        \example {pidfile         /var/run/sympa.pid}

\subsection {\cfkeyword {pidfile\_creation}} 

	\default {\file {[PIDDIR]/sympa-creation.pid}}

        The file where the automatic list creation dedicated \file {sympa.pl} daemon stores its
        process number. Warning: the \texttt {sympa} user must be
        able to write to this file, and to create it if it doesn't
        exist.

        \example {pidfile\_creation         /var/run/sympa-creation.pid}

\subsection {\cfkeyword {umask}} 

	\default {027}

        Default mask for file creation (see \unixcmd {umask}(2)).
	Note that it will be interpreted as an octual value.

        \example {umask 007}

\section {Sending related}

\subsection {\cfkeyword {distribution\_mode}}

	\default {single} 
	Use this parameter to determine if your installation nrun only one sympa.pl daemon that process both messages
        to distribute and commands (single) or if sympa.pl will fork to run two separate processus one dedicated to message distribution
	and one dedicated to commands and message pre-processing (fork). The second choice make a better priority processing for message
        distribution and faster command response, but it require a bit more computer ressources.

	\example {distribution\_mode fork}

\subsection {\cfkeyword {maxsmtp}} 

	\default {20}

        Maximum number of SMTP delivery child processes spawned
        by  \Sympa. This is the main load control parameter.

        \example {maxsmtp           500}

\subsection {\cfkeyword {log\_smtp}} 

	\default {off}

	Set logging of each MTA call. Can be overwritten by -m sympa option.

        \example {log\_smtp           on}


\subsection {\cfkeyword {use\_blacklist}}

	\default {send,create\_list}
        \index{use\_blacklist}
        \label{useblacklist}
	Sympa provide a blacklist feature available for list editor and list owner. The \cfkeyword {use\_blacklist} parameter
        define which operation use the blacklist. Search in black list is mainly usefull for the  \cfkeyword {send} service
        (distribution of a message to the subscribers). You may use blacklist for more operation such as review,archive etc but
        be aware that thoses web services needs fast response and blacklist may require some ressources.

        If you don't want blacklist at all, define \cfkeyword {use\_blacklist none} so the user interface to manage blacklist
        will disappear from the web interface.


\subsection {\cfkeyword {max\_size}} 

	\default {5 Mb}

	Maximum size allowed for messages distributed by \Sympa.
	This may be customized per virtual host or per list by setting the \lparam {max\_size} 
	robot or list parameter.

        \example {max\_size           2097152}

\subsection {\cfkeyword {misaddressed\_commands}} 

	\default {reject}

	When a robot command is sent to a list, by default Sympa reject this message. This feature
        can be turned off setting this parameter to \cfkeyword {ignore}.

\subsection {\cfkeyword {misaddressed\_commands\_regexp}} 

	\default {(subscribe|unsubscribe|signoff)}

	This is the Perl regular expression applied on messages subject and body to detect 
	misaddressed commands, see \cfkeyword {misaddressed\_commands} parameter above.

\subsection {\cfkeyword {nrcpt}} 

	\default {25}

	\label {nrcpt}
        Maximum number of recipients per \unixcmd {sendmail} call.
        This grouping factor makes it possible for the (\unixcmd
        {sendmail}) MTA to optimize the number of SMTP sessions for
        message distribution. 	If needed, you can limit the number of receipient for a particular domain. 
        Check nrcpt\_by\_domain configuration file. (see 
	\ref {nrcptbydomain},  page~\pageref {nrcptbydomain})

\subsection {\cfkeyword {avg}} 

	\default {10}

        Maximum number of different internet domains within addresses per
        \unixcmd {sendmail} call.

\subsection {\cfkeyword {sendmail}} 

	\default {/usr/sbin/sendmail}

        Absolute path to SMTP message transfer agent binary. Sympa expects this binary to
	be sendmail compatible (\textindex {postfix}, \textindex {Qmail} and \textindex {Exim} binaries all
	provide sendmail compatibility).

        \example {sendmail        /usr/sbin/sendmail}

\subsection {\cfkeyword {sendmail\_args}} 

	\default {-oi -odi -oem}

        Arguments passed to SMTP message transfer agent

\subsection {\cfkeyword {sendmail\_aliases}} 

	\default {defined by makefile, sendmail\_aliases | none}

        Path of the alias file that contain all lists related aliases. It is recommended to create a specific alias file so Sympa never overright the standard alias file but only a dedicated file.You must refer to this aliases file in your \file {sendmail.mc} :

        Set this parameter to 'none' if you want to disable alias management in sympa (e.g. if you use \file {virtual\_transport} with Postfix).

\subsection {\cfkeyword {rfc2369\_header\_fields}} 

	\default {help,subscribe,unsubscribe,post,owner,archive}

	RFC2369 compliant header fields (List-xxx) to be added to 
	distributed messages. These header-fields should be implemented
	by MUA's, adding menus.

\subsection {\cfkeyword {remove\_headers}} 

        \default {Return-Receipt-To,Precedence,X-Sequence,Disposition-Notification-To}

        This is the list of headers that \Sympa should remove from
        outgoing messages. Use it, for example, to ensure some privacy
        for your users by discarding anonymous options.
        It is (for the moment) site-wide. It is applied before the
        \Sympa, {rfc2369\_header\_fields}, and {custom\_header} fields are
        added.

\example {remove\_headers      Resent-Date,Resent-From,Resent-To,Resent-Message-Id,Sender,Delivered-To,Return-Receipt-To,Precedence,X-Sequence,Disposition-Notification-To}

\subsection {\cfkeyword {anonymous\_headers\_fields}} 

        \default {Sender,X-Sender,Received,Message-id,From,X-Envelope-To,Resent-From,Reply-To,Organization,Disposition-Notification-To,X-Envelope-From,X-X-Sender}

	This parameter defines the list of SMTP header fields that should be
	removed when a mailing list is setup in anonymous mode (see 
	\ref {par-anonymous-sender},  page~\pageref {par-anonymous-sender}).

\subsection {\cfkeyword {list\_check\_smtp}} 

        \default {NONE}

	If this parameter is set with a SMTP server address, \Sympa will check if alias
	with the same name as the list you're gonna create already exists on the
	SMTP server. It is robot specific, i.e. you can specify a different SMTP
	server for every virtual host you are running. This is needed if you are
	running \Sympa on somehost.foo.org, but you handle all your mail on a
	separate mail relay.

\subsection {\cfkeyword {list\_check\_suffixes}} 

        \default {request,owner,unsubscribe}

	This paramater is a comma-separated list of admin suffixes you're using
	for \Sympa aliases, i.e. \samplelist-request, \samplelist-owner etc...
	This parameter is used with \cfkeyword {list\_check\_smtp} parameter.
	It is also used to check list names at list creation time.

\subsection {\cfkeyword {urlize\_min\_size}} 

        \default {10240}

        This parameter is related to the \texttt {URLIZE} subscriber reception mode ; it
	defines the minimum size (in bytes) for MIME attachments to be urlized.


\section {Quotas}
\label {quotas}

\subsection {\cfkeyword {default\_shared\_quota}}

	The default disk quota (the unit is Kbytes) for lists' document repository.
 
\subsection {\cfkeyword {default\_archive\_quota}}

	The default disk quota (the unit is Kbytes) for lists' web archives.

\section {Spool related}
\label {spool-related}
\subsection {\cfkeyword {spool}}

        \default {\dir {[SPOOLDIR]}}

	The parent directory which contains all the other spools.  
        

\subsection {\cfkeyword {queue}} 

        The absolute path of the directory which contains the queue, used both by the
        \file {queue} program and the \file {sympa.pl} daemon. This
        parameter is mandatory.

	\example {\dir {[SPOOLDIR]/msg}}

\subsection {\cfkeyword {queuedistribute}} 
	\index{spool}
	\index{distribution}
	
	\default {\dir {[SPOOLDIR]/distribute}}

        This parameter is optional and retained solely for backward compatibility.


\subsection {\cfkeyword {queuemod}}  
        \label {cf:queuemod}
        \index{moderation}

	\default {\dir {[SPOOLDIR]/moderation}}

        This parameter is optional and retained solely for backward compatibility.


\subsection {\cfkeyword {queuedigest}}  
        \index{digest}
        \index{spool}

        This parameter is optional and retained solely for backward compatibility.

\subsection {\cfkeyword {queueauth}} 

	\default {\dir {[SPOOLDIR]/auth}}

        This parameter is optional and retained solely for backward compatibility.

\subsection {\cfkeyword {queueoutgoing}} 

	\default {\dir {[SPOOLDIR]/outgoing}}

	This parameter is optional and retained solely for backward compatibility.

\subsection {\cfkeyword {queuetopic}} 

	\default {\dir {[SPOOLDIR]/topic}}

	This parameter is optional and retained solely for backward compatibility.

\subsection {\cfkeyword {queuebounce}} 
    \index{bounce}

	\default {\dir {[SPOOLDIR]/bounce}}

        Spool to store bounces (non-delivery reports) received by the \file {bouncequeue}
	program via the \samplelist-owner (unless this suffix was customized) or bounce+* addresses (VERP) . This parameter is mandatory
        and must be an absolute path.

\subsection {\cfkeyword {queuetask}} 
    \index{bounce}

	\default {\dir {[SPOOLDIR]/task}}

        Spool to store task files created by the task manager. This parameter is mandatory
        and must be an absolute path.

\subsection {\cfkeyword {queueautomatic}} 
    \label {kw-queueautomatic}

	\default {none}

        The absolute path of the directory which contains the queue for automatic list creation, used both by the
        \file {familyqueue} program and the \file {sympa.pl} daemon. This
        parameter is mandatory when enabling automatic\_list\_creation.

	\example {\dir {[SPOOLDIR]/msg}}

\subsection {\cfkeyword {tmpdir}}

        \default {\dir {[SPOOLDIR]/tmp}}

	Temporary directory used by OpenSSL and antiviruses.

\subsection {\cfkeyword {sleep}}  
        \label {kw-sleep}

	\default {5}

        Waiting period (in seconds) between each scan of the main queue.
        Never set this value to~0!

\subsection {\cfkeyword {clean\_delay\_queue}} 

	\default {1}

        Retention period (in days) for ``bad'' messages in
        \textindex {spool} (as specified by \cfkeyword {queue}).
        \Sympa keeps messages rejected for various reasons (badly
        formatted, looping, etc.) in
        this directory, with a name prefixed by \texttt {BAD}.
        This configuration variable controls the number of days
        these messages are kept.

        \example {clean\_delay\_queue 3}

\subsection {\cfkeyword {clean\_delay\_queuemod}} 

	\default {10}

        Expiration delay (in days) in the \textindex {moderation}
        \textindex {spool} (as specified by \cfkeyword {queuemod}).
        Beyond this deadline, messages that have not been processed
        are deleted.  For moderated lists, the contents of this spool
	can be consulted using a key along with the \mailcmd
        {MODINDEX} command.

\subsection {\cfkeyword {clean\_delay\_queueauth}}  

	\default {3}

        Expiration delay (in days) in the \textindex {authentication}
        queue.  Beyond this deadline, messages not enabled are
        deleted.

\subsection {\cfkeyword {clean\_delay\_queuesubscribe}}  

	\default {10}

        Expiration delay (in days) in the \textindex {subscription requests}
        queue.  Beyond this deadline, requests not validated are deleted.

\subsection {\cfkeyword {clean\_delay\_queuetopic}}  

	\default {7}

        Delay for keeping message topic files (in days) in the \textindex {topic}
        queue.  Beyond this deadline, files are
        deleted.

\subsection {\cfkeyword {clean\_delay\_queueautomatic}}  

	\default {10}

        Retention period (in days) for ``bad'' messages in
        \textindex {automatic spool} (as specified by \cfkeyword {queueautomatic}).
        \Sympa keeps messages rejected for various reasons (badly
        formatted, looping, etc.) in
        this directory, with a name prefixed by \texttt {BAD}.
        This configuration variable controls the number of days
        these messages are kept.

\section {Internationalization related}    

\subsection {\cfkeyword {localedir}}   

	\default{\dir {[LOCALEDIR]}}

        The location of multilingual catalog files. Must correspond to	\tildefile {src/locale/Makefile}.

\subsection {\cfkeyword {supported\_lang}}

\example {supported\_lang  fr,en\_US,de,es}

        This parameter lists all supported languages (comma separated) for the user interface. The default value will include
	all message catalogues but it can be narrowed by the listmaster.

\subsection {\cfkeyword {lang}}   

	\default {en\_US}

        This is the default language for \Sympa. The message catalog (.po, compiled as a .mo file) located 
	in the corresponding \cfkeyword {locale} directory will be used.

\subsection {\cfkeyword {web\_recode\_to}} (OBSOLETE)

    All web pages are now encoded in utf-8.
   
Note : if you recode web pages to utf-8, you should also add the following tag to your \file {mhonarc-ressources.tt2} file :
\begin {quote}
\begin{verbatim}
<TextEncode>
utf-8; MHonArc::UTF8::to_utf8; MHonArc/UTF8.pm
</TextEncode>
\end{verbatim}
\end {quote}

\subsection {\cfkeyword {filesystem\_encoding}}   
    \index{filesystem-encoding}

	\default {utf-8}

	\example {filesystem\_encoding  iso-8859-1}

        Sympa (and Perl) use utf-8 as the its internal encoding and
        also for the encoding of web pages. Because you might use a
        different character encoding on your filesystem, you need to
        declare it, so that Sympa is able to properly decode strings.


\section {Bounce related}

\subsection {\cfkeyword {verp\_rate}}
	 \label {kw-verp-rate}
	 \default {0\%}


        See \ref {verp},page~\pageref {verp} for more information on VERP in Sympa.

        When \cfkeyword {verp\_rate} is null VERP is not used ; if  \cfkeyword {verp\_rate} is 100\% VERP is alway in use.

	VERP requires plussed aliases to be supported and the bounce+* alias to be installed.

\subsection {\cfkeyword {welcome\_return\_path}}
        \label {kw-welcome-return-path}
         
        \default {owner}

	If  set to string \texttt {unique}, Sympa enable VERP for welcome message and bounce processing will
        remove the subscription if a bounce is received for the welcome message. This prevent to add bad address in subscriber list.

\subsection {\cfkeyword {remind\_return\_path}}
        \label {kw-remind-return-path}
         
        \default {owner}

        Like \cfkeyword {welcome\_return\_path}, but relates to the remind message.


\subsection {\cfkeyword {return\_path\_suffix}}
        \label {kw-return-path-suffix}
         
        \default {-owner}

	This defines the suffix that is appended to the list name to build the return-path
	of messages sent to the lists. This is the address that will receive all non delivery
	reports (also called bounces).

\subsection {\cfkeyword {expire\_bounce\_task}}
        \label {kw-expire-bounce-task}
         
        \default {daily}

	This parameter tells what task will be used by \file {task\_manager.pl}
	to perform bounces expiration. This task resets bouncing information for
	addresses not bouncing in the last 10 days after the latest message distribution.
	
\subsection {\cfkeyword {purge\_orphan\_bounces\_task}}
        \label {kw-purge-orphan-bounce-task}
         
        \default {Monthly}

	This parameter tells what task will be used by \file {task\_manager.pl}
	to perform bounces cleaning. This task delete bounces archives for 
	unsubscribed users.	


\subsection {\cfkeyword {eval\_bouncers\_task}}
        \label {kw-eval-bouncers-task}
         
        \default {daily}
	
	The task eval\_bouncers evaluate all bouncing users for all lists, and fill
	the field \cfkeyword {bounce\_score\_suscriber} in table \cfkeyword {suscriber\_table}
	with a score. This score allow the auto-management of bouncing-users.

\subsection {\cfkeyword {process\_bouncers\_task}}
        \label {kw-process-bouncers-task}
         
        \default {monthly}
	
	The task process\_bouncers execute configured actions on bouncing users, according to 
	their Score. The association between score and actions has to be done in List configuration,
	This parameter define the frequency of execution for this task.


\subsection {\cfkeyword {minimum\_bouncing\_count}}
        \label {kw-minimum-bouncing-count}
         
        \default {10}
	
	This parameter is for the bounce-score evaluation : the bounce-score is a note that
	allows the auto-management of bouncing users. This score is evaluated with,in particular, 
	the number of messages bounces received for the user. This parameter sets the minimum number 
	of these messages to allow the bounce-score evaluation for a user.

\subsection {\cfkeyword {minimum\_bouncing\_period}}
        \label {kw-minimum-bouncing-period}
         
        \default {10}
	
	Determine the minimum bouncing period for a user to allow his bounce-score evaluation.
	Like previous parameter, if this value is too low, bounce-score will be 0.

\subsection {\cfkeyword {bounce\_delay}}
        \label {kw-bounce-score-min-bouncing-period}
         
        \default {0} Days
	
	Another parameter for the bounce-score evaluation : This one represent the average time
	(days) for a bounce to come back to sympa-server after a post was send to a list.
	Usually bounces are arriving same day as the original message.


\subsection {\cfkeyword {default\_bounce\_level1\_rate}}
        \label {kw-default-bounce-level1-rate}
         
        \default {45}
	

	This is the default value for \lparam {bouncerslevel1} \lparam {rate} entry
	(\ref{bouncers-level1}, page~\pageref{bouncers-level1})


\subsection {\cfkeyword {default\_bounce\_level2\_rate}}
        \label {kw-default-bounce-level1-rate}
         
        \default {75}
	
	This is the default value for \lparam {bouncerslevel2} \lparam {rate} entry
	(\ref{bouncers-level2}, page~\pageref{bouncers-level2})

	
\subsection {\cfkeyword {bounce\_email\_prefix}} 

	\default {bounce}

        The prefix string used to build variable envelope return path (VERP). In the context
        of VERP enabled, the local part of the address start with a constant string specified by this parameter. The email is used to collect bounce.
	Plussed aliases are used in order to introduce the variable part of the email that encode the subscriber address. 
	This parameter is useful if you want to run more than one sympa on the
	same host (a sympa test for example).

	If you change the default value, you must modify the sympa aliases too.

	For example, if you set it as :

\begin {quote}
bounce\_email\_prefix bounce-test
\end {quote}

	you must modify the sympa aliases like this :

\begin {quote}
bounce-test+*: 	"| /home/sympa/bin/queuebounce sympa@\samplerobot"
\end {quote}

 	See \ref {robot-aliases},page~\pageref {robot-aliases} for all aliases.


\subsection {\cfkeyword {bounce\_warn\_rate}}
        \label {kw-bounce-warn-rate}
         
        \default {30}

	Site default value for \lparam {bounce}.
	The list owner receives a warning whenever a message is distributed and
	the number of bounces exceeds this value.

\subsection {\cfkeyword {bounce\_halt\_rate}}
        \label {kw-bounce-halt-rate}
         
        \default {50}

	\texttt {FOR FUTURE USE}

	Site default value for \lparam {bounce}.
	Messages will cease to be distributed if the number of bounces exceeds this value.


\subsection {\cfkeyword {default\_remind\_task}}
        \label {kw-default-remind-task}
         
        \default {2month}
	
	This parameter defines the default \lparam {remind\_task} list parameter.


\section {Tuning}

\subsection {\cfkeyword {cache\_list\_config}}
\label{cache-list}
	\texttt {Format: none | binary\_file}
	\default {none}

If this parameter is set to binary\_file, then Sympa processes will maintain a binary version of the
list config structure on disk (\file {config.bin} file). This file is bypassed whenever the \file {config}
file changes on disk. Thanks to this method, the startup of Sympa processes is much faster because it 
saves the time for parse all config files. The drawback of this method is that the list config cache could 
live for a long time (not recreated when Sympa process restart) ; Sympa processes could still use authorization 
scenario rules that have changed on disk in the meanwhile.

You should use list config cache if you are managing a big amount of lists (1000+).

\subsection {\cfkeyword {sympa\_priority}}  
        \label {kw-sympa-priority}

	\default {1}

        Priority applied to \Sympa commands while running the spool.

        Available since release 2.3.1.

\subsection {\cfkeyword {request\_priority}}  
        \label {kw-request-priority}

	\default {0}

        Priority for processing of messages for \samplelist-request,
	i.e. for owners of the list.

        Available since release 2.3.3

\subsection {\cfkeyword {owner\_priority}}  
        \label {kw-owner-priority}

	\default {9}

        Priority for processing messages for \samplelist-owner in
	the spool. This address will receive non-delivery reports
	(bounces) and should have a low priority.

        Available since release 2.3.3


\subsection {\cfkeyword {default\_list\_priority}}  
        \label {kw-default-list-priority}

	\default {5}

        Default priority for messages if not defined in the list
        configuration file.

        Available since release 2.3.1.

\section {Database related}
	\label {database-related}

The following parameters are needed when using an RDBMS, but are otherwise not required:

\subsection {\cfkeyword {update\_db\_field\_types}}

	\texttt {Format: update\_db\_field\_types auto | disabled}

	\default {auto}

This parameter defines if Sympa may automatically update database structure to match the expected datafield types.
This feature is only available with \textindex{mysql}.


\subsection {\cfkeyword {db\_type}}

	\texttt {Format: db\_type mysql | SQLite | Pg | Oracle | Sybase}

        Database management system used (e.g. MySQL, Pg, Oracle)
	
	This corresponds to the PERL DataBase Driver (DBD) name and
	is therefore case-sensitive.

\subsection {\cfkeyword {db\_name}} 

	\default {sympa}

        Name of the database containing user information. See
        detailed notes on database structure, \ref{rdbms-struct},
        page~\pageref{rdbms-struct}. If you are using SQLite, then this
	parameter is the DB file name.

\subsection {\cfkeyword {db\_host}}

        Database host name.

\subsection {\cfkeyword {db\_port}}

        Database port.

\subsection {\cfkeyword {db\_user}}

        User with read access to the database.

\subsection {\cfkeyword {db\_passwd}}

        Password for \cfkeyword {db\_user}.

\subsection {\cfkeyword {db\_timeout}}

        This parameter is used for SQLite only.

\subsection {\cfkeyword {db\_options}}

	If these options are defined, they will be appended to the
	database connect string.

Example for MySQL:
\begin {quote}
\begin{verbatim}
db_options	mysql_read_default_file=/home/joe/my.cnf;mysql_socket=tmp/mysql.sock-test
\end{verbatim}
\end {quote}
   
Check the related DBD documentation to learn about the available options.

\subsection {\cfkeyword {db\_env}}

	Gives a list of environment variables to set before database connexion.
	This is a ';' separated list of variable assignments.

Example for Oracle:
\begin {quote}
\begin{verbatim}
db_env	ORACLE_TERM=vt100;ORACLE_HOME=/var/hote/oracle/7.3.4
\end{verbatim}
\end {quote}


\subsection {\cfkeyword {db\_additional\_subscriber\_fields}}
\label{db-additional-subscriber-fields}

[STOPPARSE]
	If your \textbf {subscriber\_table} database table has more fields
	than required by \Sympa (because other programs access this
	table), you can make \Sympa recognize these fields. You will then be able to
	use them from within mail/web templates and authorization scenarios (as [subscriber-\texttt{>}field]).
	These fields will also appear in the list members review page and will be editable by the list owner.
[STARTPARSE]
	This parameter is a comma-separated list.

Example :
\begin {quote}
\begin{verbatim}
db_additional_subscriber_fields 	billing_delay,subscription_expiration
\end{verbatim}
\end {quote}
 
\subsection {\cfkeyword {db\_additional\_user\_fields}}

\label{db-additional-user-fields}

[STOPPARSE]
	If your \textbf {user\_table} database table has more fields
	than required by \Sympa (because other programs access this
	table), you can make \Sympa recognize these fields. You will then be able to
	use them from within mail/web templates (as [user-\texttt{>}field]).
[STARTPARSE]

	This parameter is a comma-separated list.

Example :
\begin {quote}
\begin{verbatim}
db_additional_user_fields 	address,gender
\end{verbatim}
\end {quote}


\subsection {\cfkeyword {purge\_user\_table\_task}}

\label{purge-user-table-task}

This parameter refers to the name of the task (\example {monthly}) that will be regularly run
by the \file {task\_manager.pl} to remove entries in the \textindex {user\_table} table that
have no corresponding entries in the \textindex {subscriber\_table} table.

\section {Loop prevention}

   The following define your loop prevention policy for commands.
(see~\ref {loop-detection}, page~\pageref {loop-detection})

\subsection {\cfkeyword {loop\_command\_max}}

	\default {200}

	The maximum number of command reports sent to an e-mail
	address. When it is reached, messages are stored with the BAD
	prefix, and reports are no longer sent.

\subsection {\cfkeyword {loop\_command\_sampling\_delay}} 

	\default {3600}

	This parameter defines the delay in seconds before decrementing
	the counter of reports sent to an e-mail address.

\subsection {\cfkeyword {loop\_command\_decrease\_factor}} 

	\default {0.5}

	The decrementation factor (\texttt {from 0 to 1}), used to
	determine the new report counter after expiration of the delay.

\subsection {\cfkeyword {loop\_prevention\_regex}} 

	\default {mailer-daemon|sympa|listserv|majordomo|smartlist|mailman}

	
	This regular expression is applied to messages sender address. If the sender address matches the regular expression, then
	the message is rejected. The goal of this parameter is to prevent loops between Sympa and other robots.

\section {S/MIME configuration}

\Sympa can optionally verify and use S/MIME signatures for security purposes.
In this case, the three first following parameters must be set by the listmaster
(see \ref {smimeconf},  page~\pageref {smimeconf}). The two others are optionnal.

\subsection {\cfkeyword {openssl}}

The path for the openSSL binary file.
         
\subsection {\cfkeyword {capath}} 
The directory path use by openssl for trusted CA certificates.

A directory of trusted certificates. The certificates should
have names of the form: hash.0 or have symbolic links to
them of this form ("hash" is the hashed certificate subject
name: see the -hash option of the openssl x509 utility). This
directory should be the same as the  directory
SSLCACertificatePath specified for mod\_ssl module for Apache.

\subsection {\cfkeyword {cafile}} 
This parameter sets the all-in-one file where you can assemble
the Certificates of Certification Authorities (CA) whose clients
you deal with. These are used for Client Authentication. Such a
file is simply the concatenation of the various PEM-encoded
Certificate files, in order of preference. This can be used
alternatively and/or additionally to \cfkeyword {capath}. 
	
\subsection {\cfkeyword {key\_passwd}} 

The password for list private key encryption. If not
	defined, \Sympa assumes that list private keys are not encrypted.

\label {certificate-task-config}
\subsection {\cfkeyword {chk\_cert\_expiration\_task}}

States the model version used to create the task which regularly checks the certificate
expiration dates and warns users whose certificate have expired or are going to.
To know more about tasks, see \ref {tasks}, page~\pageref {tasks}.

\subsection {\cfkeyword {crl\_update\_task}}

Specifies the model version used to create the task which regurlaly updates the certificate
revocation lists. 

\section {Antivirus plug-in}
\label {Antivirus plug-in}

\Sympa can optionally check incoming messages before delivering them, using an external antivirus solution.
You must then set two parameters.

\subsection {\cfkeyword {antivirus\_path}}

The path to your favorite antivirus binary file (including the binary file).

Example :
\begin {quote}
\begin{verbatim}
antivirus_path		/usr/local/bin/uvscan
\end{verbatim}
\end {quote}
   
\subsection {\cfkeyword {antivirus\_args}} 

The arguments used by the antivirus software to look for viruses.
You must set them so as to get the virus name.
You should use, if available, the 'unzip' option and check all extensions.

Example with uvscan :
\begin {quote}
\begin{verbatim}
antivirus_args		--summary --secure
\end{verbatim}
\end {quote}

Example with fsav :
\begin {quote}
\begin{verbatim}
antivirus_args		--dumb	--archive
\end{verbatim}
\end {quote}

Exemple with AVP :
\begin {quote}
\begin{verbatim}
antivirus_path  /opt/AVP/kavscanner
antivirus_args  -Y -O- -MP -I0
\end{verbatim}
\end {quote}

Exemple with Sophos :
\begin {quote}
\begin{verbatim}
antivirus_path  /usr/local/bin/sweep
antivirus_args  -nc -nb -ss -archive
\end{verbatim}
\end {quote}

Exemple with Clam :
\begin {quote}
\begin{verbatim}
antivirus_path  /usr/local/bin/clamscan
antivirus_args  --stdout
\end{verbatim}
\end {quote}
      	
\subsection {\cfkeyword {antivirus\_notify}} \texttt {sender} | \texttt {nobody}

	\default {sender}

This parameter tells if \Sympa should notify the email sender when a virus has been
detected.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Sympa and its RDBMS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\cleardoublepage
\chapter {\Sympa and its database}
\label {sec-rdbms}

Most basic feature of \Sympa will work without a RDBMS, but WWSympa and bounced require a relational database. 
Currently you can use one of the following RDBMS : MySQL, SQLite, PostgreSQL, Oracle, Sybase. Interfacing with other RDBMS
requires only a few changes in the code, since the API used, \htmladdnormallinkfoot {DBI} {http://www.symbolstone.org/technology/perl/DBI/} 
(DataBase Interface), has DBD (DataBase Drivers) for many RDBMS.

Sympa stores three kind of information in the database, each in one table :
\begin {itemize}

  \item User preferences and passwords are stored in the \textindex {user\_table} table

  \item List subscription informations are stored in the \textindex {subscriber\_table} table, along with subscription options.
  This table also contains the cache for included users (if using include2 mode).

  \item List administrative informations are stored in the \textindex {admin\_table} table if using include2 mode, along with owner and editor options. This table also contains the cache for included owners and editors.

\end {itemize}

\section {Prerequisites}

You need to have a DataBase System installed (not necessarily 
on the same host as \Sympa), and the client libraries for that
Database installed on the \Sympa host ; provided, of course, that
a PERL DBD (DataBase Driver) is available for your chosen RDBMS!
Check the \htmladdnormallinkfoot
{\perlmodule {DBI} Module Availability} {http://www.symbolstone.org/technology/perl/DBI/}.

\section {Installing PERL modules}

\Sympa will use \perlmodule {DBI} to communicate with the database system and
therefore requires the DBD for your database system. DBI and 
DBD::YourDB (\perlmodule {Msql-Mysql-modules} for MySQL) are distributed as 
CPAN modules. Refer to ~\ref {Install PERL and CPAN modules}, 
page~\pageref {Install PERL and CPAN modules} for installation
details of these modules.

\section {Creating a sympa DataBase}

\subsection {Database structure}

The sympa database structure is slightly different from the
structure of a \file {subscribers} file. A \file {subscribers}
file is a text file based on paragraphs (similar to 
the \file {config} file) ; each paragraph completely describes 
a subscriber. If somebody is subscribed to two lists, he/she 
will appear in both subscribers files.

The DataBase distinguishes information relative to a person (e-mail,
real name, password) and his/her subscription options (list
concerned, date of subscription, reception option, visibility 
option). This results in a separation of the data into two tables :
the user\_table and the subscriber\_table, linked by a user/subscriber e-mail.

The table concerning owners and editors, the admin\_table, is made on the same way as 
the subscriber\_table but is used only in include2 mode. It constains owner and editor 
options (list concerned, administrative role, date of ``subscription'', reception option, 
private info, gecos and profile option for owners).

\subsection {Database creation}

The \file {create\_db} script below will create the sympa database for 
you. You can find it in the \dir {script/} directory of the 
distribution (currently scripts are available for MySQL, SQLite, PostgreSQL, Oracle and Sybase).

\begin{itemize}

  \item MySQL database creation script\\
	\begin {quote}
	\begin{verbatim}
	[INCLUDE '../src/etc/script/create_db.mysql']
	\end{verbatim}
	\end {quote}

  \item SQLiteL database creation script\\
	\begin {quote}
	\begin{verbatim}
	[INCLUDE '../src/etc/script/create_db.SQLite']
	\end{verbatim}
	\end {quote}

  \item PostgreSQL database creation script\\
	\begin {quote}
	\begin{verbatim}
	[INCLUDE '../src/etc/script/create_db.Pg']
	\end{verbatim}
	\end {quote}

  \item Sybase database creation script\\
	\begin {quote}
	\begin{verbatim}
	[INCLUDE '../src/etc/script/create_db.Sybase']
	\end{verbatim}
	\end {quote}

  \item Oracle database creation script\\
	\begin {quote}
	\begin{verbatim}
	[INCLUDE '../src/etc/script/create_db.Oracle']
	\end{verbatim}
	\end {quote}

\end{itemize}

You can execute the script using a simple SQL shell such as
mysql, psql or sqlplus.

Example:

\begin {quote}
\begin{verbatim}
# mysql  < create_db.mysql
\end{verbatim}  
\end {quote}

\section {Setting database privileges}

We strongly recommend you restrict access to \textit {sympa} database. You will
then set \cfkeyword {db\_user} and \cfkeyword {db\_passwd} in \file {sympa.conf}.

With \textindex{MySQL} :
\begin {quote}
\begin{verbatim}
grant all on sympa.* to sympa@localhost identified by 'your_password';
flush privileges;
\end{verbatim}
\end {quote}

\section {Importing subscribers data}

\subsection {Importing data from a text file}

You can import subscribers data into the database from a text file having one entry per line : the first field is 
an e-mail address, the second (optional) field is the free form name.  Fields are spaces-separated.

Example:
\begin {quote}
\begin{verbatim}
## Data to be imported
## email        gecos
john.steward@some.company.com           John - accountant
mary.blacksmith@another.company.com     Mary - secretary
\end{verbatim}  
\end {quote}

To import data into the database :

\begin {quote}
\begin{verbatim}
cat /tmp/my_import_file | sympa.pl --import=my_list
\end{verbatim}  
\end {quote}

(see \ref {sympa.pl}, page~\pageref {sympa.pl}).


\subsection {Importing data from subscribers files}

If a mailing list was previously setup to store subscribers into 
\file {subscribers} file (the default mode in versions older then 2.2b) 
you can load subscribers data into the sympa database. The easiest way
is to edit the list configuration using \WWSympa (this requires listmaster 
privileges) and change the data source from \textbf {file} to \textbf {database}
; subscribers data will be loaded into the database at the same time.
 
If the subscribers file is big, a timeout may occur during the FastCGI execution
(Note that you can set a longer timeout with the \option {-idle-timeout} option of
the \texttt {FastCgiServer} Apache configuration directive). In this case, or if you have not installed \WWSympa, you should use the \file {load\_subscribers.pl} script.


\section {Management of the include cache}
\label {include2-cache}

You may dynamically add a list of subscribers, editors or owners to a list with Sympa's \textbf {include2} user data source. Sympa is able to query
multiple data sources (RDBMS, LDAP directory, flat file, a local list, a remote list) to build a mailing list. 

Sympa used to manage the cache of such \textit {included} subscribers in a DB File (\textbf {include} mode) but now stores
subscribers, editors and owners in the database (\textbf {include2} mode). These changes brought the following advantages :
\begin {itemize}

    \item Sympa processes are smaller when dealing with big mailing lists (in include mode)

    \item Cache update is now performed regularly by a dedicated process, the task manager

    \item Mixed lists (included + subscribed users) can now be created

    \item Sympa can now provide reception options for \textit {included} members

    \item Bounces information can be managed for \textit {included} members

    \item Sympa keeps track of the data sources of a member (available on the web REVIEW page)

    \item \textit {included} members can also subscribe to the list. It allows them to remain in the list though they might no more be included.

\end {itemize}



\section {Extending database table format}

You can easily add other fields to the three tables, they will not disturb \Sympa because it lists
explicitely the field it expects in SELECT queries.

Moreover you can access these database fields from within \Sympa
(in templates), as far as you list these additional fields in
\file {sympa.conf} (See \ref {db-additional-subscriber-fields}, page~\pageref {db-additional-subscriber-fields}
and \ref {db-additional-user-fields}, page~\pageref {db-additional-user-fields}).


\section {\Sympa configuration}

To store subscriber information in your newly created
database, you first need to tell \Sympa what kind of
database to work with, then you must configure
your list to access the database.

You define the database source in \file {sympa.conf} :
\cfkeyword {db\_type}, \cfkeyword {db\_name}, 
\cfkeyword {db\_host}, \cfkeyword {db\_user}, 
\cfkeyword {db\_passwd}.

If you are interfacing \Sympa with an Oracle database, 
\cfkeyword {db\_name} is the SID.

All your lists are now configured to use the database,
unless you set list parameter \lparam {user\_data\_source} 
to \textbf {file} or \textbf {include}. 

\Sympa will now extract and store user
information for this list using the database instead of the
\file {subscribers} file. Note however that subscriber information is 
dumped to \file {subscribers.db.dump} at every shutdown, 
to allow a manual rescue restart (by renaming subscribers.db.dump to
subscribers and changing the user\_data\_source parameter), if ever the
database were to become inaccessible.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% WWSympa
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\cleardoublepage
\chapter {WWSympa, Sympa's web interface}


WWSympa is \Sympa's web interface.

\section {Organization}
\label {WWSympa}

\WWSympa is fully integrated with \Sympa. It uses \file {sympa.conf}
and \Sympa's libraries. The default \Sympa installation will also
install WWSympa.

Every single piece of HTML in \WWSympa is generated by the CGI code
using template files (See \ref {tpl-format}, page~\pageref {tpl-format}).
This facilitates internationalization of pages, as well as per-site
customization. 

The code consists of one single PERL CGI script, \file {WWSympa.fcgi}.
To enhance performance you can configure \WWSympa to use
FastCGI ; the CGI will be persistent in memory.\\
All data will be accessed through the CGI, including web archives.
This is required to allow the authentication scheme to be applied
systematically.

Authentication is based on passwords stored in the database table
user\_table ; if the appropriate \file {Crypt::CipherSaber} is
installed, password are encrypted in the database using reversible
encryption based on RC4. Otherwise they are stored in clear text.
In both cases reminding of passwords is possible.
 To keep track of authentication information \WWSympa
uses HTTP cookies stored on the client side. The HTTP cookie only 
indicates that a specified e-mail address has been authenticated ;
permissions are evaluated when an action is requested.

The same web interface is used by the listmaster, list owners, subscribers and
others. Depending on permissions, the same URL may generate a different view.

\WWSympa's main loop algorithm is roughly the following : 
\begin {enumerate}
	\item Check authentication information returned by 
	the HTTP cookie

	\item Evaluate user's permissions for the
        requested action 

	\item Process the requested action 

	\item Set up variables resulting from the action 

	\item Parse the HTML template files
\end {enumerate}

\section {Web server setup}

\subsection {wwsympa.fcgi access permissions}
 
      
     Because Sympa and WWSympa share a lot of files, \file {wwsympa.fcgi},
     must run with the same 
     uid/gid as \file {archived.pl}, \file {bounced.pl} and \file {sympa.pl}.
     There are different ways to achieve this :
\begin{itemize}
\item SetuidPerl : this is the default method but might be insecure. If you don't set the \textbf {- -enable\_secure} configure option,
      \file {wwsympa.fcgi} is installed with the SetUID bit set. On most systems you will need to install the suidperl package.

\item Sudo : use \textbf {sudo} to run \file {wwsympa.fcgi} as user sympa. Your Apache configuration should use \file {wwsympa\_sudo\_wrapper.pl} instead 
       of \file {wwsympa.fcgi}. You should edit your \file {/etc/sudoers} file (with visudo command) as follows :
\begin {quote}
\begin{verbatim}
apache ALL = (sympa)  NOPASSWD: [CGIDIR]/wwsympa.fcgi
\end{verbatim}
\end {quote}

\item Dedicated Apache server : run a dedicated Apache server with sympa.sympa as uid.gid (The Apache default
      is apache.apache).

\item Apache suExec : use an Apache virtual host with sympa.sympa as uid.gid ; Apache
      needs to be compiled with suexec. Be aware that the Apache suexec usually define a lowest
      UID/GID allowed to be a target user for suEXEC. For most systems including binaries
      distribution of Apache, the default value 100 is common.
      So Sympa UID (and Sympa GID) must be higher then 100 or suexec must be tuned in order to allow
      lower UID/GID. Check http://httpd.apache.org/docs/suexec.html\#install for details

      The User and Group directive have to be set before the FastCgiServer directive
      is encountered.

\item C wrapper : otherwise, you can overcome restrictions on the execution of suid scripts
      by using a short C program, owned by sympa and with the suid bit set, to start
      \file {wwsympa.fcgi}. Here is an example (with no guarantee attached) :
\begin {quote}
\begin{verbatim}

#include <unistd.h>

#define WWSYMPA "[CGIDIR]/wwsympa.fcgi"
[STOPPARSE]

int main(int argn, char **argv, char **envp) {
    argv[0] = WWSYMPA;
    execve(WWSYMPA,argv,envp);
}

[STARTPARSE]
\end{verbatim}
\end {quote}
\end{itemize}

\subsection {Installing wwsympa.fcgi in your Apache server}

     You first need to set an alias to the directory where Sympa stores static contents (CSS, members pictures, documentation) directly delivered by Apache


\begin {quote}
\begin{verbatim}
     Example :
       	Alias /static-sympa [DIR]/static_content
\end{verbatim}
\end {quote}

     If you chose to run \file {wwsympa.fcgi} as a simple CGI, you simply need to
     script alias it. 

\begin {quote}
\begin{verbatim}
     Example :
       	ScriptAlias /sympa [CGIDIR]/wwsympa.fcgi
\end{verbatim}
\end {quote}

     Running  FastCGI will provide much faster responses from your server and 
     reduce load (to understand why, read 
     \htmladdnormallink 
     {http://www.fastcgi.com/fcgi-devkit-2.1/doc/fcgi-perf.htm}
     {http://www.fastcgi.com/fcgi-devkit-2.1/doc/fcgi-perf.htm})
     
\begin {quote}
\begin{verbatim}
     Example :
	FastCgiServer [CGIDIR]/wwsympa.fcgi -processes 2
	<Location /sympa>
   	  SetHandler fastcgi-script
	</Location>

	ScriptAlias /sympa [CGIDIR]/wwsympa.fcgi

 \end{verbatim}
\end {quote}
 
If you are using \textbf {sudo} (see evious subsection), then replace \file {wwsympa.fcgi} calls with \file {wwsympa\_sudo\_wrapper.pl}.

If you run virtual hosts, then each FastCgiServer(s) can serve multiple hosts. 
Therefore you need to define it in the common section of your Apache configuration file.

\subsection {Using FastCGI}

\htmladdnormallink {FastCGI} {http://www.fastcgi.com/} is an extention to CGI that provides persistency for CGI programs. It is extemely useful
with \WWSympa since source code interpretation and all initialisation tasks are performed only once, at server startup ; then
file {wwsympa.fcgi} instances are waiting for clients requests. 

\WWSympa can also work without FastCGI, depending on the \textbf {use\_fast\_cgi} parameter 
(see \ref {use-fastcgi}, page~\pageref {use-fastcgi}).

To run \WWSympa with FastCGI, you need to install :
\begin{itemize}

\item \textindex {mod\_fastcgi} : the Apache module that provides \textindex {FastCGI} features

\item \perlmodule {FCGI} : the Perl module used by \WWSympa

\end{itemize}

\section {wwsympa.conf parameters}


	\subsection {arc\_path}

	\default {/home/httpd/html/arc} \\
	Where to store html archives. This parameter is used
        by the \file {archived.pl} daemon. It is a good idea to install the archive
        outside the web hierarchy to prevent possible back doors in the access control
        powered by WWSympa. However, if Apache is configured with a chroot, you may
	have to install the archive in the Apache directory tree.

	\subsection {archive\_default\_index thrd | mail}

	\default {thrd} \\
	The default index organization when entering web archives : either threaded or	
	chronological order.

	\subsection {archived\_pidfile}
	\default {archived.pid} \\
	The file containing the PID of \file {archived.pl}.

	\subsection {bounce\_path}
	\default {/var/bounce} \\
	Root directory for storing bounces (non-delivery reports). This parameter
	is used mainly by the \file {bounced.pl} daemon.

	\subsection {bounced\_pidfile}
	\default {bounced.pid} \\
	The file containing the PID of \file {bounced.pl}.

	\subsection {cookie\_expire}
	\default {0}
	Lifetime (in minutes) of HTTP cookies. This is the default value
	when not set explicitly by users.
	
	\subsection {cookie\_domain}
	\default {localhost} \\
	Domain for the HTTP cookies. If beginning with a dot ('.'),
	the cookie is available within the specified internet domain.
	Otherwise, for the specified host. Example : 
		\begin {quote}
		\begin{verbatim}
		   cookie_domain cru.fr
		   cookie is available for host 'cru.fr'

		   cookie_domain .cru.fr
		   cookie is available for any host within 'cru.fr' domain
		\end{verbatim}
		\end {quote}
	The only reason for replacing the default value would be where
	\WWSympa's authentication process is shared with an application
	running on another host.
	
	\subsection {default\_home}
	\default {home} \\
        Organization of the WWSympa home page. If you have only a few lists,
	the default value `home' (presenting a list of lists organized by topic)
	should be replaced by `lists' (a simple alphabetical list of lists).

	\subsection {icons\_url}
	\default {/icons} \\
	URL of WWSympa's icons directory.

      	\subsection {log\_facility}

	WWSympa will log using this facility. Defaults to \Sympa's syslog
        facility.
	Configure your syslog according to this parameter.

	\subsection {mhonarc}
	\default {/usr/bin/mhonarc} \\
	Path to the (superb) MhOnArc program. Required for html archives
	http://www.oac.uci.edu/indiv/ehood/mhonarc.html

	\subsection {htmlarea\_url}
	\default {undefined} \\
	Relative URL to the (superb) online html editor HTMLarea. If you have installed javascript application you can use it
        when editing html document in the shared document repository. In order to activate this pluggin the value of this
        parameter should point to the root directory where HTMLarea is installed.  HTMLarea is a free opensource software you can download
        here : http://sf.net/projects/itools-htmlarea/

	\subsection {password\_case sensitive | insensitive}
	\default {insensitive} \\
	If set to \textbf {insensitive}, WWSympa's password check will be insensitive.
	This only concerns passwords stored in Sympa database, not the ones in \textindex {LDAP}.
	
	\textbf {Be careful :} in previous 3.xx versions of Sympa, passwords were 
	lowercased before database insertion. Therefore changing to case-sensitive 
	password checking could bring you some password checking problems.

	\subsection {title}
	\default {Mailing List Service} \\
	The name of your mailing list service. It will appear in
	the Title section of WWSympa.

	\subsection {use\_fast\_cgi   0 | 1}
	\label{use-fastcgi}
	\default {1} \\
	Choice of whether or not to use FastCGI. On listes.cru.fr, using FastCGI 
        increases WWSympa performance by as much as a factor of 10. Refer to 
       	\htmladdnormallink {http://www.fastcgi.com/} {http://www.fastcgi.com/}
	and the Apache config section of this document for details about 
	FastCGI.


\section {MhOnArc}
 
MhOnArc is a neat little converter from mime messages to html. Refer to
\htmladdnormallink {http://www.oac.uci.edu/indiv/ehood/mhonarc.html}
{http://www.oac.uci.edu/indiv/ehood/mhonarc.html}.

The long mhonarc resource file is used by \WWSympa in a particular way.
MhOnArc is called to produce not a complete html document, but only a part of it
to be included in a complete document (starting with \texttt{<}HTML\texttt{>} and terminating
with \texttt{<}/HTML\texttt{>} ;-) ).
The best way is to use the MhOnArc resource file 
provided in the \WWSympa distribution and to modify it for your needs.

The mhonarc resource file is named \file {mhonarc-ressources}. 
You may locate this file either in \begin{enumerate}
 	\item \dir {[EXPL_DIR]/\samplelist/mhonarc-ressources}
	in order to create a specific archive look for a particular list

	\item or \dir {[ETCDIR]/mhonarc-ressources}

\end{enumerate}

\section {Archiving daemon}
\file {archived.pl} converts messages from \Sympa's spools 
and calls \file {mhonarc} to create html versions (whose location is defined by the 
"arc\_path" WWSympa parameter). You should probably install these archives 
outside the \Sympa home\_dir (\Sympa's initial choice for storing mail archives : 
\dir {[EXPL_DIR]/\samplelist}). Note that the html archive 
contains a text version of each message and is totally separate from \Sympa's
main archive.
\begin{enumerate}

\item create a directory according to the WWSympa "arc\_path" parameter
    (must be owned by sympa, does not have to be in Apache space unless
    your server uses chroot)

\item for each list, if you need a web archive, create a new web archive paragraph
    in the list configuration. Example :
\begin {quote}
\begin{verbatim}
     web_archive
     access public|private|owner|listmaster|closed
     quota 10000
\end{verbatim}
\end {quote}

     If web\_archive is defined for a list, every message distributed by this list is copied
     to \dir {[SPOOLDIR]/outgoing/}. (No need to create nonexistent subscribers to receive
     copies of messages). In this example disk quota (expressed in Kbytes) for the archive is limited to 10 Mo.

\item start \file {archived.pl}.
\Sympa and Apache
 
\item check \WWSympa logs, or alternatively, start \file {archived.pl} in debug mode (-d). 

\item If you change mhonarc resources and wish to rebuild the entire archive 
using the new look defined for mhonarc, simply create an empty file named
".rebuild.\samplelist@myhost" in \dir {[SPOOLDIR]/outgoing}, and make sure that
the owner of this file is \Sympa. 

\begin {quote}
\begin{verbatim}
     example : su sympa -c "touch [SPOOLDIR]/outgoing/.rebuild.sympa-fr@cru.fr"
\end{verbatim}
\end {quote}
You can also rebuild web archives from within the admin page of the list.

Furthermore, if you want to get list's archives, you can do it via the \cfkeyword{ List-admin menu-> Archive Management}
\end{enumerate}
 

\section {Database configuration}

\WWSympa needs an RDBMS (Relational Database Management System) in order to
run. All database access is performed via the \Sympa API. \Sympa
currently interfaces with \htmladdnormallink {MySQL}{http://www.mysql.net/}, 
\htmladdnormallink {SQLite}{http://sqlite.org/},
\htmladdnormallink {PostgreSQL}{http://www.postgresql.pyrenet.fr/}, 
\htmladdnormallink {Oracle}{http://www.oracle.com/database/} 
and \htmladdnormallink {Sybase}{http://www.sybase.com/index_sybase.html}.

A database is needed to store user passwords and preferences.
The database structure is documented in the \Sympa documentation ;
scripts for creating it are also provided with the \Sympa distribution
(in \dir {script}). 

User information (password and preferences) are stored in the «User» table.
User passwords stored in the database are encrypted using reversible
RC4 encryption controlled with the \cfkeyword {cookie} parameter,
since \WWSympa might need to remind users of their passwords. 
The security of \WWSympa rests on the security of your database. 


\section {Logging in as listmaster}

Once \Sympa is running you should log in on the web interface as a privileged user (listmaster)
to explore the admin interface, create mailing lists.

Multiple email addresses can be declared as listmaster via the \file {sympa.conf} (or \file {robot.conf})
\cfkeyword {listmaster} configuration parameter (see \ref {exp-admin},  page~\pageref {exp-admin}). Note
that listmasters on the main robot (declared in  \file {sympa.conf}) also have listmaster privileges on
the virtual hosts but they will not receive the various mail notifications (list creation, warnings,...)
regarding these virtual hosts.

The listmasters should log in with their canonical email address as an identifier (not \textit {listmaster@my.host}).
The associated password is not declared in sympa.conf ; it will be allocated by \Sympa when first hitting
the \textbf {Send me a password} button on the web interface. As for any user, the password can then be modified via the 
\textbf {Preferenced} menu.

Note that you must start the \file {sympa.pl} process with the web interface ; it is in responsible for delivering 
mail messages including password reminders.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Sympa Internationalization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\cleardoublepage
\chapter {Sympa Internationalization}
\label{i18n}
\index{i18n}

\section {Catalogs and templates}

Sympa is designed to allow easy internationalization of its user interface (service mail messages and web interface). 
All translations for one language are gathered in a single PO file that can be manipulated by standard 
\htmladdnormallinkfoot {GNU gettext tools} {http://www.gnu.org/software/gettext/\#TOCintroduction}.

Documentation and ressources about software translations : \htmladdnormallinkfoot {http://translate.sourceforge.net/doc/} {http://translate.sourceforge.net/doc/} 

Sympa previously (until Sympa 4.1.x) used XPG4 messages catalogue format. Web and mail templates were language specific. 
The new organization both provide a unique file to work on for translators and a standard format supported by many software.
Sympa templates refer to translatable strings using the \texttt {loc} TT2 filter.

Examples :
\begin {quote}
\begin{verbatim}
[%|loc%]User Email[%END%]

[%|loc(list.name,user.email)%]You have subscribed to list %1 with email address %2[%END%]
\end{verbatim}
\end {quote}

Sympa had previously been translated into 15 languages more or less completely. We have automatically extracted the 
translatable strings from previous templates but this process is awkward and is only seen as a bootstrap for translators. 
Therefore Sympa distribution will not include previous translations until a skilled translator has reviewed and updated 
the corresponding PO file. 

\section {Translating Sympa GUI in your language}

Instructions for translating Sympa are maintained on Sympa web site :
\htmladdnormallink {http://www.sympa.org/howtotranslate.html} {http://www.sympa.org/howtotranslate.html}

\section {Defining language-specific templates}

The default Sympa templates are language independant, refering to catalogue entries for translations. 
When customizing either web or mail templates, you can define different templates for different languages. 
The template should be located in a ll\_CC subdirectory of \dir {web\_tt2} or \dir {mail\_tt2} with the language code.

Example :
\begin {quote}
\begin{verbatim}
[ETC_DIR]/web_tt2/home.tt2
[ETC_DIR]/web_tt2/de_DE/home.tt2
[ETC_DIR]/web_tt2/fr_FR/home.tt2
\end{verbatim}
\end {quote}

This mecanism also applies to \file {comment.tt2} files used by create list templates.


Web templates can also make use of the \texttt {locale} variable to make templates multi-lingual :

Example :
\begin {quote}
\begin{verbatim}
[% IF locale == 'fr_FR' %]
Personnalisation
[% ELSE %]
Customization
[% END %]
\end{verbatim}
\end {quote}

\section {Translating topics titles}

Topics are defined in a \file {topics.conf} file. In this file, each entry can be given a title in different languages, see
\ref{topics}, page~\pageref{topics}.


\section {Handling of encodings}

Until version 5.3, Sympa web pages were encoded in each language's
encoding (iso-8859-1 for French, utf-8 for Japanese,...) whereas every
web page is now encoded in utf-8. Thanks to
the \perlmodule {Encode} Perl module, Sympa can now juggle with the
filesystem encoding, each message catalog's encoding and its web
encoding (utf-8).

If your operating system uses a character encoding different from
utf-8, then you should declare it using the \cfkeyword
{filesystem\_encoding} sympa.conf parameter (see 
\ref {filesystem-encoding}, page~\pageref {filesystem-encoding}). It is required to do so
because Sympa has no way to find out what encoding is used for its
configuration files. Once this encoding is known, every template or
configuration parameter can be read properly for the web and also
saved properly when edited from the web interface.

Note that the shared documents (see\ref {shared}, page~\pageref {shared}) filenames are 
Q-encoded to make their storage encoding neutral. This encoding is transparent 
for the end-users.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Sympa RSS Channel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\cleardoublepage
\chapter {Sympa RSS channel}
\label{rss}
\index{rss}

This service is provided by \WWSympa (\Sympa's web interface). 
Here is the root of \WWSympa's rss channel :\\

      \default {http://\texttt{<}host\texttt{>}/wws/rss}\\
      \example {https://my.server/wws/rss}

The access control of RSS queries proceed on the same way as \WWSympa actions referred to.
\Sympa provides the following RSS features :
\begin{itemize}
   \item the latest created lists on a robot (\file{latest\_lists}) ;
   \item the most active lists on a robot(\file{active\_lists}) ;  
   \item the latest messages of a list (\file{active\_arc}) ;   
   \item the latest shared documents of a list (\file{latest\_d\_read}) ; 
\end{itemize}


\section {\file{latest\_lists}}

This provides the latest created lists.  

      \example {http://my.server/wws/rss/latest\_lists?for=3\&count=6}\\
      This provides the 6 latest created lists for the last 3 days.\\

      \example {http://my.server/wws/rss/latest\_lists/computing?count=6}\\ 
      This provides the 6 latest created lists with topic ``computing''.\\

Parameters : 
\begin{itemize}
  \item \file{for} : period of interest (expressed in days). This is a CGI parameter. It is optional but one of the two parameters 
     ``for'' or ``count'' is required.
  \item \file{count} : maximum number of expected records. This is a CGI parameter. It is optional but one of the two parameters 
     ``for'' or ``count'' is required.
  \item topic : the topic is indicated in the path info (see example below with topic computing). 
    This parameter is optional.
\end{itemize}

\section {\file{active\_lists}}

This provides the most active lists, based on the number of distributed messages (number of received messages).  

      \example {http://my.server/wws/rss/active\_lists?for=3\&count=6}\\
      This provides the 6 most active lists for the last 3 days.\\

      \example {http://my.server/wws/rss/active\_lists/computing?count=6}\\ 
      This provides the 6 most active lists with topic ``computing''.\\

Parameters : 
\begin{itemize}
   \item \file{for} : period of interest (expressed in days). This is a CGI parameter. It is optional but one of the two parameters 
     ``for'' or ``count'' is required.
  \item \file{count} : maximum number of expected records. This is a CGI parameter. It is optional but one of the two parameters 
     ``for'' or ``count'' is required.
 \item topic : the topic is indicated in the path info (see example below with topic computing). 
    This parameter is optional.
\end{itemize}

\section {\file{latest\_arc}}

This provides the latest messages of a list.  

      \example {http://my.server/wws/rss/latest\_arc/\samplelist?for=3\&count=6}\\
      This provides the 6 latest messages received on the \samplelist  list for the last 3 days.\\

Parameters : 
\begin{itemize}
   \item list : the list is indicated in the path info. This parameter is mandatory.
   \item \file{for} : period of interest (expressed in days). This is a CGI parameter. It is optional but one of the two parameters 
     ``for'' or ``count'' is required.
  \item \file{count} : maximum number of expected records. This is a CGI parameter. It is optional but one of the two parameters 
     ``for'' or ``count'' is required.
\end{itemize}

\section {\file{latest\_d\_read}}

This provides the latest updated and uploaded shared documents of a list.  

      \example {http://my.server/wws/rss/latest\_d\_read/\samplelist?for=3\&count=6}\\
      This provides the 6 latest documents uploaded or updated on the \samplelist  list for the last 3 days.\\

Parameters : 
\begin{itemize}
   \item list : the list is indicated in the path info. This parameter is mandatory.
   \item \file{for} : period of interest (expressed in days). This is a CGI parameter. It is optional but one of the two parameters 
     ``for'' or ``count'' is required.
  \item \file{count} : maximum number of expected records. This is a CGI parameter. It is optional but one of the two parameters 
     ``for'' or ``count'' is required.
\end{itemize}


 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Sympa SOAP Server
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\cleardoublepage
\chapter {Sympa SOAP server}
\label {soap}

\section {Introduction}

\htmladdnormallink {SOAP} {http://www.w3.org/2002/ws/} is one protocol (generally over HTTP) that 
can be used to provide \textbf {web services}. Sympa SOAP server allows to access a Sympa service 
from within another program, written in any programming language and on any computer. SOAP encapsulates 
procedure calls, input parameters and resulting data in an XML data structure. The Sympa SOAP server's
API is published in a \textbf {WSDL } document, retreived via Sympa's web interface.

The SOAP server provides a limited set of high level functions including \texttt{login}, \texttt{which},
\texttt{lists}, \texttt{subscribe}, \texttt{signoff} and list creation. Other functions might be implemented in the future. One
of the important implementation constraint is to provide services for proxy application with a correct authorization evaluation
processus where authentication may differ from classic web method. The following cases can be used to access to the service :
\begin{itemize}
   \item The client first ask for a login and later service request provide the \texttt{sympa-user} cookie.
   \item The client authenticate the end user providing the \texttt{sympa-user} http cookie. This can be used in order to share the an authenticated session betwing Sympa
and some other application running on the same server as wwsympa. The soap method used is \texttt{getUserEmailByCookieRequest}.
   \item The client provide user email and password and request a service in a single soap access using the \texttt{authenticateAndRun} soap service.
   \item The client is a trusted by Sympa as a proxy application and is authorized to set some variables that will be used by 
         Sympa during the authorization scenario evaluation. Trusted application have there own password and the variables they can set are listed in
         a configuration file name  \file {trusted\_applications.conf}. See \ref{trustedapplications} page~\pageref{trustedapplications}.
\end{itemize}

In any case scenario authorization is used with same rules as mail interface or usual web interface.
           


The SOAP server uses \htmladdnormallink {SOAP::Lite} {http://www.soaplite.com/} Perl library. The server 
is running as a daemon (thanks to FastCGI), receiving the client SOAP requests via a web server (Apache 
for example).

\section {Web server setup}

You \textbf {NEED TO} install FastCGI for the SOAP server to work properly because it will run as a daemon.

Here is a sample piece of your Apache \file {httpd.conf} with a SOAP server configured :
\begin {quote}
\begin{verbatim}
	FastCgiServer [CGIDIR]/sympa_soap_server.fcgi -processes 1
	ScriptAlias /sympasoap [CGIDIR]/sympa_soap_server.fcgi

	<Location /sympasoap>
   	  SetHandler fastcgi-script
	</Location>

\end{verbatim}
\end {quote}

\section {Sympa setup}

The only mandatory parameter you need to set in \file {sympa.conf}/\file {robot.conf} files is
the \cfkeyword {soap\_url} that defines the URL of the SOAP service corresponding
to the ScriptAlias you've previously setup in Apache config. 

This parameter is used to publish the SOAP service URL in the WSDL file (defining the API) but
also for the SOAP server to deduce what Virtual Host is concerned by the current SOAP request 
(a single SOAP server will serve all Sympa virtual hosts).

\section {trust remote application}
\label {trustedapplications}

The SOAP service \cfkeyword {authenticateRemoteAppAndRun} is used in order to allow some remote application such as a web portal to request Sympa service as a proxy for the end user. In such case, Sympa will not authenticate the end user itself but instead it will trust a particular application to act as a proxy. 

This configuration file \cfkeyword {trusted\_applications.conf} can be created in the robot \dir {etc/} subdirectory or in \dir {[ETCDIR]} directory depending on the scope you want for it (the source package include a sample of file \file {trusted\_applications.conf} in directory \dir {soap}). This file is constructed with paragraphs separated by empty line and stating with key word  \cfkeyword {trusted\_application}. A sample \file {trusted\_applications.conf} file is provided with Sympa sources. Each paragraph defines a remote trusted application with keyword/value pairs

\begin{itemize}
\item \cfkeyword {name} : the name of the application. Used with password for authentication ; the \cfkeyword {remote\_application\_name} variable is set for use in authorization scenarios.
\item  \cfkeyword {md5password} : the MD5 digest of the application password. You can compute the digest as follows :  \unixcmd{sympa.pl -md5\_digest=<the password>}.
\item  \cfkeyword {proxy\_for\_variables} : a comma separated list of variables that can be set by the remote application and that will be used by Sympa SOAP server when evaluating an authorization scenario. If you list \cfkeyword {USER\_EMAIL} in this parameter, then the remote application can act as a user. Any other variable such as  \cfkeyword {remote\_host} can be listed.
 
\end{itemize}


You can test your SOAP service using the \file {sympa\_soap\_client.pl} sample script as follows :
\begin {quote}
\begin{verbatim}
[BINDIR]/sympa_soap_client.pl --soap_url=http://my.server/sympasoap --service=createList --trusted_application=myTestApp --trusted_application_password=myTestAppPwd --proxy_vars="USER_EMAIL=userProxy@my.server" --service_parameters=listA,listSubject,discussion_list,description,myTopic

[BINDIR]/sympa_soap_client.pl --soap_url=http://myserver/sympasoap --service=add --trusted_application=myTestApp --trusted_application_password=myTestAppPwd  --proxy_vars="USER_EMAIL=userProxy@my.server" --service_parameters=listA,someone@some;domain,name
\end{verbatim}
\end {quote}

Availible services are :
\begin{itemize}
\item info <list>
\item which
\item lists
\item review <list>
\item amI <function>
\item subscribe  <list> 
\item signoff <list>
\item add <list><email>
\item del <list><email>
\item createList <list>...
\item closeList <list>
\item login <email><password>
\item casLogin <proxyTicket>
\item checkCookie
\end{itemize}


\section {The WSDL service description}

Here is what the WSDL file looks like before it is parsed by WWSympa :

\begin {quote}
\begin{verbatim}
[INCLUDE '../soap/sympa.wsdl']
\end{verbatim}
\end {quote}

\section {Client-side programming}

Sympa is distributed with 2 sample clients written in Perl and in PHP. Sympa SOAP server has also
been successfully tested with a UPortal Chanel as a Java client (using Axis). The sample PHP SOAP
client has been installed on our demo server :  \htmladdnormallink {http://demo.sympa.org/sampleClient.php} {http://demo.sympa.org/sampleClient.php}.

Depending on your programming language and the SOAP library you're using, you will either directly 
contact the SOAP service (as with Perl SOAP::Lite library) or first load the WSDL description of
the service (as with PHP nusoap or Java Axis). Axis is able to create a stub from the WSDL document.

The WSDL document describing the service should be fetch through WWSympa's dedicated URL :
\textbf {http://your.server/sympa/wsdl}.

Note : the \textbf {login()} function maintains a login session using HTTP cookies. If you are not able
to maintain this session by analysing and sending appropriate cookies under SOAP, then you
should use the \textbf {authenticateAndRun()} function that does not require cookies to authenticate.

\subsection {Writting a Java client with Axis}

First, download jakarta-axis (http://ws.apache.org/axis/)\\

You must add the libraries provided with jakarta axis (v >1.1) to you CLASSPATH. These libraries are  :

\begin{itemize}
\item axis.jar
\item saaj.jar
\item commons-discovery.jar
\item commons-logging.jar
\item xercesImpl.jar
\item jaxrpc.jar
\item xml-apis.jar
\item jaas.jar
\item wsdl4j.jar
\item soap.jar
\end{itemize}

Next, you have to generate client java classes files from the sympa WSDL url. Use the following command :\\

 java org.apache.axis.wsdl.WSDL2Java -av  WSDL\_URL\\

For example :
\begin{verbatim}
java org.apache.axis.wsdl.WSDL2Java -av  http://demo.sympa.org/sympa/wsdl
\end{verbatim}

Exemple of screen output during generation of java files :\\
 \begin{verbatim}
Parsing XML file:  http://demo.sympa.org/sympa/wsdl
Generating org/sympa/demo/sympa/msdl/ListType.java
Generating org/sympa/demo/sympa/msdl/SympaPort.java
Generating org/sympa/demo/sympa/msdl/SOAPStub.java
Generating org/sympa/demo/sympa/msdl/SympaSOAP.java
Generating org/sympa/demo/sympa/msdl/SympaSOAPLocator.java
\end{verbatim}

If you need  more information or more generated classes (to have the server-side classes or junit testcase classes for example), you can get a list of switches :\\
    \begin{verbatim}
java org.apache.axis.wsdl.WSDL2Java -h
    \end{verbatim}
The reference page is :\\
http://ws.apache.org/axis/java/reference.html


Take care of Test classes generated by axis, there are not useable as is. You have to stay connected between each test. To use junit testcases, before each soap operation tested, you must call the authenticated connexion to sympa instance.

Here is a simple Java code that invokes the generated stub to perform a casLogin() and a which() on the remote Sympa SOAP server :
\begin{verbatim}
SympaSOAP loc = new SympaSOAPLocator();
((SympaSOAPLocator)loc).setMaintainSession(true);
SympaPort tmp = loc.getSympaPort();
String _value = tmp.casLogin(_ticket);
String _cookie = tmp.checkCookie();
String[] _abonnements = tmp.which();
\end{verbatim}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Authentication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\cleardoublepage
\chapter {Authentication}
\label {authn}

\Sympa needs to authenticate users (subscribers, owners, moderators, listmaster) on both its
mail and web interface to then apply appropriate privileges (authorization process) to subsequent 
requested actions. \Sympa is able to cope with multiple authentication means on the client side and 
when using user+password it can validate these credentials against LDAP authentication backends.

When contacted on the mail interface \Sympa has 3 authentication levels. Lower level is to trust
the \rfcheader {From} SMTP header field. A higher level of authentication will require that the 
user confirms his/her message. The strongest supported authentication method is S/MIME (note that \Sympa 
also deals with S/MIME encrypted messages).

On the \Sympa web interface (\WWSympa) the user can authenticate in 4 different ways (if appropriate setup
has been done on \Sympa serveur). Default authentication mean is via the user's email address and a password 
managed by \Sympa itself. If an LDAP authentication backend (or multiple) has been defined, then the user 
can authentication with his/her LDAP uid and password. \Sympa is also able to delegate the authentication
job to a web Single SignOn system ; currently \htmladdnormallink {CAS} {http://www.yale.edu/tp/auth/} 
(the Yale University system) or a generic SSO setup, adapted to SSO products providing an Apache module. 
When contacted via HTTPS, \Sympa can make use of X509 client certificates to authenticate users.

The authorization process in \Sympa (authorization scenarios) refers to authentication methods. The 
same authorization scenarios are used for both mail and web accesss ; therefore some authentication 
methods are considered as equivalent : mail confirmation (on the mail interface) is equivalent to
password authentication (on the web interface) ; S/MIME authentication is equivalent to HTTPS with
client certificate authentication. Each rule in authorization scenarios requires an authentication method 
(\cfkeyword {smtp},\cfkeyword {md5} or \cfkeyword {smime}) ; if the required authentication method was 
not used, a higher authentication mode can be requested.


\section {S/MIME and HTTPS authentication}

Chapter \ref {smime-sig} (page~\pageref {smime-sig}) deals with \Sympa and S/MIME signature.
\Sympa uses \texttt {OpenSSL} library to work on S/MIME messages, you need to configure some
related \Sympa parameters : \ref {smimeconf} (page~\pageref {smimeconf}).

\Sympa HTTPS authentication is based on Apache+mod\_SSL that provide the required authentication
information via CGI environment variables. You will need to edit Apache configuration to 
allow HTTPS access and require X509 client certificate. Here is a sample Apache configuration

\begin {quote}
\begin{verbatim}
SSLEngine on
SSLVerifyClient optional
SSLVerifyDepth  10
...
<Location /sympa>
   SSLOptions +StdEnvVars
   SetHandler fastcgi-script
</Location>

 \end{verbatim}
\end {quote}

If you are using the SubjAltName, then you additionaly need to export the certificate data because of a \textindex {mod\_ssl} bug. You will also 
need to install the textindex {Crypt-OpenSSL-X509} CPAN module. Add this option to the Apache configuration file :

\begin {quote}
\begin{verbatim}
   SSLOptions +ExportCertData
 \end{verbatim}
\end {quote}




\section {Authentication with email address, uid or alternate email address}
\label {ldap-auth}

\Sympa stores the data relative to the subscribers in a DataBase. Among these data: password, email exploited during the Web authentication. The  module of \textindex {LDAP authentication} allows to use \Sympa in an intranet without duplicating user passwords. 

This way users can indifferently authenticate with their ldap\_uid, their alternate\_email or their canonic email stored in the \textindex {LDAP} directory.

\Sympa gets the canonic email in the \textindex {LDAP} directory with the ldap\_uid or the alternate\_email.  
\Sympa will first attempt an anonymous bind to the directory to get the user's DN, then \Sympa will bind with the DN and the user's ldap\_password in order to perform an efficient authentication. This last bind will work only if the good ldap\_password is provided. Indeed the value returned by the bind(DN,ldap\_password) is tested.


Example: a person is described by
\begin {quote}
\begin{verbatim}
                 Dn:cn=Fabrice Rafart,
                 ou=Siege ,
                 o=MaSociete ,
                 c=FR Objectclass:
                 person Cn: Fabrice Rafart
                 Title: Network Responsible
                 O: Siege
                 Or: Data processing
                 Telephonenumber: 01-00-00-00-00
                 Facsimiletelephonenumber:01-00-00-00-00
                 L:Paris
                 Country: France

		 uid: frafart
 		 mail: Fabrice.Rafart@MaSociete.fr
                 alternate_email: frafart@MaSociete.fr
                 alternate:rafart@MaSociete.fr
\end{verbatim}
\end {quote}

So Fabrice Rafart can be authenticated with: frafart, Fabrice.Rafart@MaSociete.fr, frafart@MaSociete.fr,Rafart@MaSociete.fr.
After this operation, the address in the field FROM will be the Canonic email, in this case  Fabrice.Rafart@MaSociete.fr. 
That means that \Sympa will get this email and use it during all the session until you clearly ask \Sympa to change your email address via the two pages : which and pref.
  

\section {Generic SSO authentication}
\label {generic-sso}

The authentication method has first been introduced to allow interraction with \htmladdnormallink {Shibboleth} {http://shibboleth.internet2.edu/}, Internet2's inter-institutional authentication system. But it should be usable with any SSO system that provides an Apache authentication module being able to protect a specified URL on the site (not the whole site). Here is a sample httpd.conf that shib-protects the associated Sympa URL :
\begin {quote}
\begin{verbatim}
...
<Location /sympa/sso_login/inqueue>
  AuthType shibboleth
  require affiliation ~ ^member@.+
</Location>
...
\end{verbatim}
\end {quote}


\Sympa will get user attributes via environment variables. In the most simple case the SSO will provide the user email address. If not, Sympa can be configured to verify an email address provided by the user hiself or to look for the user email address in a LDAP directory (the search filter will make use of user information inherited from the SSO Apache module).

To plug a new SSO server in your Sympa server you should add a \textbf {generic\_sso} paragraph (describing the SSO service) in your \file {auth.conf} configuration file (See  \ref {generic-sso-format}, page~\pageref {generic-sso-format}). Once this paragraph has been added, the SSO service name will be automatically added to the web login menu.

Apart from the user email address, the SSO can provide other user attributes that \Sympa will store in the user\_table DB table (for persistancy) and make them available in the [user\_attributes] structure that you can use within authorization scenarios (see~\ref {rules}, page~\pageref {rules}) or in web templates via the [\% user.attributes \%] structure.

\section {CAS-based authentication}
\label {cas}

CAS is Yale university SSO software. Sympa can use CAS authentication service.

The listmaster should define at least one or more CAS servers (\textbf {cas} paragraph) in \file {auth.conf}. If \textbf 
{non\_blocking\_redirection} parameter was set for a CAS server then Sympa will try a transparent login on this server
when the user accesses the web interface. If one CAS server redirect the user to Sympa with a valid ticket Sympa receives a user ID from the CAS server. It then connects to the related LDAP directory to get the user email address. If no CAS server returns a valid user ID, Sympa will let the user either select a CAS server to login or perform a Sympa login.

\section {auth.conf}
\label {auth-conf}

The \file {[ETCDIR]/auth.conf} configuration file contains numerous
parameters which are read on start-up of \Sympa. If you change this file, do not forget
that you will need to restart wwsympa.fcgi afterwards. 

The \file {[ETCDIR]/auth.conf} is organised in paragraphs. Each paragraph describes an authentication 
service with all required parameters to perform an authentication using this service. Current version of
\Sympa can perform authentication through LDAP directories, using an external Single Sign-On Service (like CAS 
or Shibboleth), or using internal user\_table.

The login page contains 2 forms : the login form and the SSO. When users hit the login form, each ldap or user\_table authentication
paragraph is applied unless email adress input from form match the \cfkeyword {negative\_regexp} or do not match \cfkeyword {regexp}. 
 \cfkeyword {negative\_regexp} and \cfkeyword {regexp} can be defined for earch ldap or user\_table authentication service so
administrator can block some authentication methode for class of users.

The segond form in login page contain the list of CAS server so user can choose explicitely his CAS service.

Each paragraph start with one of the keyword cas, ldap or user\_table  

The \file {[ETCDIR]/auth.conf} file contains directives in the following format:

\begin {quote}

 \textit {paragraphs}\\
    \textit {keyword    value}

 \textit {paragraphs}\\
    \textit {keyword    value} 

\end {quote}

Comments start with the \texttt {\#} character at the beginning of a line.
  
Empty lines are also considered as comments and are ignored at the beginning. After the first paragraph they are considered as paragraphs separators.
There should only be one directive per line, but their order in the paragraph is of no importance.

Example :

\begin {quote}
\begin{verbatim}
[STOPPARSE]
#Configuration file auth.conf for the LDAP authentification
#Description of parameters for each directory


cas
	base_url			https://sso-cas.cru.fr
	non_blocking_redirection        on
	auth_service_name		cas-cru
	ldap_host			ldap.cru.fr:389
        ldap_get_email_by_uid_filter    (uid=[uid])
	ldap_timeout			7
	ldap_suffix			dc=cru,dc=fr
	ldap_scope			sub
	ldap_email_attribute		mail

## The URL corresponding to the service_id should be protected by the SSO (Shibboleth in the exampl)
## The URL would look like http://yourhost.yourdomain/sympa/sso_login/inqueue in the following example
generic_sso
        service_name       InQueue Federation
        service_id         inqueue
        http_header_prefix HTTP_SHIB
        email_http_header  HTTP_SHIB_EMAIL_ADDRESS

## The email address is not provided by the user home institution
generic_sso
        service_name               Shibboleth Federation
        service_id                 myfederation
        http_header_prefix         HTTP_SHIB
        netid_http_header          HTTP_SHIB_EMAIL_ADDRESS
	internal_email_by_netid    1
	force_email_verify         1

ldap
	regexp				univ-rennes1\.fr
	host				ldap.univ-rennes1.fr:389
	timeout				30
	suffix				dc=univ-rennes1,dc=fr
	get_dn_by_uid_filter		(uid=[sender])
	get_dn_by_email_filter		(|(mail=[sender])(mailalternateaddress=[sender]))
	email_attribute			mail
	alternative_email_attribute	mailalternateaddress,ur1mail
	scope				sub
	use_ssl                         1
	ssl_version                     sslv3
	ssl_ciphers                     MEDIUM:HIGH

ldap
	
	host				ldap.univ-nancy2.fr:392,ldap1.univ-nancy2.fr:392,ldap2.univ-nancy2.fr:392
	timeout				20
	bind_dn                         cn=sympa,ou=people,dc=cru,dc=fr
	bind_password                   sympaPASSWD
	suffix				dc=univ-nancy2,dc=fr
	get_dn_by_uid_filter		(uid=[sender])
	get_dn_by_email_filter			(|(mail=[sender])(n2atraliasmail=[sender]))
	alternative_email_attribute	n2atrmaildrop
	email_attribute			mail
	scope				sub
        authentication_info_url         http://sso.univ-nancy2.fr/
	

user_table
	negative_regexp 		((univ-rennes1)|(univ-nancy2))\.fr

[STARTPARSE]
\end{verbatim}
\end {quote}

\subsection {user\_table paragraph}

The user\_table paragraph is related to sympa internal authentication by email and password. It is the simplest one the only parameters
are \cfkeyword {regexp} or \cfkeyword {negative\_regexp} which are perl regular expressions applied on a provided email address to select or block this authentication method for a subset of email addresses. 


\subsection {ldap paragraph}


\begin{itemize}
\item {\cfkeyword {regexp} and \cfkeyword {negative\_regexp}}
	Same as in user\_table paragraph : if a provided email address (does not apply to an uid), then the
	regular expression will be applied to find out if this LDAP directory can be used to authenticate a
	subset of users.

\item{host}\\

        This keyword is \textbf {mandatory}. It is the domain name
	used in order to bind to the directory and then to extract informations.
	You must mention the port number after the server name.
	Server replication is supported by listing several servers separated by commas.

        Example :
	\begin {quote}
	\begin{verbatim}

	host ldap.univ-rennes1.fr:389
	host ldap0.university.com:389,ldap1.university.com:389,ldap2.university.com:389

	\end{verbatim}
	\end {quote}
	

\item{timeout}\\ 
	
	It corresponds to the timelimit in the Search fonction. A timelimit that restricts the maximum 
	time (in seconds) allowed for a search. A value of 0 (the default), means that no timelimit
        will be requested.
 
\item{suffix}\\ 

	The root of the DIT (Directory Information Tree). The DN that is the base object entry relative 
	to which the search is to be performed. 

        \example {dc=university,dc=fr}

\item{bind\_dn}\\ 

        If anonymous bind is not allowed on the LDAP server, a DN and password can be used.

\item{bind\_password}\\ 

        This password is used, combined with the bind\_dn above.

\item{get\_dn\_by\_uid\_filter}\\

[STOPPARSE]	
	Defines the search filter corresponding to the ldap\_uid. (RFC 2254 compliant).
	If you want to apply the filter on the user, use the variable ' [sender] '. It will work with every
	type of authentication (uid, alternate\_email..). 
	  
	Example :
	\begin {quote}
	\begin{verbatim}

	(Login = [sender])
	(|(ID = [sender])(UID = [sender]))

	\end{verbatim}
	\end {quote}
	
\item{get\_dn\_by\_email\_filter}\\

	Defines the search filter corresponding to the email addresses (canonic and alternative).(RFC 2254 compliant). 
	If you want to apply the filter on the user, use the variable ' [sender] '. It will work with every
	type of authentication (uid, alternate\_email..). 

 		Example: a person is described by

\begin {quote}
\begin{verbatim}



                 Dn:cn=Fabrice Rafart,
                 ou=Siege ,
                 o=MaSociete ,
                 c=FR Objectclass:
                 person Cn: Fabrice Rafart
                 Title: Network Responsible
                 O: Siege
                 Or: Data processing
                 Telephonenumber: 01-00-00-00-00
                 Facsimiletelephonenumber:01-00-00-00-00
                 L:Paris
                 Country: France

		 uid: frafart
 		 mail: Fabrice.Rafart@MaSociete.fr
                 alternate_email: frafart@MaSociete.fr
                 alternate:rafart@MaSociete.fr
  

\end{verbatim}
\end {quote}

	The filters can be :

\begin {quote}
\begin{verbatim}
	
	(mail = [sender])
	(| (mail = [sender])(alternate_email = [sender]) )
	(| (mail = [sender])(alternate_email = [sender])(alternate  = [sender]) )

[STARTPARSE]

\end{verbatim}
\end {quote}

\item{email\_attribute}\\
	
	The name of the attribute for the canonic email in your directory : for instance mail, canonic\_email, canonic\_address ...
	In the previous example the canonic email is 'mail'.

		 
\item{alternative\_email\_attribute}\\

	The name of the attribute for the alternate email in your directory : for instance alternate\_email, mailalternateaddress, ...
	You make a list of these attributes separated by commas.

	With this list \Sympa creates a cookie which contains various information : the user is authenticated via Ldap or not, his alternate email. To store the alternate email is interesting when you want to canonify your preferences and subscriptions. 
	That is to say you want to use a unique address in User\_table and Subscriber\_table which is the canonic email.

\item{scope}\\

	\default {sub}
	By default the search is performed on the whole tree below the specified base object. This may be changed by 
	specifying a scope :

\begin{itemize}

	\item{base}\\
	Search only the base object.

	\item{one}\\ 
	Search the entries immediately below the base object. 

 	\item{sub}\\         
	Search the whole tree below the base object. This is the default. 

\end{itemize}

\item{authentication\_info\_url}\\

        Defines the URL of a document describing LDAP password management. When hitting Sympa's 
	\textit {Send me a password} button, LDAP users will be redirected to this URL.

\item{use\_ssl}
   
        If set to \texttt {1}, connection to the LDAP server will use SSL (LDAPS).

\item{ssl\_version}

        This defines the version of the SSL/TLS protocol to use. Defaults of \textindex {Net::LDAPS} to \texttt {sslv2/3}, 
	other possible values are \texttt {sslv2}, \texttt {sslv3}, and \texttt {tlsv1}.

\item{ssl\_ciphers}
  
        Specify which subset of cipher suites are permissible for this connection, using the standard 
	OpenSSL string format. The default value of \textindex {Net::LDAPS} for ciphers is \texttt {ALL}, 
	which permits all ciphers, even those that don't encrypt!


\end{itemize}


\subsection {generic\_sso paragraph}
\label {generic-sso-format}

 \begin{itemize}

 \item{service\_name} \\
This is the SSO service name that will be proposed to the user in the login banner menu.

\item{service\_id} \\
This service ID is used as a parameter by sympa to refer to the SSO service (instead of the service name). 

A corresponding URL on the local web server should be protected by the SSO system ; this URL would look like \textbf {http://yourhost.yourdomain/sympa/sso\_login/inqueue} if the service\_id is \textbf {inqueue}.

\item{http\_header\_prefix} \\
Sympa gets user attributes from environment variables comming from the web server. These variables are then stored in the user\_table DB table for later use in authorization scenarios (in [user_attributes] structure). Only environment variables starting with the defined prefix will kept.

\item{email\_http\_header} \\
This parameter defines the environment variable that will contain the authenticated user's email address.

\end{itemize}

The following parameters define how Sympa can verify the user email address, either provided by the SSO or by the user himself :

 \begin{itemize}

\item{internal\_email\_by\_netid} \\
If set to 1 this parameter makes Sympa use its netidmap table to associate NetIDs to user email address.

\item{netid\_http\_header} \\
This parameter defines the environment variable that will contain the user's identifier. This netid will then be associated with an email address either provided by the user.

\item{force\_email\_verify} \\
If set to 1 this parameter makes Sympa verify the user's email address. If the email address was not provided by the authentication module, then the user is requested to provide a valid email address.


\end{itemize}

The following parameters define how Sympa can retrieve the user email address ; \textbf {these are only useful if the email\_http\_header entry was not defined :}

 \begin{itemize}

\item{ldap\_host}\\
	The LDAP host Sympa will connect to fetch user email. The ldap\_host include the
        port number and it may be a comma separated list of redondant host.   

\item{ldap\_bind\_dn}\\
	The DN used to bind to this server. Anonymous bind is used if this parameter is not defined.
				    
\item{ldap\_bind\_password}\\
	The password used unless anonymous bind is used.

\item{ldap\_suffix}\\
	The LDAP suffix used when seraching user email

\item{ldap\_scope}\\
	The scope used when seraching user email, possible values are \texttt {sub}, \texttt {base}, and \texttt {one}.

\item{ldap\_get\_email\_by\_uid\_filter}\\
	The filter to perform the email search. It can refer to any environment variables inherited from the SSO module, as shown below.
	Example : 
	\begin {quote}
	  \begin{verbatim}
[STOPPARSE]
	    ldap_get_email_by_uid_filter    (mail=[SSL_CLIENT_S_DN_Email])
[STARTPARSE]
	  \end{verbatim}
	\end {quote}

\item{ldap\_email\_attribute}\\
	The attribut name to be used as user canonical email. In the current version of sympa only the first value returned by the LDAP server is used.

\item{ldap\_timeout}\\
	The time out for the search.

\item{ldap\_use\_ssl}
   
        If set to \texttt {1}, connection to the LDAP server will use SSL (LDAPS).

\item{ldap\_ssl\_version}

        This defines the version of the SSL/TLS protocol to use. Defaults of \textindex {Net::LDAPS} to \texttt {sslv2/3}, 
	other possible values are \texttt {sslv2}, \texttt {sslv3}, and \texttt {tlsv1}.

\item{ldap\_ssl\_ciphers}
  
        Specify which subset of cipher suites are permissible for this connection, using the  
	OpenSSL string format. The default value of \textindex {Net::LDAPS} for ciphers is \texttt {ALL}, 
	which permits all ciphers, even those that don't encrypt!


 \end{itemize}


\subsection {cas paragraph}


\begin{itemize}

\item{auth\_service\_name}\\
	The friendly user service name as shown by \Sympa in the login page.

\item{host} (OBSOLETE) \\
        This parameter has been replaced by \textbf {base\_url} parameter

\item{base\_url} \\

	The base URL of the CAS server.


\item{non\_blocking\_redirection}\\  

This parameter concern only the first access to Sympa services by a user, it activate or not the non blocking
redirection to the related cas server to check automatically if the user as been previously authenticated with  this CAS server.
Possible values are \textbf {on}  \textbf {off}, default is  \textbf {on}. The redirection to CAS is use with
the cgi parameter \textbf {gateway=1} that specify to CAS server to always redirect the user to the origine
URL but just check if the user is logged. If active, the SSO service is effective and transparent, but in case
the CAS server is out of order the access to Sympa services is impossible.


\item{login\_uri} (OBSOLETE) \\
        This parameter has been replaced by \textbf {login\_path} parameter.

\item{login\_path} (OPTIONAL)\\
	The login service path

\item{check\_uri} (OBSOLETE) \\
        This parameter has been replaced by \textbf {service\_validate\_path} parameter

\item{service\_validate\_path} (OPTIONAL)\\
	The ticket validation service path

\item{logout\_uri} (OBSOLETE) \\
        This parameter has been replaced by \textbf {logout\_path} parameter

\item{logout\_path} (OPTIONAL)\\
	The logout service path

\item{proxy\_path} (OPTIONAL)\\
	The proxy service path, used by Sympa SOAP server only.

\item{proxy\_validate\_path} (OPTIONAL)\\
	The proxy validate service path, used by Sympa SOAP server only.

\item{ldap\_host}\\
	The LDAP host Sympa will connect to fetch user email when user uid is return by CAS service. The ldap\_host include the
        port number and it may be a comma separated list of redondant host.   

\item{ldap\_bind\_dn}\\
	The DN used to bind to this server. Anonymous bind is used if this parameter is not defined.
				    
\item{ldap\_bind\_password}\\
	The password used unless anonymous bind is used.

\item{ldap\_suffix}\\
	The LDAP suffix used when seraching user email

\item{ldap\_scope}\\
	The scope used when seraching user email, possible values are \texttt {sub}, \texttt {base}, and \texttt {one}.

\item{ldap\_get\_email\_by\_uid\_filter}\\
	The filter to perform the email search.

\item{ldap\_email\_attribute}\\
	The attribut name to be use as user canonical email. In the current version of sympa only the first value returned by the LDAP server is used.

\item{ldap\_timeout}\\
	The time out for the search.


\item{ldap\_use\_ssl}
   
        If set to \texttt {1}, connection to the LDAP server will use SSL (LDAPS).

\item{ldap\_ssl\_version}

        This defines the version of the SSL/TLS protocol to use. Defaults of \textindex {Net::LDAPS} to \texttt {sslv2/3}, 
	other possible values are \texttt {sslv2}, \texttt {sslv3}, and \texttt {tlsv1}.

\item{ldap\_ssl\_ciphers}
  
        Specify which subset of cipher suites are permissible for this connection, using the  
	OpenSSL string format. The default value of \textindex {Net::LDAPS} for ciphers is \texttt {ALL}, 
	which permits all ciphers, even those that don't encrypt!

\end{itemize}

\section {Sharing \WWSympa authentication with other applications}
\label {sharing-auth}

If your are not using a web Single SignOn system you might want to make other web applications collaborate with \Sympa,
and share the same authentication system. \Sympa uses
HTTP cookies to carry users' auth information from page to page.
This cookie carries no information concerning privileges. To make your application
work with \Sympa, you have two possibilities :

\begin {itemize}

\item Delegating authentication operations to \WWSympa \\
If you want to avoid spending a lot of time programming a CGI to do Login, Logout
and Remindpassword, you can copy \WWSympa's login page to your 
application, and then make use of the cookie information within your application. 
The cookie format is :
\begin{verbatim}
sympauser=<user_email>:<checksum>
\end{verbatim}
where \texttt{<}user\_email\texttt{>} is the user's complete e-mail address, and
\texttt{<}checksum\texttt{>} are the 8 last bytes of the a MD5 checksum of the \texttt{<}user\_email\texttt{>}+\Sympa \cfkeyword {cookie}
configuration parameter.
Your application needs to know what the \cfkeyword {cookie} parameter
is, so it can check the HTTP cookie validity ; this is a secret shared
between \WWSympa and your application.
\WWSympa's \textit {loginrequest} page can be called to return to the
referer URL when an action is performed. Here is a sample HTML anchor :

\begin{verbatim}
<A HREF="/sympa/loginrequest/referer">Login page</A>
\end{verbatim}

You can also have your own HTML page submitting data to \file {wwsympa.fcgi} CGI. If you're
doing so, you can set the \texttt {referer} variable to another URI. You can also
set the \texttt {failure\_referer} to make WWSympa redirect the client to a different
URI if login fails.

\item Using \WWSympa's HTTP cookie format within your auth module \\
To cooperate with \WWSympa, you simply need to adopt its HTTP
cookie format and share the secret it uses to generate MD5 checksums,
i.e. the \cfkeyword {cookie} configuration parameter. In this way, \WWSympa
will accept users authenticated through your application without
further authentication.

\end {itemize}

\section {Provide a Sympa login form in another application}
\label {external-auth}

You can easily trigger a Sympa login from within another web page. The login form should look like this :
\begin {quote}
\begin{verbatim}
<FORM ACTION="http://listes.cru.fr/sympa" method="post">
      <input type="hidden" name="previous_action" value="arc" />
      Accès web archives of list
      <select name="previous_list">
      <option value="sympa-users" >sympa-users</option>
      </select><br/>

      <input type="hidden" name="action" value="login" />
      <label for="email">email address :
      <input type="text" name="email" id="email" size="18" value="" /></label><br />
      <label for="passwd" >password :
      <input type="password" name="passwd" id="passwd" size="8" /></label> <br/>
      <input class="MainMenuLinks" type="submit" name="action_login" value="Login and access web archives" />
</FORM>
\end{verbatim}
\end  {quote}

The example above does not only perform the login action but also redirects the user to another sympa page, a list web archives here. 
The  \texttt {previous\_action} and \texttt {previous\_list} variable define the action that will be performed after the login is done.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Managing authorizations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\cleardoublepage
\chapter {Authorization scenarios}
\label {scenarios}
\index{scenario}

List parameters controlling the behavior of commands are linked to different authorization scenarios.
For example : the \cfkeyword {send private} parameter is related to the send.private scenario.
There are four possible locations for a authorization scenario. When \Sympa seeks to apply an authorization scenario, it
looks first in the related list directory \dir {[EXPL_DIR]/\texttt{<}list\texttt{>}/scenari}. If it
does not find the file there, it scans the current robot configuration directory \dir {[ETCDIR]/\samplerobot/scenari}, then the site's configuration directory \dir {[ETCDIR]/scenari},
and finally \dir {[ETCBINDIR]/scenari}, which is the directory installed by the Makefile.

An authorization scenario is a small configuration language to describe who
can perform an operation and which authentication method is requested for it.
An authorization scenario is an ordered set of rules. The goal is to provide a simple and
flexible way to configure authorization and required authentication method for each operation.


Each authorization scenario rule contains :
\begin{itemize}
[STOPPARSE]
\item a condition : the condition is evaluated by \Sympa. It can use
  variables such as $[$sender$]$ for the sender e-mail, $[$list$]$ for the listname etc.
\item an authentication method. The authentication method can be \cfkeyword {smtp},
\cfkeyword {md5} or \cfkeyword {smime}. The rule is applied by \Sympa if both condition
and authentication method match the runtime context. \cfkeyword {smtp} is used if
\Sympa use the SMTP \cfkeyword {from:} header , \cfkeyword {md5} is used if a unique
md5 key as been returned by the requestor to validate her message, \cfkeyword {smime}
is used for signed messages (see \ref {smimeforsign}, page~\pageref {smimeforsign}).
\item a returned atomic action that will be executed by \Sympa if the rule matches

\end{itemize}

 
Example

\begin {quote}
del.auth
\begin{verbatim}
title.us deletion performed only by list owners, need authentication
title.fr suppression réservée au propriétaire avec authentification
title.es eliminacin reservada slo para el propietario, necesita autentificacin


  is_owner([listname],[sender])  smtp       -> request_auth
  is_listmaster([sender])        smtp       -> request_auth
  true()                         md5,smime  -> do_it
\end{verbatim}
\end {quote}

\section {rules specifications}
\label {rules}

An authorization scenario consists of rules, evaluated in order beginning with the first. 
Rules are defined as follows :
\begin {quote}
\begin{verbatim}
<rule> ::= <condition> <auth_list> -> <action>

<condition> ::= [!] <condition
                | true ()
                | all ()
                | equal (<var>, <var>)
                | match (<var>, /perl_regexp/)
		| search (<named_filter_file>,<var>)
                | is_subscriber (<listname>, <var>)
                | is_owner (<listname>, <var>)
                | is_editor (<listname>, <var>)
                | is_listmaster (<var>)
                | older (<date>, <date>)    # true if first date is anterior to the second date
                | newer (<date>, <date>)    # true if first date is posterior to the second date
                | CustomCondition::<package_name> (<var>*)

<var> ::= [email] | [sender] | [user-><user_key_word>] | [previous_email]
                  | [remote_host] | [remote_addr] | [user_attributes-><user_attributes_keyword>]
	 	  | [subscriber-><subscriber_key_word>] | [list-><list_key_word>] | [env-><env_var>]
		  | [conf-><conf_key_word>] | [msg_header-><smtp_key_word>] | [msg_body] 
	 	  | [msg_part->type] | [msg_part->body] | [msg_encrypted] | [is_bcc] | [current_date] 
		  | [topic-auto] | [topic-sender,] | [topic-editor] | [topic] | [topic-needed]
		  | <string>

[is_bcc] ::= set to 1 if the list is neither in To: nor Cc:

[sender] ::= email address of the current user (used on web or mail interface). Default value is 'nobody'

[previous_email] ::= old email when changing subscription email in preference page. 

[msg_encrypted] ::= set to 'smime' if the message was S/MIME encrypted

[topic-auto] ::= topic of the message if it has been automatically tagged

[topic-sender] ::= topic of the message if it has been tagged by sender

[topic-editor] ::= topic of the message if it has been tagged by editor

[topic]  ::= topic of the message

[topic-needed] ::= the message has not got any topic and message topic are required for the list

/perl_regexp/ ::= a perl regular expression. Don't forget to escape special characters (^, $, \{, \(, ...) 
Check http://perldoc.perl.org/perlre.html for regular expression syntax.

<date> ::= '<date_element> [ +|- <date_element>]'

<date_element> ::= <epoch_date> | <var> | <date_expr>

<epoch_date> ::= <integer>

<date_expr> ::= <integer>y<integer>m<integer>d<integer>h<integer>min<integer>sec

<listname> ::= [listname] | <listname_string>

<auth_list> ::= <auth>,<auth_list> | <auth>

<auth> ::= smtp|md5|smime

<action> ::=   do_it [,notify]
             | do_it [,quiet]
	     | reject(reason=<reason_key>) [,quiet]
	     | reject(tt2=<tpl_name>) [,quiet]
             | request_auth
             | owner
	     | editor
	     | editorkey[,quiet]
	     | listmaster

<reason_key> ::= match a key in mail_tt2/authorization_reject.tt2 template corresponding to 
                 an information message about the reason of the reject of the user
  
<tpl_name> ::= corresponding template (<tpl_name>.tt2) is send to the sender

<user_key_word> ::= email | gecos | lang | password | cookie_delay_user
	            | <additional_user_fields>

<user_attributes_key_word> ::= one of the user attributes provided by the SSO system via environment variables. The [user_attributes] structure is available only if user authenticated with a generic_sso.

<subscriber_key_word> ::= email | gecos | bounce | reception 
	                  | visibility | date | update_date
			  | <additional_subscriber_fields>

<list_key_word> ::= name | host | lang | max_size | priority | reply_to | 
		    status | subject | account | total

<conf_key_word> ::= domain | email | listmaster | default_list_priority | 
		      sympa_priority | request_priority | lang | max_size

<named_filter_file> ::= filename ending with .ldap , .sql or .txt

<package_name> ::= name of a perl package in /etc/custom_conditions/ (small letters)
\end{verbatim}
\end {quote}

(Refer to  \ref {tasks}, page~\pageref {tasks} for date format definition)

The function to evaluate scenario is described in section \ref {list-scenario-evaluation}, page~\pageref {list-scenario-evaluation}.

perl\_regexp can contain the string [host] (interpreted at run time as the list or robot domain).
The variable notation [msg\_header-\texttt{>}\texttt{<}smtp\_key\_word\texttt{>}] is interpreted as the 
SMTP header value only when evaluating the authorization scenario for sending messages. 
It can be used, for example, to require editor validation for multipart messages.
[msg\_part-\texttt{>}type] and [msg\_part-\texttt{>}body] are the MIME parts content-types and bodies ; the body is available
for MIME parts in text/xxx format only.

The difference between \textindex {editor} and \textindex {editorkey} is, that with \textindex {editor} the message is simply forwarded to the moderaotr. He then can forward it to the list, if he wishes. \textindex {editorkey} assigns a key to the message and sends it to the moderator together with the message. So the moderator can just send back the key to distribute the message. Please note, that moderation from the webinterface is only possible when using \textindex {editorkey}, because otherwise there is no copy of the message saved on the server. 

A bunch of authorization scenarios is provided with the \Sympa distribution ; they provide
a large set of configuration that allow to create lists for most usage. But you will
probably create authorization scenarios for your own need. In this case, don't forget to restart \Sympa
and wwsympa because authorization scenarios are not reloaded dynamicaly.

[STARTPARSE]
These standard authorization scenarios are located in the \dir {[ETCBINDIR]/scenari/}
directory. Default scenarios are named \texttt{<}command\texttt{>}.default.

You may also define and name your own authorization scenarios. Store them in the
\dir {[ETCDIR]/scenari} directory. They will not be overwritten by Sympa release.
Scenarios can also be defined for a particular virtual host (using directory \dir {[ETCDIR]/\texttt{<}robot\texttt{>}/scenari}) or for a list ( \dir {[EXPL_DIR]/\texttt{<}robot\texttt{>}/\texttt{<}list\texttt{>}/scenari} ). \textbf {Sympa will not dynamically detect that a list config should be reloaded after a scenario has been changed on disk.}

[STOPPARSE]

Example:

Copy the previous scenario to \file {scenari/subscribe.rennes1} :

\begin {quote}
\begin{verbatim}
equal([sender], 'userxxx@univ-rennes1.fr') smtp,smime -> reject
match([sender], /univ-rennes1\.fr$/) smtp,smime -> do_it
true()                               smtp,smime -> owner
\end{verbatim}
\end {quote}

You may now refer to this authorization scenario in any list configuration file, for example :

\begin {quote}
\begin{verbatim}
subscribe rennes1
\end{verbatim}
\end {quote}

\section {Named Filters}
\label {named-filters}

At the moment Named Filters are only used in authorization scenarios. They enable to select a category of people who will be authorized or not to realise some actions.
	
As a consequence, you can grant privileges in a list to people belonging to an \textindex {LDAP} directory, an \textindex {SQL} database or an flat text file, thanks to an authorization scenario.
	
Note that the only variable available in named filters is [sender] and is set to the email address of the acting user.

\subsection {LDAP Named Filters Definition}

[STARTPARSE]
       People are selected through an \textindex {LDAP filter} defined in a configuration file. This file must have the extension '.ldap'. It is stored in \dir {[ETCDIR]/search\_filters/}.
	
       You must give several informations in order to create a LDAP Named Filter:
\begin{itemize}

	\item{host}\\
	A list of host:port LDAP directories (replicates) entries.

	\item{suffix}\\
	Defines the naming space covered by the search (optional, depending on the LDAP server).

[STOPPARSE]
	\item{filter}\\
	Defines the LDAP search filter (RFC 2254 compliant). 
	But you must absolutely take into account the first part of the filter which is:
	('mail\_attribute' = [sender]) as shown in the example. you will have to replce 'mail\_attribute' by the name 
	of the attribute for the email.
	\Sympa verifies if the user belongs to the category of people defined in the filter. 
[STARTPARSE]	

	\item{scope}\\
	By default the search is performed on the whole tree below the specified base object. This may be changed by specifying a scope :

	\begin{itemize}
		\item{base} : Search only the base object.
		\item{one}\\ 
		Search the entries immediately below the base object. 
 		\item{sub}\\         
		Search the whole tree below the base object. This is the default. 
	\end{itemize}
 
	\item{bind\_dn}\\
	  If anonymous bind is not allowed on the LDAP server, a DN and password can be used.

	\item{bind\_password}\\
	  This password is used, combined with the bind\_dn above.

\end{itemize}


example.ldap : we want to select the professors of mathematics in the university of Rennes1 in France
\begin {quote}
\begin{verbatim}
	
[STOPPARSE]
	host		ldap.univ-rennes1.fr:389,ldap2.univ-rennes1.fr:390
	suffix		dc=univ-rennes1.fr,dc=fr
	filter		(&(canonic_mail = [sender])(EmployeeType = prof)(subject = math))
	scope		sub

\end{verbatim}
\end {quote}

\subsection {SQL Named Filters Definition}

[STARTPARSE]
       People are selected through an \textindex {SQL filter} defined in a configuration file. This file must have the extension '.sql'. It is stored in \dir {[ETCDIR]/search\_filters/}.

       To create an SQL Named Filter, you have to configure SQL host, database and options, the same way you did it for the main Sympa database in sympa.conf.
       Of course you can use different database and options. Sympa will open a new Database connection to execute your statement.

       Please refer to section  \ref {database-related}, page~\pageref {database-related} for a detailed explanation of each parameter.

       Here, all database parameters have to be grouped in one \texttt {sql\_named\_filter\_query} paragraph.

\begin{itemize}

       \item{db\_type}\\
       \texttt {Format: db\_type mysql | SQLite | Pg | Oracle | Sybase}
       Database management system used. Mandatory and Case sensitive.

       \item{db\_host}\\
       Database host name. Mandatory.

       \item{db\_name}\\
       Name of database to query. Mandatory.

       \item{statement}\\
       Mandatory. The SQL statement to execute to verify authorization. This statement must returns 0 to refuse the action, or anything else to grant privileges.
       The \texttt {SELECT COUNT(*)...} statement is the perfect query for this parameter.
       The \texttt {[sender]} keyword in the SQL query will be replaced by the sender's email.

       \item{Optional parameters}\\
       Please refer to main sympa.conf section for description.
       \begin{itemize}
               \item{db\_user}
               \item{db\_password}
               \item{db\_options}
               \item{db\_env}
               \item{db\_port}
               \item{db\_timeout}
       \end{itemize}

\end{itemize}


example.sql : we want to select the professors of mathematics in the university of Rennes1 in France
\begin {quote}
\begin{verbatim}
[STOPPARSE]
       sql_named_filter_query
       db_type         mysql
       db_name         people
       db_host         dbserver.rennes1.fr
       db_user         sympa
       db_passwd       pw_sympa_mysqluser
       statement       SELECT count(*) as c FROM users WHERE mail=[sender] AND EmployeeType='PROFESSOR' AND department='mathematics'
\end{verbatim}
\end {quote}


\subsection {Search Condition}
	
The search condition is used in authorization scenarios which are defined and described in (see~\ref {scenarios}) 

The syntax of this rule is:
\begin {quote}
\begin{verbatim}
	search(example.ldap,[sender])      smtp,smime,md5    -> do_it
	search(blacklist.txt,[sender])     smtp,smime,md5    -> do_it
\end{verbatim}
\end {quote}

The variables used by 'search' are :
\begin{itemize}
	\item{the name of the LDAP Configuration file or a txt matching enumeration}\\
	\item{the [sender]}\\
	That is to say the sender email address.
\end{itemize}
 
+Note that \Sympa processes maintain a cache of processed search conditions to limit access to the LDAP directory or SQL server; each entry has a lifetime of 1 hour in the cache.

When using .txt file extention, the file is read looking for a line that match the second parameter (usually the user email address). Each line is a string where the
char * can be used once to mach any block. This feature is used by the blacklist implicit scenario rule.   (see~\ref {blacklist}) 

The method of authentication does not change.
[STARTPARSE]

\section {scenario inclusion}

Scenarios can also contain includes :

\begin {quote}
\begin{verbatim}
    subscribe
        include commonreject
        match([sender], /cru\.fr$/)          smtp,smime -> do_it
	true()                               smtp,smime -> owner
\end{verbatim}
\end {quote}
	    

In this case sympa applies recursively the scenario named \texttt {include.commonreject}
before introducing the other rules. This possibility was introduced in
order to facilitate the administration of common rules.

You can define a set of common scenario rules, used by all lists.
include.\texttt{<}action\texttt{>}.header is automatically added to evaluated scenarios.
Note that you will need to restart Sympa processes to force reloading of list config files.

\section {blacklist implicit rule}

For each service listed in parameter \cfkeyword {use\_blacklist} (see~\ref {useblacklist}), the following implicit scenario rule is added at the beginning of the scenario :
\begin {quote}
\begin{verbatim}
search(blacklist.txt,[sender])  smtp,md5,pgp,smime -> reject,quiet
\end{verbatim}
\end {quote}
	    
The goal is to block message or other service request from unwanted users. The blacklist can be defined for the robot or for the list. The one at the list level is to
managed by list owner or list editor  via the web interface.

\section {Custom perl package conditions}

You can use a perl package of your own to evaluate a custom condition. It could be usefull if you have very complex
tasks to accomplish to evaluate your condition (web services queries...). You write a perl module, place it in the CustomCondition namespace, with one verify fonction that have to return 1 to grant access, undef to throw an error, or anything else to refuse the authorization.

This perl module:
\begin{itemize}
	\item{must be placed in a subdirectoy \texttt {'custom\_conditions'} of the \texttt {'etc'} directory of your sympa installation, or of a robot }\\
	\item{its filename must be lowercase}\\
	\item{must be placed in the CustomCondition namespace}\\
	\item{must contains one \texttt {'verify'} static fonction}\\
	\item{will receive all condition arguments as parameters}\\
\end{itemize}

For example, lets write the smallest custom condition that always returns 1.

\begin {quote}
\begin{verbatim}
  /home/sympa/etc/custom_conditions/yes.pm :

      #!/usr/bin/perl

      package CustomCondition::yes;

      use strict;
      use Log; # optional : we log parameters

      sub verify {
        my @args = @_;
        foreach my $arg (@args) {
          do_log ('debug3', 'arg: %s', $arg);
        }
        # I always say 'yes'
        return 1;
      }
      ## Packages must return true.
      1;
\end{verbatim}
\end {quote}

We can use this custom condition that way :

\begin {quote}
\begin{verbatim}
CustomCondition::yes([sender],[list->name],[list->total])      smtp,smime,md5    -> do_it
true()                               smtp,smime -> reject
\end{verbatim}
\end {quote}

Note that the \texttt {[sender],[list->name],[list->total]} are optionnal, but it's the way you can pass information to your package. Our yes.pm will print their values in the logs.

Remember that the package name has to be small letters, but the 'CustomCondition' namespace is case sensitive. If your package return undef, the sender will receive an 'internal error' mail. If it returns anything else but '1', the sender will receive a 'forbidden' error.

\section {Hidding scenario files}

Because \Sympa is distributed with many default scenario files, you may want to hidde some of them 
to list owners (to make list admin menus shorter and readable). To hidde a scenario file you should 
create an empty file with the \texttt{:ignore} suffix. Depending on where this file has been created
will make it ignored at either a global, robot or list level.

[STARTPARSE]
\textit {Example :} 
\begin {quote}
[ETCDIR]/\samplerobot/scenari/send.intranetorprivate:ignore
\end {quote}

The \texttt{intranetorprivate} \texttt{send} scenario will be hidden (on the web admin interface),
at the \samplerobot robot level only.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% virtual host how to
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\chapter {virtual host}
    \label {virtual-robot}

Sympa is designed to manage multiple distinct mailing list servers on
a single host with a single Sympa installation. Sympa virtual hosts
are like Apache virtual hosting. Sympa virtual host definition includes
a specific email address for the robot itself and its lists and also a virtual
http server. Each robot provides access to a set of lists, each list is
related to only one robot.

Most configuration parameters can be redefined for each robot except 
general Sympa installation parameters (binary and spool location, smtp engine,
antivirus plugging,...).

The virtual host name as defined in \Sympa documentation and configuration file refers
to the Internet domaine of the virtual host.

Note that the main limitation of virtual hosts in Sympa is that you cannot create 
2 lists with the same name (local part) among your virtual hosts.

\section {How to create a virtual host}

You don't need to install several Sympa servers. A single \file {sympa.pl} daemon
and one or more fastcgi servers can serve all virtual host. Just configure the 
server environment in order to accept the new domain definition.
\begin {itemize}
\item \textbf {The DNS} must be configured to define a new mail exchanger record (MX) 
to route message to your server. A new host (A record) or alias (CNAME) are mandatory
to define the new web server.
\item Configure your \textbf {MTA (sendmail, postfix, exim, ...)} to accept incoming 
messages for the new robot domain. Add mail aliases for the robot :

\textit {Examples (with sendmail):} 
\begin {quote}
\begin{verbatim}
sympa@your.virtual.domain:      "| [MAILERPROGDIR]/queue sympa@your.virtual.domain"
listmaster@your.virtual.domain: "| [MAILERPROGDIR]/queue listmaster@your.virtual.domain"
bounce+*@your.virtual.domain:          "| [MAILERPROGDIR]/bouncequeue sympa@your.virtual.domain"\\
\end{verbatim}
\end {quote}

\item Define a \textbf {virtual host in your HTTPD server}. The fastcgi servers defined 
in the common section of you httpd server can be used by each virtual host. You don't 
need to run dedicated fascgi server for each virtual host.

\textit {Examples:} 
\begin {quote}
\begin{verbatim}
FastCgiServer [CGIDIR]/wwsympa.fcgi -processes 3 -idle-timeout 120
.....
<VirtualHost 195.215.92.16>
  ServerAdmin webmaster@your.virtual.domain
  DocumentRoot /var/www/your.virtual.domain
  ServerName your.virtual.domain

  <Location /sympa>
     SetHandler fastcgi-script
  </Location>

  ScriptAlias /sympa [CGIDIR]/wwsympa.fcgi

  Alias /static-sympa [DIR]/your.virtual.domain/static_content

</VirtualHost>
\end{verbatim}
\end {quote}

\item Create a \file {[ETCDIR]/your.virtual.domain/robot.conf} configuration file for the virtual host. Its format is a subset of \file {sympa.conf} and is described in the next section ; a sample \file {robot.conf} is provided.

\item Create a \dir {[EXPL_DIR]/your.virtual.domain/} directory that will contain the virtual host mailing lists directories. This directory should have the  \textit {sympa} user as its owner and must have read and write access for this user.

\begin {quote}
\begin{verbatim}
# su sympa -c 'mkdir [EXPL_DIR]/your.virtual.domain'
# chmod 750 [EXPL_DIR]/your.virtual.domain
\end{verbatim}
\end {quote}


\end {itemize}

\section {robot.conf}
A robot is named by its domain, let's say \samplerobot  and defined by a directory 
\dir {[ETCDIR]/\samplerobot}. This directory must contain at least a 
\file {robot.conf} file. This files has the same format as  \file {[CONFIG]}
(have a look at robot.conf in the sample dir).
Only the following parameters can be redefined for a particular robot :

\begin {itemize}

	\item \cfkeyword {http\_host} \\
	This hostname will be compared with 'SERVER\_NAME' environment variable in wwsympa.fcgi
	to determine the current Virtual Host. You can a path at the end of this parameter if
	you are running multiple virtual hosts on the same host. 
	\begin {quote}
	\begin{verbatim}Examples: \\
	http_host  myhost.mydom
	http_host  myhost.mydom/sympa
	\end{verbatim}
	\end {quote}

	\item \cfkeyword {host} \\
	This is the equivalent of the \cfkeyword {host} sympa.conf parameter.
	The default for this parameter is the name of the virtual host (ie the name of the subdirectory).

	\item \cfkeyword {wwsympa\_url} \\
	The base URL of WWSympa

	\item \cfkeyword {soap\_url} \\
	The base URL of Sympa's SOAP server (if it is running ; see ~\ref {soap}, page~\pageref {soap})

	\item \cfkeyword {cookie\_domain}

	\item \cfkeyword {email}

	\item \cfkeyword {title}

	\item \cfkeyword {default\_home}
	
	\item \cfkeyword {create\_list}

	\item \cfkeyword {lang}
	 
	\item \cfkeyword {supported\_lang}

	\item \cfkeyword {log\_smtp}

	\item \cfkeyword {listmaster}

	\item \cfkeyword {max\_size}

        \item \cfkeyword {css\_path}

        \item \cfkeyword {css\_url}

	\item \cfkeyword {static\_content\_path}

	\item \cfkeyword {static\_content\_url}

	\item \cfkeyword {pictures\_feature}

	\item \cfkeyword {pictures\_max\_size}

        \item \cfkeyword {logo\_html\_definition}

	\item  \cfkeyword {color\_0}, {color\_1} ... {color\_15}

	\item deprecated color definition \cfkeyword {dark\_color}, \cfkeyword {light\_color}, \cfkeyword {text\_color}, \cfkeyword {bg\_color}, \cfkeyword {error\_color}, \cfkeyword {selected\_color}, \cfkeyword {shaded\_color}
 
\end {itemize}

These settings overwrite the equivalent global parameter defined in \file {[CONFIG]}
for \samplerobot robot ; the main \cfkeyword {listmaster} still has privileges on Virtual
Robots though. The http\_host parameter is compared by wwsympa with the SERVER\_NAME
environment variable to recognize which robot is in used. 

\subsection {Robot customization}

In order to customize the web look and feel, you may edit the CSS definition. CSS are defined in a template named css.tt2. Any robot can use static css file for making Sympa web interface faster. Then you can edit this static definition and change web style. Please refer to  \cfkeyword {css\_path} \cfkeyword {css\_url}. You can also quickly introduce a logo in left top corner of all pages configuring \cfkeyword {logo\_html\_definition} parameter in robot.conf file. 

In addition, if needed, you can customize each virtual host using its set of templates and authorization scenarios. 

\dir {[ETCDIR]/\samplerobot/web\_tt2/},
\dir {[ETCDIR]/\samplerobot/mail\_tt2/}, 
\dir {[ETCDIR]/\samplerobot/scenari/} directories are searched when
loading templates or scenari before searching into \dir {[ETCDIR]} and  \dir {[ETCBINDIR]}. This allows to define different privileges and a different GUI for a Virtual Host.

\section {Managing multiple virtual hosts}

If you are managing more than 2 virtual hosts, then you might cinsider moving all the mailing lists in the default
robot to a dedicated virtual host located in the \dir {[EXPL_DIR]/\samplerobot/} directory. The main benefit of 
this organisation is the ability to define default configuration elements (templates or authorization scenarios) 
for this robot without inheriting them within other virtual hosts.

To create such a virtual host, you need to create \dir {[EXPL_DIR]/\samplerobot/} and \file {[ETCDIR]/\samplerobot/} directories ; 
customize \cfkeyword {host}, \cfkeyword {http\_host} and \cfkeyword {wwsympa\_url} parameters in the \file {[ETCDIR]/\samplerobot/robot.conf} 
with the same values as the default robot (as defined in \file {sympa.conf} and \file {wwsympa.conf} files).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Interaction between SYMPA and other applications
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\cleardoublepage
\chapter {Interaction between \Sympa and other applications}
    \label {interaction}

\section {Soap}

See~\ref {soap}, page~\pageref {soap}.

\section {RSS channel}

See \ref {rss}, page~\pageref {rss}. 

\section {Sharing \WWSympa authentication with other applications}

See \ref {sharing-auth}, page~\pageref {sharing-auth}.

\section {Sharing data with other applications}

You may extract subscribers, owners and editors for a list from any of :
\begin{itemize}

\item a text file

\item a Relational database

\item a LDAP directory

\end{itemize}

See \lparam {user\_data\_source} list parameter \ref {user-data-source}, page~\pageref {user-data-source}.

The three tables can have more fields than the one used by \Sympa, by defining these additional fields, they will be available
from within \Sympa's authorization scenarios and templates (see \ref {db-additional-subscriber-fields}, 
page~\pageref {db-additional-subscriber-fields} and \ref {db-additional-user-fields}, page~\pageref {db-additional-user-fields}).

See data inclusion file \ref {data-inclusion-file}, page~\pageref {data-inclusion-file}. 

\section {Subscriber count}
 \label {subscriber-count}
 \index {subscriber\_count}

The number of subscribers of a list can be get from an external application by requesting function 'subscriber\_count' on the Web 
interface.

      \example {http://my.server/wws/subscriber\_count/\samplelist}\\



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Customization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\cleardoublepage
\chapter {Customizing \Sympa/\WWSympa}
    \label {customization}

\section {Template file format}
\label{tpl-format}
\index{templates format}

Template files within \Sympa used to be in a proprietary format that has been
replaced with the \htmladdnormallinkfoot {TT2} {http://www.tt2.org} template format.

You will find detailed documentation about the TT2 syntax on the web site : \textbf {http://www.tt2.org}

Here are some aspects regarding templates that are specific to \Sympa : 
\begin {itemize}

  \item References to PO catalogue are noted with the \textbf {[\% loc \%]} tag that may include 
  parameters. \example {[\%|loc(list.name,list.host)\%]Welcome to list \%1\@\%2[\%END\%]}.

  \item Few exceptions apart, templates cannot insert or parse a file given its full or relative 
   path, for security reason. Only the file name should be provided ; the TT2 parser will then
   use the INCLUDE\_PATH provided by \Sympa to find the relevant file to insert/parse.

  \item The \textbf {qencode} filter should be used if a template includes SMTP header fields
  that should be Q-encoded. \example {[\% FILTER qencode \%]Message à modérer[\%END\%]}

  \item You can write different versions of a template file in different language, each of them 
  being located in a subdirectory of the \textbf {tt2} directory. \example {[ETC_DIR]/mail\_tt2/fr\_FR/helpfile.tt2}

\end {itemize}

\section {Site template files}
\label{site-tpl}
\index{templates, site}

These files are used by Sympa as service messages for the \mailcmd {HELP}, 
\mailcmd {LISTS} and \mailcmd {REMIND *} commands. These files are interpreted 
(parsed) by \Sympa and respect the TT2 template format ; every file has a \textbf {.tt2} extension. 
See \ref {tpl-format}, 
page~\pageref {tpl-format}. 

Sympa looks for these files in the following order (where \texttt{<}list\texttt{>} is the
listname if defined, \texttt{<}action\texttt{>} is the name of the command, and \texttt{<}lang\texttt{>} is
the preferred language of the user) :
\begin {enumerate}
	\item \dir {[EXPL_DIR]/\texttt{<}list\texttt{>}/mail\_tt2/\texttt{<}lang\texttt{>}/\texttt{<}action\texttt{>}.tt2}. 
	\item \dir {[EXPL_DIR]/\texttt{<}list\texttt{>}/mail\_tt2/\texttt{<}action\texttt{>}.tt2}. 
	\item \dir {[ETCDIR]/\samplerobot/mail\_tt2/\texttt{<}lang\texttt{>}/\texttt{<}action\texttt{>}.tt2}. 
	\item \dir {[ETCDIR]/\samplerobot/mail\_tt2/\texttt{<}action\texttt{>}.tt2}. 
	\item \dir {[ETCDIR]/mail\_tt2/\texttt{<}lang\texttt{>}/\texttt{<}action\texttt{>}.tt2}. 
	\item \dir {[ETCDIR]/mail\_tt2/\texttt{<}action\texttt{>}.tt2}. 
	\item \dir {[ETCBINDIR]/mail\_tt2/\texttt{<}lang\texttt{>}/\texttt{<}action\texttt{>}.tt2}.
	\item \dir {[ETCBINDIR]/mail\_tt2/\texttt{<}action\texttt{>}.tt2}.
\end {enumerate}

If the file starts with a From: line, it is considered as
a full message and will be sent (after parsing) without adding SMTP
headers. Otherwise the file is treated as a text/plain message body.

The following variables may be used in these template files :

\begin {itemize}
[STOPPARSE]
	\item[-] [\% conf.email \%] : sympa e-mail address local part

	\item[-] [\% conf.domain \%] : sympa robot domain name

	\item[-] [\% conf.sympa \%] : sympa's complete e-mail address

	\item[-] [\% conf.wwsympa\_url \%] : \WWSympa root URL

	\item[-] [\% conf.listmaster \%] : listmaster e-mail addresses

	\item[-] [\% user.email \%] : user e-mail address

	\item[-] [\% user.gecos \%] : user gecos field (usually his/her name)

	\item[-] [\% user.password \%] : user password

	\item[-] [\% user.lang \%] : user language	
\end {itemize}

\subsection {helpfile.tt2} 


	This file is sent in response to a \mailcmd {HELP} command. 
	You may use additional variables
\begin {itemize}

	\item[-] [\% is\_owner \%] : TRUE if the user is list owner

	\item[-] [\% is\_editor \%] : TRUE if the user is list editor

\end {itemize}

\subsection {lists.tt2} 

	File returned by \mailcmd {LISTS} command. 
	An additional variable is available :
\begin {itemize}

	\item[-] [\% lists \%] : this is a hash table indexed by list names and
			containing lists' subjects. Only lists visible
			to this user (according to the \lparam {visibility} 
			list parameter) are listed.
\end {itemize}

\textit {Example:} 

\begin {quote}
\begin{verbatim}
These are the public lists for [conf->email]@[conf->domain]

[% FOREACH l = lists %]
[% l.key %]@[% l.value.host %] : [% l.value.subject %]

[% END %]

\end{verbatim}
\end {quote}

\subsection {global\_remind.tt2} 

	This file is sent in response to a \mailcmd {REMIND *} command. 
	(see~\ref {cmd-remind}, page~\pageref {cmd-remind})
	You may use additional variables
\begin {itemize}

	\item[-] [\% lists \%] : this is an array containing the list names the user
			is subscribed to.
\end {itemize}

\textit {Example:} 

\begin {quote}
\begin{verbatim}

This is a subscription reminder.

You are subscribed to the following lists :
[% FOREACH l = lists %]
	
 [% l %] : [% conf.wwsympa\_url \%]/info/[% l %]

[% END %]

Your subscriber e-mail : [% user.email %]
Your password : [% user.password %]

\end{verbatim}
\end {quote}

\subsection {your\_infected\_msg.tt2} 

This message is sent to warn the sender of a virus infected mail,
indicating the name of the virus found 
(see~\ref {Antivirus}, page~\pageref {Antivirus}).
[STARTPARSE]

\section {Web template files}
\label{web-tpl}
\index{templates, web}

You may define your own web template files, different from the standard
ones. \WWSympa first looks for list specific web templates, then for
site web templates, before falling back on its defaults. 

Your list web template files should be placed in the \dir {[EXPL_DIR]/\samplelist/web\_tt2} 
directory ; your site web templates in \tildedir {[ETCDIR]/web\_tt2} directory.

Note that web colors are defined in \Sympa's main Makefile (see \ref {makefile},
page~\pageref {makefile}).


\section {Internationalization}
\label {internationalization}
\index{internationalization}
\index{localization}

\Sympa was originally designed as a multilingual Mailing List
Manager. Even in its earliest versions, \Sympa separated messages from
the code itself, messages being stored in NLS catalogues (according 
to the XPG4 standard). Later a \lparam{lang} list parameter was introduced.
Nowadays \Sympa is able to keep track of individual users' language preferences.

If you are willing to provide Sympa into your native language, please check the \textbf {translation howto} (\htmladdnormallink {\texttt {http://www.sympa.org/howtotranslate.html}}  {http://www.sympa.org/howtotranslate.html});

\subsection {\Sympa internationalization}

Every message sent by \Sympa to users, owners and editors is outside
the code, in a message catalog. These catalogs are located in the
\dir {[LOCALEDIR]} directory. 
%Messages have currently been translated into 14 different languages : 
%
%\begin{itemize}
%
%\item cn-big5: BIG5 Chinese (Hong Kong, Taiwan)
%
%\item cn-gb: GB Chinese (Mainland China)
%
%\item cz: Czech
%
%\item de: German
%
%\item es: Spanish
%
%\item fi: Finnish
%
%\item fr: French
%
%\item hu: Hungarian
%
%\item it: Italian
%
%\item pl: Polish
%
%\item us: US English
%
%\end{itemize}

To tell \Sympa to use a particular message catalog, you can should set 
the \cfkeyword{lang} parameter in \file{sympa.conf}.

\subsection {List internationalization}

The \lparam{lang} list parameter defines the language for a list.
It is currently used by \WWSympa and to initialize users'
language preferences at subscription time.

In future versions, all messages returned by \Sympa concerning
a list should be in the list's language. 

\subsection {User internationalization}

The user language preference is currently used by \WWSympa
only. There is no e-mail-based command for a user to set his/her
language. The language preference is initialized when the user
subscribes to his/her first list. \WWSympa allows the user to change 
it.

\section {Topics}
\label{topics}
\index{topics}

\WWSympa's homepage shows a list of topics for classifying
mailing lists. This is dynamically generated using the different lists'
\lparam {topics} configuration parameters. A list may appear 
in multiple categories (This parameter is different from \lparam{msg\_topic}
used to tag list messages)

The list of topics is defined in the \file {topics.conf} configuration
file, located in the \dir {[ETCDIR]} directory. The format of this file is 
as follows :
\begin {quote}
\begin{verbatim}
<topic1_name>
title	<topic1 title>
title.fr <topic french title>
visibility <topic1 visibility>
....
<topicn_name/subtopic_name>
title	<topicn title>
title.de <topicn german title>
\end{verbatim}
\end {quote}

You will notice that subtopics can be used, the separator being \textit {/}.
The topic name is composed of alphanumerics (0-1a-zA-Z) or underscores (\_).
The order in which the topics are listed is respected in \WWSympa's homepage.
The \textbf {visibility} line defines who can view the topic (now available for subtopics).
It refers to the associated topics\_visibility authorization scenario.
You will find a sample \file {topics.conf} in the \dir {sample} 
directory ; NONE is installed as the default. 

A default topic is hard-coded in \Sympa : \textit {default}. This default topic
contains all lists for which a topic has not been specified.

\section {Authorization scenarios}

See \ref {scenarios}, page~\pageref {scenarios}.

\section {Loop detection}
    \label {loop-detection}
    \index{loop-detection}

\Sympa uses multiple heuristics to avoid loops in Mailing lists

First, it rejects messages coming from a robot (as indicated by the
From: and other header fields), and messages containing commands.

Secondly, every message sent by \Sympa includes an X-Loop header field set to
the listname. If the message comes back, \Sympa will detect that
it has already been sent (unless X-Loop header fields have been
erased).

Thirdly, \Sympa keeps track of Message IDs and will refuse to send multiple
messages with the same message ID to the same mailing list.

Finally, \Sympa detect loops arising from command reports (i.e. sympa-generated replies to commands). 
This sort of loop might occur as follows:

\begin {quote}
\begin{verbatim}
1 - X sends a command to Sympa
2 - Sympa sends a command report to X
3 - X has installed a home-made vacation program replying to programs
4 - Sympa processes the reply and sends a report
5 - Looping to step 3
\end{verbatim}
\end {quote}

\Sympa keeps track (via an internal counter) of reports sent to any particular address.
The loop detection algorithm is :

\begin {itemize}

	\item Increment the counter

	\item If we are within the sampling period (as defined by the
	\cfkeyword {loop\_command\_sampling\_delay} parameter)

	\begin {itemize}
		\item If the counter exceeds the 
		\cfkeyword {loop\_command\_max} parameter, then 
		do not send the report, and notify the listmaster

		\item Else, start a new sampling period and reinitialize
		the counter,  i.e. multiply it by the 
		\cfkeyword {loop\_command\_decrease\_factor} parameter
	\end {itemize}


\end {itemize}

\section {Tasks}
    \label {tasks}
    \index{tasks}

A task is a sequence of simple actions which realize a complex routine. It is executed in background 
by the task manager daemon and allow the list master to automate the processing of recurrent tasks. 
For example a task sends every year the subscribers of a list a message to remind their subscription. 

A task is created with a task model. It is a text file which describes a sequence of simple actions. 
It may have different versions (for instance reminding subscribers every year or semester).
A task model file name has the following format : \file {\texttt{<}model name\texttt{>}.\texttt{<}model version\texttt{>}.task}.
For instance \file {remind.annual.task}  or \file {remind.semestrial.task}.

\Sympa provides several task models stored in \dir {[ETCBINDIR]/global\_task\_models} 
  and \dir {[ETCBINDIR]/list\_task\_models} directories.
Others can be designed by the listmaster. 

A task is global or related to a list.

\subsection {List task creation}

You define in the list config file the model and the version you want to use (see 
\ref {list-task-parameters}, page~\pageref {list-task-parameters}). Then the task manager daemon will automatically 
create the task by looking for the appropriate model file in different directories in the
following order :

\begin {enumerate}
	\item \dir {[EXPL_DIR]/\texttt{<}list name\texttt{>}/}
	\item \dir {[ETCDIR]/list\_task\_models/}
	\item \dir {[ETCBINDIR]/list\_task\_models/}
\end {enumerate}
  
See also \ref {Listmodelfiles}, page~\pageref {Listmodelfiles}, to know more about standard list models provided with \Sympa.

\subsection {Global task creation}

The task manager daemon checks if a version of a global task model is specified in \file {sympa.conf} 
and then creates a task as soon as it finds the model file by looking in different directories
in the following order :

\begin {enumerate}
	\item \dir {[ETCDIR]/global\_task\_models/}
	\item \dir {[ETCBINDIR]/global\_task\_models/}
\end {enumerate}

\subsection {Model file format}

Model files are composed of comments, labels, references, variables, date values
and commands. All those syntactical elements are composed of alphanumerics (0-9a-zA-Z) and underscores (\_).

\begin {itemize}
[STOPPARSE]
\item Comment lines begin by '\#' and are not interpreted by the task manager.
\item Label lines begin by '/' and are used by the next command (see below).
\item References are enclosed between brackets '[]'. They refer to a value 
depending on the object of the task (for instance [list-\texttt{>}name]). Those variables
are instantiated when a task file is created from a model file. The list of available 
variables is the same as for templates (see \ref {list-tpl}, see 
page~\pageref {list-tpl}) plus [creation\_date] (see below).
\item Variables store results of some commands and are paramaters for others.
Their name begins with '@'.
\item A date value may be written in two ways :

	\begin {itemize}
		\item absolute dates follow the format : xxxxYxxMxxDxxHxxMin. Y is the year, 
		M the month (1-12), D the day (1-28\texttt{|}30\texttt{|}31, leap-years are not managed),
		H the hour (0-23), Min the minute (0-59). H and Min are optionnals.
		For instance, 2001y12m4d44min is the 4th of December 2001 at 00h44.
 
		\item relative dates use the [creation\_date] or [execution\_date] references. 
		[creation\_date] is the date when the task file is created, [execution\_date] 
		when the command line is executed.
		A duration may follow with '+' or '-' operators. The duration is expressed 
		like an absolute date whose all parameters are optionnals. 	
		Examples : [creation\_date], [execution\_date]+1y, [execution\_date]-6m4d
	\end {itemize}


\item Command arguments are separated by commas and enclosed between parenthesis '()'.
\end {itemize}

Here is the list of current avalable commands :
\begin {itemize}
\item stop ()

	Stops the execution of the task and delete the task file
\item next (\texttt{<}date value\texttt{>}, \texttt{<}label\texttt{>})

	Stop the execution. The task will go on at the date value and begin at the label line.
\item \texttt{<}{\at}deleted\_users\texttt{>} = delete\_subs (\texttt{<}{\at}user\_selection\texttt{>})

	Delete @user\_selection email list and stores user emails successfully deleted in @deleted\_users.
\item send\_msg (\texttt{<}{\at}user\_selection\texttt{>}, \texttt{<}template\texttt{>})

	Send the template message to emails stored in @user\_selection.
\item {\at}user\_selection = select\_subs (\texttt{<}condition\texttt{>})

	Store emails which match the condition in @user\_selection. See 8.6 Authorization Scenarios section to know how to write conditions. Only available for list models.
\item create (global | list (\texttt{<}list name\texttt{>}), \texttt{<}model type\texttt{>}, \texttt{<}model\texttt{>})

	Create a task for object with model file \tildefile {model type.model.task}.
\item chk\_cert\_expiration (\texttt{<}template\texttt{>}, \texttt{<}date value\texttt{>})

	Send the template message to emails whose certificate has expired or will expire before the date value.
\item update\_crl (\texttt{<}file name\texttt{>}, \texttt{<}date value\texttt{>})

	Update certificate revocation lists (CRL) which are expired or will expire before the date value. The file stores the CRL's URLs.

\item purge\_orphan\_bounces()

        Clean bounces by removing unsubscribed-users archives.

\item eval\_bouncers()

        Evaluate all bouncing users of all list and give them a score from 0 to 100. (0 = no bounces for this user, 100 is for users who should be removed).

\item process\_bouncers()

        Execute actions defined in list configuration on each bouncing users, according to their score.
\end {itemize}

Model files may have a scenario-like title line at the beginning.
 
When you change a configuration file by hand, and a task parameter is created or modified, it is up to you
to remove existing task files in the \dir {task/} spool if needed. Task file names have the following format : 

\file {\texttt{<}date\texttt{>}.\texttt{<}label\texttt{>}.\texttt{<}model name\texttt{>}.\texttt{<}list name | global\texttt{>}} where :

\begin {itemize}
	\item date is when the task is executed, it is an epoch date
	\item label states where in the task file the execution begins. If empty, starts at the beginning 
\end {itemize}

 [STARTPARSE]

\subsection {Model file examples}

\begin {itemize}
\item remind.annual.task
	\label {remind-annual-task}
	\begin {quote}
	\begin{verbatim}
	[INCLUDE '../src/etc/list_task_models/remind.annual.task']
	\end{verbatim}
	\end {quote}


\item expire.annual.task
	\label {expire-annual-task}
	\begin {quote}
	\begin{verbatim}
	[INCLUDE '../src/etc/list_task_models/expire.annual.task']
	\end{verbatim}
	\end {quote}


\item crl\_update.daily.task\\
	\begin {quote}
	\begin{verbatim}
	[INCLUDE '../src/etc/global_task_models/crl_update.daily.task']
	\end{verbatim}
	\end {quote}

\end{itemize}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Mailing list definition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\cleardoublepage
\chapter {Mailing list definition}
    \label {ml-definition}

This chapter describes what a mailing list is made of within Sympa environment.

\section {Mail aliases}
    \label {list-aliases}
    \index{aliases}
    \index{mail aliases}

See list aliases section, \ref {list-aliases},
page~\pageref {list-aliases})

\section {List configuration file}
    \label {exp-config}

The configuration file for the \mailaddr {\samplelist} list is named
\file {[EXPL_DIR]/\samplerobot/\samplelist/config} 
(or \file {[EXPL_DIR]/\samplelist/config} if no virtual host is defined). 
\Sympa reloads it into memory whenever this file has changed on disk. The file can either be
edited via the web interface or directly via your favourite text editor. 

If you have set the \cfkeyword {cache\_list\_config} sympa.conf parameter (see \ref {cache-list},  
page~\pageref {cache-list}), a binary version of the config (\file {[EXPL_DIR]/\samplerobot/\samplelist/config.bin} is maintained to allow 
a faster restart of daemons (this is especialy usefull for sites managing lots of lists). 

Be careful to provide read access for \Sympa user to this file !

You will find a few configuration files in the \dir {sample} directory. 

List configuration parameters are described in the list creation section, \ref {list-configuration-param}, page~\pageref {list-configuration-param}.

\section {Examples of configuration files}

This first example is for a list open to everyone:

\begin {quote}
\begin{verbatim}
subject First example (an open list)

visibility noconceal

owner
email Pierre.David@prism.uvsq.fr

send public

review public
\end{verbatim}
\end {quote}

The second example is for a moderated list with authenticated subscription:
\index{moderation}
\index{authentication}

\begin {quote}
\begin{verbatim}
subject Second example (a moderated list)

visibility noconceal

owner
email moi@ici.fr

editor
email big.prof@ailleurs.edu

send editor

subscribe auth

review owner

reply_to_header
value list

cookie 142cleliste
\end{verbatim}
\end {quote}

The third example is for a moderated list, with subscription
controlled by the owner, and running in digest mode. Subscribers
who are in \textindex {digest} mode receive messages on Mondays and
Thursdays.

\begin {quote}
\begin{verbatim}
owner
email moi@ici.fr

editor
email prof@ailleurs.edu

send editor

subscribe owner

review owner

reply_to_header
value list

digest 1,4 12:00
\end{verbatim}
\end {quote}

\section {Subscribers file}
    \label {file-subscribers}
    \index{subscriber file}

\textbf {Be carefull}: Since version 3.3.6 of \Sympa, a RDBMS is required for internal data storage. Flat file should
not be use anymore except for testing purpose. \Sympa will not use this file if the list is configured
with \texttt {include} or \texttt {database} \lparam{user\_data\_source}.

The \file {[EXPL_DIR]/\samplelist/subscribers} file is automatically created and
populated. It contains information about list
subscribers.  It is not advisable to edit this file.  Main parameters
are:

\begin {itemize}
    \item \lparam {email} \textit {address}

        E-mail address of subscriber.

    \item  \lparam {gecos} \textit {data} 

        Information about subscriber (last name, first name,
        etc.) This parameter is optional at subscription time.

    \item \lparam {reception}
            \texttt {nomail} \texttt{|}
            \texttt {digest} \texttt{|}
            \texttt {summary} \texttt{|}
            \texttt {notice} \texttt{|}
 	    \texttt {txt} \texttt{|}
	    \texttt {html} \texttt{|}
 	    \texttt {urlize} \texttt{|}
	    \texttt {not\_me} \texttt{|}
        \label {par-reception} 

        Special receive modes which the subscriber may select.
        Special modes can be either \textit {nomail},  \textit
        {digest}, \textit {summary}, \textit {notice}, \textit {txt},
        \textit {html}, \textit {urlize}, \textit {not\_me} .
        In normal receive mode, the receive attribute
        for a subscriber is not displayed. In this mode subscription to message topics is available.
        See the \mailcmd {SET~LISTNAME~SUMMARY} (\ref {cmd-setsummary}, 
        page~\pageref {cmd-setsummary}),
        the \mailcmd {SET~LISTNAME~NOMAIL} command (\ref {cmd-setnomail},
        page~\pageref {cmd-setnomail}), and the \lparam {digest}
        parameter (\ref {par-digest}, page~\pageref {par-digest}).

    \item \lparam {visibility} \texttt {conceal}  
        \label {par-visibility-conceal}

        Special mode which allows the subscriber to remain invisible when
        a \mailcmd {REVIEW} command is issued for the list.  If this
        parameter is not declared, the subscriber will be visible
        for \mailcmd {REVIEW}.  Note: this option does not affect
        the results of a \mailcmd {REVIEW} command issued by an
        owner.  See the \mailcmd {SET~LISTNAME~MAIL} command (\ref
        {cmd-setconceal}, page~\pageref {cmd-setconceal}) for
        details.

\end {itemize}


\section {Info file}

\file {[EXPL_DIR]/\samplelist/info} should contain a detailed text
description of the list, to be displayed by the \mailcmd {INFO} command. 
It can also be referenced from template files for service messages.

\section {Homepage file}

\file {[EXPL_DIR]/\samplelist/homepage} is the HTML text 
on the \WWSympa info page for the list.

\section {Data inclusion file}
\label{data-inclusion-file}
\index{data-inclusion-file}

Sympa will use these files only if the list is configured in \texttt {include2} \lparam{user\_data\_source} mode.
Every file has the .incl extension. 
More over, these files must be declared in paragraphs \lparam {owner\_include} or \lparam {editor\_inlude} in the list configuration file 
without the .incl extension (see \ref {list-configuration-param}, page~\pageref {list-configuration-param}).
This files can be template file.

Sympa looks for them in the following order :
\begin {enumerate}
 	\item \dir {[EXPL_DIR]/\samplelist/data\_sources/\texttt{<}file\texttt{>}.incl}. 
	\item \dir {[ETCDIR]/data\_sources/\texttt{<}file\texttt{>}.incl}. 
	\item \dir {[ETCDIR]/\samplerobot/data\_sources/\texttt{<}file\texttt{>}.incl}.
\end {enumerate} 

These files are used by Sympa to load administrative data in a relational database :
Owners or editors are defined \emph {intensively} (definition of criteria owners or editors must satisfy).  
Includes can be performed by extracting e-mail addresses using an \textindex {SQL} or \textindex {LDAP} query, or 
by including other mailing lists.

A data inclusion file is composed of paragraphs separated by blank lines and introduced by a keyword.
Valid paragraphs are \lparam {include\_file}, \lparam {include\_list}, \lparam {include\_remote\_sympa\_list}, 
\lparam {include\_sql\_query} and \lparam {include\_ldap\_query}. They are described in the list configuration parameters chapitre, \ref {list-configuration-param}, page~\pageref {list-configuration-param}.

When this file is a template, used variables are array elements (\file {param} array). This array is instantiated by values contained in the subparameter 
\lparam {source\_parameter} of \lparam {owner\_include} or \lparam {editor\_inlude}.

\textit {Example :} 

\begin{itemize}
  \item in the list configuration file :

    \begin {quote}
      \begin{verbatim}
	owner_include
	source myfile
	source_parameters mysql,rennes1,stduser,mysecret,studentbody,student
      \end{verbatim}
    \end {quote}
    
  \item in myfile.incl :
    
    \begin {quote}
      \begin{verbatim}
	include_sql_query
	db_type [% param.0 %]
	host sqlserv.admin.univ-[% param.1 %].fr
	user [% param.2 %]
	passwd [% param.3 %]
        db_name [% param.4 %]
	sql_query SELECT DISTINCT email FROM [% param.5 %]
      \end{verbatim}
    \end {quote}
    
  \item resulting data inclusion file :
    
    \begin {quote}
      \begin{verbatim}
	include_sql_query
	db_type mysql
	host sqlserv.admin.univ-rennes1.fr
        user stduser
        passwd mysecret
        db_name studentbody
        sql_query SELECT DISTINCT email FROM student
     \end{verbatim}
    \end {quote}

\end{itemize}          



\section {List template files}
\label{list-tpl}
\index{templates, list}

These files are used by Sympa as service messages for commands such as
\mailcmd {SUB}, \mailcmd {ADD}, \mailcmd {SIG}, \mailcmd {DEL}, \mailcmd {REJECT}. 
These files are interpreted (parsed) by \Sympa and respect the template 
format ; every file has the .tt2 extension. See \ref {tpl-format}, 
page~\pageref {tpl-format}. 

Sympa looks for these files in the following order :
\begin {enumerate}
 	\item \dir {[EXPL_DIR]/\samplelist/mail\_tt2/\texttt{<}file\texttt{>}.tt2} 
	\item \dir {[ETCDIR]/mail\_tt2/\texttt{<}file\texttt{>}.tt2}. 
	\item \dir {[ETCBINDIR]/mail\_tt2/\texttt{<}file\texttt{>}.tt2}.
\end {enumerate}

If the file starts with a From: line, it is taken to be
a full message and will be sent (after parsing) without the addition of SMTP
headers. Otherwise the file is treated as a text/plain message body.

The following variables may be used in list template files :

\begin {itemize}
[STOPPARSE]
	\item[-] [\% conf.email \%] : sympa e-mail address local part

	\item[-] [\% conf.domain \%] : sympa robot domain name

	\item[-] [\% conf.sympa \%] : sympa's complete e-mail address

	\item[-] [\% conf.wwsympa\_url \%] : \WWSympa root URL

	\item[-] [\% conf.listmaster \%] : listmaster e-mail addresses

	\item[-] [\% list.name \%] : list name

	\item[-] [\% list.host \%] : list hostname (default is sympa robot domain name)

	\item[-] [\% list.lang \%] : list language

	\item[-] [\% list.subject \%] : list subject

	\item[-] [\% list.owner \%] : list owners table hash

	\item[-] [\% user.email \%] : user e-mail address

	\item[-] [\% user.gecos \%] : user gecos field (usually his/her name)

	\item[-] [\% user.password \%] : user password

	\item[-] [\% user.lang \%] : user language

	\item[-] [\% execution\_date \%] : the date when the scenario is executed	
\end {itemize}

You may also dynamically include a file from a template using the
[\% INSERT \%] directive.


\textit {Example:} 

\begin {quote}
\begin{verbatim}
Dear [% user.email %],

Welcome to list [% list.name %]@[% list.host %].

Presentation of the list :
[% INSERT 'info' %]

The owners of [% list.name %] are :
[% FOREACH ow = list.owner %]
   [% ow.value.gecos %] <[% ow.value.email %]>
[% END %]


\end{verbatim}
\end {quote}

\subsection {welcome.tt2} 

\Sympa will send a welcome message for every subscription. The welcome 
message can be customized for each list.

\subsection {bye.tt2} 

Sympa will send a farewell message for each SIGNOFF 
mail command received.

\subsection {removed.tt2} 

This message is sent to users who have been deleted (using the \mailcmd {DELETE} 
command) from the list by the list owner.


\subsection {reject.tt2} 

\Sympa will send a reject message to the senders of messages rejected
by the list editor. If the editor prefixes her \mailcmd {REJECT} with the
keyword QUIET, the reject message will not be sent.


\subsection {invite.tt2} 

This message is sent to users who have been invited (using the \mailcmd {INVITE} 
command) to subscribe to a list. 

You may use additional variables
\begin {itemize}

	\item[-] [\% requested\_by \%] : e-mail of the person who sent the 
		\mailcmd{INVITE} command

	\item[-] [\% url \%] : the mailto: URL to subscribe to the list

\end {itemize}

\subsection {remind.tt2}

This file contains a message sent to each subscriber
when one of the list owners sends the \mailcmd {REMIND} command
 (see~\ref {cmd-remind}, page~\pageref {cmd-remind}).

\subsection {summary.tt2}

Template for summaries (reception mode close to digest), 
see~\ref {cmd-setsummary}, page~\pageref {cmd-setsummary}.

\subsection {list\_aliases.tt2}
\label{list-aliases-tpl}

Template that defines list mail alises. It is used by the alias\_manager script.

[STARTPARSE]

\section {Stats file}
    \label {stats-file}
    \index{statistics}

\file {[EXPL_DIR]/\samplelist/stats} is a text file containing 
statistics about the list. Data are numerics separated
by white space within a single line :

\begin {itemize}

	\item Number of messages sent, used to generate X-sequence headers

	\item Number of messages X number of recipients 

	\item Number of bytes X number of messages

	\item Number of bytes X number of messages X number of recipients

	\item Number of subscribers

	\item Last update date (epoch format) of the subscribers cache in DB, used by lists in \textbf {include2} mode only

\end {itemize}

\section {List model files}
\label {Listmodelfiles}

These files are used by \Sympa to create task files. They are interpreted (parsed) 
by the task manager and respect the task format. See \ref {tasks}, page~\pageref {tasks}.

\subsection {remind.annual.task}

Every year \Sympa will send a message (the template \file {remind.tt2}) 
to all subscribers of the list to remind them of their subscription.

\subsection {expire.annual.task}

Every month \Sympa will delete subscribers older than one year who haven't answered two warning messages.

\section {Message header and footer} 
\label {messagefooter}

You may create \file {[EXPL_DIR]/\samplelist/message.header} and
\file {[EXPL_DIR]/\samplelist/message.footer} files. Their content
is added, respectively at the beginning and at the end of each message 
before the distribution process. You may also include the content-type
of the appended part (when \lparam {footer\_type} list parameter s set 
to \textbf {mime}) by renaming the files to \file {message.header.mime} 
and \file {message.footer.mime}.

The \lparam {footer\_type} list parameter defines whether to attach the 
header/footer content as a MIME part (except for multipart/alternative 
messages), or to append them to the message body (for text/plain messages).

Under certain circumstances, Sympa will NOT add headers/footers, here is its
algorythm :
\begin {quote}
\begin{verbatim}
if message is not multipart/signed 
        if footer_type==append
	        if message is text/plain
		       append header/footer to it
		else if message is multipart AND first part is text/plain
		       append header/footer to first part

        if footer_type==mime
	        if message is not multipart/alternative
		       add header/footer as a new MIME part
\end{verbatim}
\end {quote}

\subsection {Archive directory} 

The \dir {[EXPL_DIR]/\samplelist/archives/} directory contains the 
archived messages for lists which are archived; see \ref {par-archive}, 
page~\pageref {par-archive}. The files are named in accordance with the 
archiving frequency defined by the \lparam {archive} parameter.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% List creation, edition and removal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\cleardoublepage
\chapter {List creation, edition and removal}
    \label {ml-creation}

The list creation can be done by two ways, according to listmaster 
needs : 
\begin{itemize}
  \item instanciation family to create and manage large number of related lists. 
    In this case, lists are linked to their family all along their life (Moreover
    you can let sympa automatically create lists when needed.
    See \ref {automatic-list-creation}, page~\pageref {automatic-list-creation}).    
  \item command line creation of individual list with \file {sympa.pl} or on the Web 
interface according to privileges defined by listmasters. Here lists are free from 
their model creation.
\end{itemize} 
Management of mailing lists by list owners is usually done via the Web interface : 
when a list is created, whatever its status (\cfkeyword {pending} or \cfkeyword {open}), the owner 
can use WWSympa admin features to modify list parameters, or to edit the welcome 
message, and so on.

WWSympa keeps logs of the creation and all modifications to a list as part of the list's
\file {config} file (old configuration files are archived).
A complete installation requires some careful planning, although default
values should be acceptable for most sites.

\section {List creation}
    \label{list-creation}

Mailing lists can have many different uses. \Sympa offers a
wide choice of parameters to adapt a list behavior
to different situations. Users might have difficulty selecting all the
correct parameters to make the list configuration, so instead of selecting each 
parameters, list configuration is made with a list profile. This is an 
almost complete list configuration, but with a number of unspecified fields
(such as owner e-mail) to be replaced by \Sympa at list creation time. It is easy to create new list 
templates by modifying existing ones. (Contributions to the distribution are welcome...)

\subsection {Data for list creation}

To create a list, some data concerning list parameters are required : 
\begin{itemize}
  \item \textbf{listname } : name of the list,
  \item \textbf{subject} : subject of the list (a short description),
  \item \textbf{owner(s)} : by static definition and/or dynamic definition.
    In case of static definition, the parameter \textbf{owner} and its subparameter \textbf{email} are required.
    For dynamic definition, the parameter  \textbf{owner\_include} and its subparameter \textbf{source} are required, 
    indicating source file of data inclusion.
  \item \textbf{list creation template} : the typical list profile.
\end{itemize}

Moreover of these required data, provided values are assigned to vars being in the list creation template. 
Then the result is the list configuration file :\\

% \centerline{\includegraphics*[width=13cm]{/tmp/creation.jpg}} 

On the Web interface, these data are given by the list creator in the web form. On command line these 
data are given by an xml file.

\subsection {XML file format}
\label{xml-file-format}

The xml file provides information on :\\
\begin{itemize}
  \item the list name,
  \item values to assign vars in the list creation template
  \item the list description in order to be written in the list file info
  \item the name of the list creation template (only for list creation on command line with sympa.pl, in a family context, the template is specified by the family name)
\end{itemize}

Here is an example of XML document that you can map with the following example of list creation template.:

\begin {quote}
\begin{verbatim}
<?xml version="1.0" ?>
<list>
	<listname>example</listname>
  	<type>my_profile</type>
  	<subject>a list example</subject>
  	<description/>
  	<status>open</status>
  	<shared_edit>editor</shared_edit>
    	<shared_read>private</shared_read>
	<language>fr</language>
	<owner multiple="1"> 
	   <email>serge.aumont@cru.fr</email>
	   <gecos>C.R.U.</gecos>
	</owner>
	<owner multiple="1"> 
	   <email>olivier.salaun@cru.fr</email>
	</owner>
	<owner_include multiple="1">
	   <source>my_file</source>
	</owner_include>
	<sql> 
	   <type>oracle</type>
	   <host>sqlserv.admin.univ-x.fr</host>
	   <user>stdutilisateur</user>
	   <pwd>monsecret</pwd>
	   <name>les_etudiants</name>
	   <query>SELECT DISTINCT email FROM etudiant</query>
	</sql>
</list>



[STOPPARSE]
subject [% subject %]

status [% status %]

[% IF topic %]
topics [% topic %]

[% END %]
visibility noconceal

send privateoreditorkey

Web_archive
  access public

subscribe open_notify

shared_doc
  d_edit [% shared_edit %]
  d_read [% shared_read %]

lang [% language %]

[% FOREACH o = owner %]
owner
  email [% o.email %]
  profile privileged
  [% IF o.gecos %] 
  gecos [% o.gecos %]
  [% END %]

[% END %]
[% IF moderator %]
   [% FOREACH m = moderator %]
editor
  email [% m.email %]

   [% END %]
[% END %]
 
[% IF sql %]
include_sql_query
  db_type [% sql.type %]
  host [% sql.host %]
  user [% sql.user %]
  passwd [% sql.pwd %]
  db_name [% sql.name %]
  sql_query [% sql.query %]
    
[% END %]
ttl 360
[STARTPARSE]
\end{verbatim}
\end {quote}
 

The XML file format should comply with the following rules : 
\begin{itemize}
  \item The root element is \file{<list>}
  \item One XML element is mandatory : \file{<listname>} contains the name of the list.
        That not excludes mandatory parameters for list creation (\lparam {listname, subject,owner.email and/or 
	owner\_include.source}).
  \item \file{<type>} : this element contains the name of template list creation, it is used for list creation on command line with sympa.pl.
        In a family context, this element is no used.
  \item \file{<description>} : the text contained in this element is written in list \file{info} file(it can be a CDATA section).
  \item For other elements, its name is the name of the var to assign in the list creation template. 
  \item Each element concerning multiple parameters must have the \file{multiple} attribute set 
    to ``1'', example : \file{<owner multiple=''1''>}. 
  \item For composed and multiple parameters, sub-elements are used. Example for \file{owner} parameter :
    \file{<email>} and \file{<gecos>} elements are contained in the \file{<owner>}element. 
    An element can only have homogeneous content.
  \item A list requires at least one owner, defined in the XML input file with one of the following elements :
    \begin{itemize}
      \item \file{<owner multiple=''1''> <email> ... </email> </owner>}
      \item \file{<owner\_include multiple=''1''> <source> ... </source> </owner\_include>}
    \end{itemize}
\end{itemize}
   

\section {List families}

See chapter \ref{lists-families}, page~\pageref{lists-families}

\section {List creation on command line with \file {sympa.pl}}
    \label {list-creation-sympa}

This way to create lists is independent of family. 

Here is a sample command to create one list :.
\begin {quote}
sympa.pl --create\_list --robot \samplerobot --input\_file /path/to/my\_file.xml
\end {quote}

The list is created under the \file{my\_robot} robot and the list 
is described in the file \file{my\_file.xml}. The XML file is 
described before, see \ref{xml-file-format}, page~\pageref{xml-file-format}.

By default, the status of the created list is \file{open}.

\subsubsection {typical list profile (list template creation)}
    \label{typical-list-profile}

The list creator has to choose a profile
for the list and put its name in the XML element \file{<type>}.

List profiles are stored in \dir {[ETCDIR]/create\_list\_templates} or in
\dir {[ETCBINDIR]/create\_list\_templates} (default of distrib).

You might want to hide or modify profiles (not useful, or dangerous 
for your site). If a profile exists both in the local site directory
\dir {[ETCDIR]/create\_list\_templates} and
\dir {[ETCBINDIR]/create\_list\_templates} directory, then the local profile 
will be used by WWSympa. 


\section {Creating and editing mailing using the web}
    \label {web-ml-creation}

The management of mailing lists is based on a strict definition of privileges 
which pertain respectively to the listmaster, to the main list owner, and to 
basic list owners. The goal is to allow each listmaster to define who can create 
lists, and which parameters may be set by owners.

\subsection {List creation on the Web interface}

Listmasters are responsible for validating new mailing lists and, depending on the configuration chosen, 
might be the only ones who can fill out the create list form.The listmaster
is defined in \file {sympa.conf} and others are defined at the virtual host level. By default, any authenticated user can 
request a list creation but newly created are then validated by the listmaster. 

List rejection message and list creation notification message are both
templates that you can customize (\file {list\_rejected.tt2} and
\file {list\_created.tt2}).

\subsection {Who can create lists on the Web interface}

This is defined by the \cfkeyword {create\_list} sympa.conf parameter (see \ref {create-list},  
page~\pageref {create-list}). This parameter refers to a \textbf {create\_list} authorization scenario.
It will determine if the \textit {create list} button is displayed and if it requires
a listmaster confirmation.

[STOPPARSE]
The authorization scenario can accept any condition concerning the [sender]
(i.e. WWSympa user), and it returns \cfkeyword {reject}, \cfkeyword {do\_it}
or \cfkeyword {listmaster} as an action.
[STARTPARSE]

Only in cases where a user is authorized by the create\_list authorization scenario
will the "create" button be available in the main menu.
If the scenario returns \cfkeyword {do\_it}, the list will be created and installed.
If the scenario returns "listmaster", the user is allowed to create a list, but
the list is created with the \cfkeyword {pending} status,
which means that only the list owner may view or use it.
The listmaster will need to open the list of pending lists
using the "pending list" button in the "server admin"
menu in order to install or refuse a pending list.

\subsection {typical list profile and Web interface}
As on command line creation, the list creator has to choose a list profile and to fill in the owner's e-mail 
and the list subject together with a short description. But in this case, you don't need any XML file. Concerning
these typical list profiles, they are described before, see \ref{typical-list-profile}, page~\pageref{typical-list-profile}. 
You can check available profile. On the Web interface, another way 
to control publicly available profiles is to
edit the \cfkeyword {create\_list.conf} file (the default for this file is in
the \dir {[ETCBINDIR]} directory, and you may create your own customized
version in \dir {[ETCDIR]}).
This file controls which of the available list templates are to be displayed. Example :
\begin {quote}
\begin{verbatim}
# Do not allow the public_anonymous profile
public_anonymous hidden
* read
\end{verbatim}
\end {quote}


\subsection {List edition}
\label {list-edition}

For each parameter, you may specify (via the \file {[ETCDIR]/edit\_list.conf}
configuration file) who has the right to edit the parameter concerned ; the default 
\file {[ETCBINDIR]/edit\_list.conf} is reasonably safe.

\begin{verbatim}
Each line is a set of 3 field
<Parameter> <Population> <Privilege>
<Population> : <listmaster|privileged_owner|owner> 
<Privilege> : <write|read|hidden>
parameter named "default" means any other parameter
\end{verbatim}

There is no hierarchical relation between  populations in this
configuration file. You need to explicitely list populations.

Eg: listmaster will not match rules refering to owner or privileged\_owner

\begin {quote}
\begin{verbatim}
     examples :

	# only listmaster can edit user_data_source, priority, ...
	user_data_source listmaster write  

	priority 	owner,privileged_owner 		read
	priority 	listmaster 			write
      
	# only privileged owner can modify  editor parameter, send, ...
	editor privileged_owner write
	
	send 		owner 				read
	send 		privileged_owner,listmaster 	write

	# other parameters can be changed by simple owners
	default 	owner 				write
\end{verbatim}
\end {quote}

      Privileged owners are defined in the list's \file {config} file as follows :
	\begin {quote}
	\begin{verbatim}
	owner
	email owners.email@foo.bar
	profile privileged
	\end{verbatim}
	\end {quote}

      The following rules are hard coded in WWSympa :
\begin {itemize}

\item only listmaster can edit the "profile privileged"
      owner attribute 

\item owners can edit their own attributes (except profile and e-mail)

\item the requestor creating a new list becomes a privileged owner

\item privileged owners can edit any gecos/reception/info attribute
of any owner

\item privileged owners can edit owners' e-mail addresses (but not privileged owners' e-mail addresses)

\end {itemize}

      Sympa aims to define two levels of trust for owners (some being entitled 
      simply to edit secondary parameters such as "custom\_subject", others having
      the right to manage more important parameters), while leaving control of
      crucial parameters (such as the list of privileged owners and user\_data\_sources)
      in the hands of the listmaster.
      Consequently, privileged owners can change owners' e-mails,
      but they cannot grant the responsibility of list management to others without
      referring to the listmaster.

Concerning list edition in a family context, see \ref{list-param-edit-family}, page~\pageref{list-param-edit-family}

\section {Removing a list}
    \label {ml-removal}

You can remove a list either from the command line or using the web interface.

\file {sympa.pl} provides an option to remove a mailing list, see the example below :
\begin {quote}
sympa.pl --remove\_list=mylist@mydomain
\end {quote}

Privileged owners can remove a mailing list through the list admin part of the web interface. Removing the mailing list
consists in removing its subscribers from the database and setting its status to \textit{closed}.Once removed, the list 
can still be restored by the listmaster ; list members are saved in a \file {subscribers.closed.dump} file.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Lists Families 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\cleardoublepage
\chapter {Lists Families}
    \label {lists-families}
    \index{families}

A list can have from three parameters to many tens of them. Some listmasters need to create 
a set of lists that have the same profile. In order to simplify the apprehension of these parameters, 
list families define a lists typology.
Families provide a new level for defaults : in the past, defaults in Sympa were global and 
most sites using Sympa needed multiple defaults for different group of lists.
Moreover families allow listmaster to delegate a part of configuration list to owners, in a controlled way 
according to family properties.
Distribution will provide defaults families.

\section {Family concept}
     \label {family-concept}

A family provides a model for all of its lists. It is specified by the following characteristics :

\begin {itemize}

    \item a list creation template providing a common profile for each list configuration file.
    \item an degree of independence between the lists and the family : list parameters edition rights and 
constraints on these parameters can be \textit{free} (no constraint), \textit{controlled} (a set of 
available values is defined for these parameters) or \textit{fixed} (the value for the parameter is imposed by 
the family). That prevents lists from diverging from the original and it allows list owner customizations in 
a controlled way. 
    \item a filiation kept between lists and family all along the list life : family modifications 
are applied on lists while keeping listowners customizations.

\end {itemize}

Here is a list of operation performed on a family : 

\begin {itemize}

    \item definition : definition of the list creation template, the degree of independence and family customizations.
    \item instantiation : lists creation or modifications of existing lists while respecting family properties.
          The set of data defining the lists is an XML document. 
    \item modification : modification of family properties. The modification is effective at the next instantiation time, that have consequences on every list.
    \item closure : closure of each list.
    \item adding one list to a family.
    \item closing one family list.
    \item modifying one family list.

\end {itemize}

\section {Using family}
    \label {using-family}

\subsection {Definition}
Families can be defined at the robot level, at  the site level or on the distribution level
 (where default families are provided).
So, you have to create a sub directory named after the family's name in a \file {families} directory  : 

\textit {Examples:} 
\begin {quote}
\begin{verbatim}
/home/sympa/etc/families/my_family
/home/sympa/etc/my_robot/families/my_family 
\end{verbatim}
\end {quote}
In this directory you must provide these files :
\begin{itemize}
  \item \file{config.tt2} (mandatory)
  \item \file{param\_constraint.conf} (mandatory)
  \item \file{edit\_list.conf}
  \item customizable files
\end{itemize}

   \subsubsection {config.tt2}
   \label{using-family-config-tpl}
      This is a list creation template, this file is mandatory. It provides default values for parameters. 
      This file is an almost complete list configuration, with a number of missing fields 
      (such as owner e-mail) to be replaced by data obtained at the time of family instantiation.
      It is easy to create new list templates by modifying existing ones. See \ref{list-tpl}, page~\pageref{list-tpl}
      and \ref{tpl-format}, page~\pageref{tpl-format}.\\

\textit {Example:} 
\begin {quote}
\begin{verbatim}
[STOPPARSE]
subject [% subject %]

status [% status %]

[% IF topic %]
topics [% topic %]

[% END %]
visibility noconceal

send privateoreditorkey

web_archive
  access public

subscribe open_notify

shared_doc
  d_edit [% shared_edit %]
  d_read [% shared_read %]

lang [% language %]

[% FOREACH o = owner %]
owner
  email [% o.email %]
  profile privileged
  [% IF o.gecos %] 
  gecos [% o.gecos %]
  [% END %]

[% END %]
[% IF moderator %]
   [% FOREACH m = moderator %]
editor
  email [% m.email %]

   [% END %]
[% END %]
 
[% IF sql %]
include_sql_query
  db_type [% sql.type %]
  host [% sql.host %]
  user [% sql.user %]
  passwd [% sql.pwd %]
  db_name [% sql.name %]
  sql_query [% sql.query %]
    
[% END %]
ttl 360
[STARTPARSE]
\end{verbatim}
\end {quote}


     \subsubsection {param\_constraint.conf}
     \index{param\_constraint.conf}
         This file is obligatory. It defines constraints on parameters. There are three kind of constraints :
	 \begin {itemize}
	    \item \textit{free} parameters : no constraint on these parameters, 
                  they are not written in the \file{param\_constraint.conf} file.
	    \item \textit{controlled} parameters : these parameters must select their values 
                  in a set of available values indicated in the \file{param\_constraint.conf} file.
	    \item \textit{fixed} parameters : these parameters must have the imposed value indicated
	          in the \file{param\_constraint.conf} file.
    
	 \end{itemize}
	 The parameters constraints will be checked at every list loading.

\textbf {WARNING} : Some parameters cannot be constrained, they are : \lparam {msg\_topic.keywords} 
(see~\ref {par-msg-topic}, page~\pageref {par-msg-topic}),\lparam {owner\_include.source\_parameter} 
(see~\ref {par-owner-include}, page~\pageref {par-owner-include}), \lparam {editor\_include.source\_parameter} (see~\ref {par-editor-include}, page~\pageref {par-editor-include}). About \lparam {digest} parameter (see~\ref {par-digest}, page~\pageref {par-digest}) , just days can be constrained.

    
\textit {Example:} 
\begin {quote}
\begin{verbatim}
lang                fr,us			
archive.period      days,week,month	
visibility          conceal,noconceal	
shared_doc.d_read   public		
shared_doc.d_edit   editor		
\end{verbatim}
\end {quote}

    \subsubsection {edit\_list.conf}
        This is an optional file. It defines which parameters/files are editable by
	owners. See \ref{list-edition}, page~\pageref{list-edition}.
	If the family does not have this file, \textit{Sympa} will look for 
	the one defined on robot level, server site level or distribution level. 
	(This file already exists without family context)\\
	Notes that by default parameter family\_name is not writable, you should not change 
	this edition right.

    \subsubsection {customizable files}
        Families provides a new level of customization for scenarios (see \ref{scenarios}, 
	page~\pageref{scenarios}), templates for service messages (see \ref {site-tpl}, 
	page~\pageref {site-tpl}) and templates for web pages (see \ref{web-tpl} , 
	page~\pageref{web-tpl}). \textit{Sympa} looks for these files in the following 
	level order: list, family, robot, server site or distribution. 

\textit {Example of custom hierarchy :} 
\begin {quote}
\begin{verbatim}
[ETCDIR]/families/myfamily/mail_tt2/
[ETCDIR]/families/myfamily/mail_tt2/bye.tt2
[ETCDIR]/families/myfamily/mail_tt2/welcome.tt2
\end{verbatim}
\end {quote}

\subsection {Instantiation}
\label{family-instantiation}

Instantiation permits to generate lists.You must provide an XML file that is 
composed of lists description, the root element is \textit{family} and is only 
composed of \textit{list} elements. List elements are described in section 
\ref{xml-file-format}, page~\pageref{xml-file-format}. Each list is described 
by the set of values for affectation list parameters.

Here is an sample command to instantiate a family :
\begin {quote}
\begin{verbatim}
sympa.pl --instantiate\_family my_family --robot \samplerobot --input\_file /path/to/my\_file.xml
\end{verbatim}
\end {quote}
This means lists that belong to family \file{my\_family} will be created under the robot 
\file{my\_robot} and these lists are described in the file \file{my\_file.xml}. Sympa will split this file 
into several xml files describing lists. Each list XML file is put in each list directory.\\

\textit {Example:} 
\begin {quote}
\begin{verbatim}
<?xml version="1.0" ?>
<family>
  <list>
    <listname>liste1</listname>
    <subject>a list example</subject>
    <description/>
    <status>open</status>
    <shared_edit>editor</shared_edit>
    <shared_read>private</shared_read>
    <language>fr</language>
    <owner multiple="1"> 
      <email>serge.aumont@cru.fr</email> 
      <gecos>C.R.U.</gecos>
    </owner>
    <owner multiple="1"> 
      <email>olivier.salaun@cru.fr</email>
    </owner>
    <owner_include multiple="1">
      <source>my_file</source>
    </owner_include>
    <sql> 
      <type>oracle</type>
      <host>sqlserv.admin.univ-x.fr</host>
      <user>stdutilisateur</user>
      <pwd>monsecret</pwd>
      <name>les_etudiants</name>
      <query>SELECT DISTINCT email FROM etudiant</query>
    </sql>
  </list>
  <list>
    <listname>liste2</listname>
    <subject>a list example</subject>
    <description/>
    <status>open</status>
    <shared_edit>editor</shared_edit>
    <shared_read>private</shared_read>
    <language>fr</language>
    <owner multiple="1"> 
      <email>serge.aumont@cru.fr</email> 
      <gecos>C.R.U.</gecos>
    </owner>
    <owner multiple="1"> 
      <email>olivier.salaun@cru.fr</email>
    </owner>
    <owner_include multiple="1">
      <source>my_file</source>
    </owner_include>
    <sql> 
      <type>oracle</type>
      <host>sqlserv.admin.univ-x.fr</host>
      <user>stdutilisateur</user>
      <pwd>monsecret</pwd>
      <name>les_etudiants</name>
      <query>SELECT DISTINCT email FROM etudiant</query>
    </sql>
  </list>
   ...
</family>
\end{verbatim}
\end {quote}


Each instantiation describes lists. Compared to the previous instantiation, there are three cases :
\begin{itemize}
  \item lists creation : new lists described by the new instantiation
  \item lists modification : lists already existing but possibly changed because of changed parameters values in
        the XML file or because of changed family's properties.
  \item lists removal : lists nomore described by the new instantiation. In this case, the listmaster must 
        valid his choice on command line. If the list is removed, it is set in status \file{family\_closed}, or if the 
	list is recovered, the list XML file from the previous instantiation is got back to go on as a list modification then.

\end{itemize}


After list creation or modification, parameters constraints are checked :
\begin{itemize}
  \item \textit{fixed} parameter : the value must be the one imposed.
  \item \textit{controlled} parameter : the value must be one of the set of available values.
  \item \textit{free} parameter : there is no checking.

\end{itemize}


diagram

In case of modification (see diagram), allowed customizations can be preserved :
\begin{itemize}
  \item (1) : for every modified parameters (via Web interface), noted in the \file{config\_changes} 
    file, values can be collected in the old list configuration file, according to new family properties :
    \begin{itemize}
      \item \textit{fixed} parameter : the value is not collected.
      \item \textit{controlled} parameter : the value is collected only if constraints are respected.
      \item \textit{free} parameter : the value is collected.
    \end{itemize}
  \item (2) : a new list configuration file is made with the new family properties
  \item (3) : collected values are set in the new list configuration file.

\end {itemize}


Notes : 
\begin{itemize}
  \item For each list problem (as family file error, error parameter constraint, error instanciation ...),
    the list is set in status \file{error\_config} and the listmaster is notified. He will have to do necessary to put list in use.
  \item For each list closing in family context, the list is set in status \file{family\_closed} and the owner is notified.
  \item For each overwritten list customization, the owner is notified. 
\end{itemize}

\subsection {Modification}
To modify a family, you have to edit family files manually. The modification will be effective while the next instanciation.\\
\textbf {WARNING}: The family modification must be done just before an instantiation. If it is not, alive lists wouldn't respect 
new family properties and they would be set in status error\_config immediately.

\subsection {Closure}

 \label{family-closure}
 
 Closes every list (installed under the indicated robot) 
 of this family : lists status are set to \file {family\_closed}, aliases are 
 removed and subscribers are removed from DB. (a dump is created in the list 
 directory to allow restoration of the list).
 
 Here is a sample command to close a family :
 \begin {quote}
 \begin{verbatim}
 sympa.pl --close_family my_family --robot \samplerobot 
 \end{verbatim}
 \end {quote} 

\subsection {Adding one list}

\label{family-add-list}
 
 Adds a list to the family without instantiate all the family. The list is created
 as if it was created during an instantiation, under the indicated robot. The XML file
 describes the list and the root element is \file{<list>}. List elements are described in section 
 \ref{list-creation-sympa}, page~\pageref{list-creation-sympa}.
 
 Here is a sample command to add a list to a family :
 \begin {quote}
 \begin{verbatim}
 sympa.pl --add\_list my\_family --robot \samplerobot  --input\_file /path/to/my\_file.xml
 \end{verbatim}
 \end {quote} 

\subsection {Removing one list}

Closes the list  installed under the indicated robot : the list status is set to
  \file {family\_closed}, aliases are 
 removed and subscribers are removed from DB. (a dump is created in the list 
 directory to allow restoring the list).
 
 Here is a sample command to close a list family (same as an orphan list) :
 \begin {quote}
 \begin{verbatim}
 sympa.pl --close_list my_list@\samplerobot
 \end{verbatim}
 \end {quote} 
 
 \subsection {Modifying one list}
 \label{family-modify-list}
 
 Modifies a family list without instantiating the whole family. The list (installed under the indicated robot) 
 is modified as if it was modified during an instantiation. The XML file
 describes the list and the root element is \file{<list>}. List elements are described in section 
 \ref{list-creation-sympa}, page~\pageref{list-creation-sympa}.
 
 Here is a sample command to modify a list to a family :
 \begin {quote}
 \begin{verbatim}
 sympa.pl --modify\_list my\_family --robot \samplerobot --input\_file /path/to/my\_file.xml
 \end{verbatim}
 \end {quote} 

\subsection {List parameters edition in a family context}
    \label{list-param-edit-family}
According to file \file{edit\_list.conf}, edition rights are controlled.  
See \ref{list-edition}, page~\pageref{list-edition}. But in a family context, constraints parameters are 
added to edition right as it is summarized in this array :\\

array\\



Note : In order to preserve list customization for instantiation, every modified parameter (via the Web interface) is noted in the \file{config\_changes} file. 

 \section {Automatic list creation}
 \label{automatic-list-creation}
 
 You can benefit from the family concept to let Sympa automatically create lists for you.
 Let us suppose that you want to open a list according to specified criteria (age, geographical site...) within your organization.
 Maybe that would result in too many lists, and many of them would never be used.
 
 Automatic list creation allows you to define those potential lists through family parameters,
 but they won't be created yet. The mailing list creation is trigerred when Sympa receives a
 message addressed to this list.
 
 To enable automatic list creation you'll have to : 
 \begin {itemize} 

   \item Configure your MTA to queue messages for these lists in an appropriate spool

   \item Define a family associated to such lists

   \item Configure Sympa to enable the feature

 \end {itemize}

\subsection {Configuring your MTA}

 To do so, we have to configure our MTA for it to add a custom header field to the message. The easiest way
 is to customize your aliases manager, so mails for automatic lists aren't delivered to the normal 
 \file {queue} program, but to the \file {familyqueue} dedicated one. For example, you can decide
 that the name of those lists will start with the \texttt {auto-} pattern, so you can process them separately
 from other lists you are hosting.
 
 \file {familyqueue} expects 2 arguments : the list name and the family name (whereas the \file {queue} program
 only expects the list address).
 
 Let's start with a use case : we need to communicate to groups of co-workers, depending on their age
 and their occupation. We decide that, for example, if I need to write to all CTOs who are fifty years old,
 I will use the auto-cto.50@lists.domain.com mailing list. The occupation and age informations are stored in our
 ldap directory (but of course we could use any Sympa data source : sql, files...). We will create the
 age-occupation family.
 
 First of all we configure our MTA to deliver mail to  \texttt{'auto-*'} to  \file {familyqueue}
 for the \texttt{age-occupation} family.
 
 \begin {quote}
 \begin{verbatim}
/etc/postfix/main.cf
    ...
    transport_maps = regexp:/etc/postfix/transport_regexp

/etc/postfix/transport_regexp
    /^.*+owner\@lists\.domain\.com$/      sympabounce:
    /^auto-.*\@lists\.domain\.com$/       sympafamily:
    /^.*\@lists\.domain\.com$/            sympa:

/etc/postfix/master.cf
    sympa     unix  -       n       n       -       -       pipe
      flags=R user=sympa argv=[MAILERPROGDIR]/queue ${recipient}
    sympabounce  unix  -       n       n       -       -       pipe
      flags=R user=sympa argv=[MAILERPROGDIR]/bouncequeue ${user}
    sympafamily  unix  -       n       n       -       -       pipe
      flags=R user=sympa argv=[MAILERPROGDIR]/familyqueue ${user} age-occupation
\end{verbatim}
\end {quote} 

A mail addressed to \textit {auto-cto.50@lists.domain.com} will be queued to the \dir {[SPOOLDIR]/automatic} spool, 
defined by the \cfkeyword {queueautomatic} \file {sympa.conf} parameter (see \ref {kw-queueautomatic}, page~\pageref {kw-queueautomatic}).
The mail will first be processed by an instance of \file {sympa.pl} process dedicated to automatic list creation, then the mail
will be sent to the newly created mailing list.

\subsection {Defining the list family}

We need to create the appropriate \file {etc/families/age-occupation/config.tt2}. All the magic comes
from the TT2 language capabilities. We define on-the-fly the LDAP source, thanks to TT2 macros.

 \begin {quote}
 \begin{verbatim}
/home/sympa/etc/families/age-occupation/config.tt2
    ...
    user_data_source include2
    
    [%
    occupations = {
        cto = { title=>"chief technical officer", abbr=>"CHIEF TECH OFF" },
        coo = { title=>"chief operating officer", abbr=>"CHIEF OPER OFF" },
        cio = { title=>"chief information officer", abbr=>"CHIEF INFO OFF" },
    }
    nemes = listname.split('-');
    THROW autofamily "SYNTAX ERROR : listname must begin with 'auto-' " IF (nemes.size != 2 || nemes.0 != 'auto');
    tokens = nemes.1.split('\.');
    THROW autofamily "SYNTAX ERROR : wrong listname syntax" IF (tokens.size != 2 || ! occupations.${tokens.0} || tokens.1 < 20 || tokens.1 > 99 );
    age = tokens.1 div 10;
    %]

    custom_subject [[% occupations.${tokens.0}.abbr %] OF [% tokens.1 %]]

    subject Every [% tokens.1 %] years old [% occupations.${tokens.0}.title %]

    include_ldap_query
    attrs mail
    filter (&(objectClass=inetOrgPerson)(employeeType=[% occupations.${tokens.0}.abbr %])(personAge=[% age %]*))
    name ldap
    port 389
    host ldap.domain.com
    passwd ldap_passwd
    suffix dc=domain,dc=com
    timeout 30
    user cn=root,dc=domain,dc=com
    scope sub
    select all
\end{verbatim}
\end {quote} 

The main variable you get is the name of the current mailing list via the \textbf {listname} variable as used in the example above.

\subsection {Configuring Sympa}

Now we need to enable automatic list creation in Sympa. To do so, we have to 
\begin {itemize}

  \item set the \cfkeyword {automatic\_list\_feature} parameter to \texttt {on} and define who can create automatic lists via
  the \cfkeyword {automatic\_list\_creation} (points to an automatic\_list\_creation scenario).

  \item set the \cfkeyword {queueautomatic} \file {sympa.conf} parameter to the spool location where we want these messages to
  be stored (it has to be different from the \dir {[SPOOLDIR]/msg} spool).

\end {itemize}

You can make Sympa delete automatic lists that were created with zero list members ; to do so
you shoukd set the \cfkeyword {automatic\_list\_removal} parameter to \texttt {if\_empty}.

 \begin {quote}
 \begin{verbatim}
/home/sympa/etc/sympa.conf
    ...
    automatic_list_feature  on
    automatic_list_creation public
    queueautomatic          [SPOOLDIR]/automatic
    automatic_list_removal    if_empty
\end{verbatim}
\end {quote} 

While writing your own \textindex {automatic\_list\_creation} scenarios, be aware that :
\begin {itemize}

  \item when the scenario is evaluated, the list is not yet created ; therefore you can't use the list-related
  variables.

  \item You can only use 'smtp' and 'smime' authentication method in scenario rules (You cannot request the md5 challenge).
  Moreover only \texttt {do\_it} and \texttt {reject} actions are available.

\end {itemize}

Now you can send message to auto-cio.40 or auto-cto.50, and the lists will be created on the fly.

You will receive an 'unknown list' error if either the syntax is incorrect or the number of subscriber is zero.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% List configuration parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\cleardoublepage
\chapter {List configuration parameters}
    \label {list-configuration-param}


The configuration file is composed of paragraphs separated by blank
lines and introduced by a keyword.

Even though there are a very large number of possible parameters, the minimal list
definition is very short. The only required parameters are \lparam {owner} (or \lparam {owner\_include}) and \lparam {subject}.
All other parameters have a default value.

\begin {quote}
    \textit {keyword value}
\end {quote}

\textbf {WARNING}: configuration parameters must be separated by
blank lines and BLANK LINES ONLY !

\section {List description}

\subsection {editor}
    \label {par-editor}
    \index{moderation}

The \file {config} file contains one \lparam {editor} paragraph
per \textindex {moderator} (or editor).
It concerns static editor definition. For dynamic definition and more information about editors see~\ref {par-editor-include}, 
page~\pageref {par-editor-include}.

\textit {Example:} 

\begin {quote}
\begin{verbatim}
editor
email Pierre.David@prism.uvsq.fr
gecos Pierre (Universite de Versailles St Quentin)
\end{verbatim}
\end {quote}

Only the editor of a list is authorized to send messages
to the list when the \lparam {send} parameter (see~\ref {par-send},
page~\pageref {par-send}) is set to either \lparam {editor}, \lparam
{editorkey}, or \lparam {editorkeyonly}.
The \lparam {editor} parameter is also consulted in certain other cases
( \lparam {privateoreditorkey} ).

The syntax of this directive is the same as that of the \lparam
{owner} parameter (see~\ref {par-owner}, page~\pageref {par-owner}),
even when several moderators are defined.


\subsection {editor\_include}
    \label {par-editor-include}
    \index{data-inclusion-file}

The \file {config} file contains one \lparam {editor\_include} paragraph
per data inclusion file (see~\ref {data-inclusion-file}, page~\pageref {data-inclusion-file}).
It concerns dynamic editor definition : inclusion of external data. For static editor definition and more information about moderation see~\ref {par-editor}, page~\pageref {par-editor}.

\textit {Example:} 

\begin {quote}
\begin{verbatim}
editor_include
reception mail
source myfile 
source_parameters a,b,c
\end{verbatim}
\end {quote}

The syntax of this directive is the same as that of the \lparam
{owner\_include} parameter (see~\ref {par-owner-include}, page~\pageref {par-owner-include}),
even when several moderators are defined.

\subsection {host}
 \label {par-host}
 \index{host}

	\default {\cfkeyword {domain} robot parameter}

\lparam {host} \textit {fully-qualified-domain-name}

Domain name of the list, default is the robot domain name set in the related \file {robot.conf} file or in file \file {[CONFIG]}.

\subsection {lang}
    \label {par-lang}

	\default {\cfkeyword {lang} robot parameter}

\textit {Example:} 

\begin {quote}
\begin{verbatim}
lang en_US
\end{verbatim}
\end {quote}

This parameter defines the language used for the list. It is
used to initialize a user's language preference ; \Sympa command
reports are extracted from the associated message catalog.

See \ref {internationalization}, page~\pageref {internationalization}
for available languages.

\subsection {owner}
    \label {par-owner}

The \file {config} file contains one \lparam {owner} paragraph per owner. 
It concerns static owner definition. For dynamic definition see~\ref {par-owner-include}, page~\pageref {par-owner-include}.

\textit {Example:} 

\begin {quote}
\begin{verbatim}
owner
email serge.aumont@cru.fr
gecos C.R.U.
info Tel: 02 99 76 45 34
reception nomail
\end{verbatim}
\end {quote}

The list owner is usually the person who has the authorization to send
\mailcmd {ADD} (see~\ref {cmd-add}, page~\pageref {cmd-add}) and
\mailcmd {DELETE} (see~\ref {cmd-delete}, page~\pageref {cmd-delete})
commands on behalf of other users.

When the \lparam {subscribe} parameter (see~\ref {par-subscribe},
page~\pageref {par-subscribe}) specifies a restricted list, it is
the owner who has the exclusive right to subscribe users, and
it is therefore to the owner that \mailcmd {SUBSCRIBE} requests
will be forwarded.

There may be several owners of a single list; in this case, each
owner is declared in a paragraph starting with the \lparam {owner}
keyword.

The \lparam {owner} directive is followed by one or several lines
giving details regarding the owner's characteristics:

\begin {itemize}
    \item  \lparam {email} \textit {address}

        Owner's e-mail address

    \item  \lparam {reception nomail}

        Optional attribute for an owner who does not wish to receive
        mails.  Useful to define an owner with multiple e-mail
        addresses: they are all recognized when \Sympa receives
        mail, but thanks to \lparam {reception nomail}, not all of
	these addresses need receive administrative mail from \Sympa.

    \item  \lparam {gecos} \textit {data}

        Public information on the owner

    \item \lparam {info} \textit {data}

	Available since release 2.3

	Private information on the owner

    \item \lparam {profile} \texttt {privileged} \texttt{|}
	                    \texttt {normal}

	Available since release 2.3.5

	Profile of the owner. This is currently used to restrict
	access to some features of WWSympa, such as adding new owners
	to a list.

\end {itemize}


\subsection{owner\_include}
    \label {par-owner-include}
    \index{data-inclusion-file}

The \file {config} file contains one \lparam {owner\_include} paragraph per data inclusion file 
(see~\ref {data-inclusion-file}, page~\pageref {data-inclusion-file}.
It concerns dynamic owner definition : inclusion of external data. For static owner definition and more information 
about owners see~\ref {par-owner}, page~\pageref {par-owner}.

\textit {Example:} 

\begin {quote}
\begin{verbatim}
owner_include
source myfile
source_parameters a,b,c
reception nomail
profile normal
\end{verbatim}
\end {quote}

The \lparam {owner\_include} directive is followed by one or several lines
giving details regarding the owner(s) included characteristics:

\begin {itemize}

    \item  \lparam {source myfile}
      
        This is an mandatory field : it indicates the data inclusion file myfile.incl. This file can be a template. In this case, it will be interpreted
	with values given by subparameter \lparam {source\_parameter}. 
	Note that the \lparam {source} parameter should NOT include the \textit {.incl} file extension ; the myfile.incl file should be located in the \dir {data\_sources} directory.

    \item \lparam {source\_parameters a,b,c}

        It contains values enumeration that will be affected to the \file {param} array used in the template file (see~\ref {data-inclusion-file}, page~\pageref {data-inclusion-file}).
	This parameter is uncompellable.

    \item  \lparam {reception nomail}

        Optional attribute for owner(s) who does not wish to receive
        mails.  

    \item \lparam {profile} \texttt {privileged} \texttt{|}
	                    \texttt {normal}

	Profile of the owner(s).

\end {itemize}



\subsection {subject}
    \label {par-subject}

\lparam {subject} \textit {subject-of-the-list}

This parameter indicates the subject of the list, which is sent in
response to the \mailcmd {LISTS} mail command. The subject is
a free form text limited to one line.

\subsection {topics}
    \label {par-topics}

\lparam {topics} computing/internet,education/university

This parameter allows the classification of lists. You may define multiple 
topics as well as hierarchical ones. \WWSympa's list of public lists 
uses this parameter. This parameter is different from (\lparam{msg\_topic})
parameter used to tag mails.

\subsection {visibility }
    \label {par-visibility}

	\default {conceal}

	\scenarized {visibility}

This parameter indicates whether the list should feature in the
output generated in response to a \mailcmd {LISTS} command.

\begin {itemize}
[FOREACH s IN scenari->visibility]
     \item \lparam {visibility} \texttt {[s->name]}
	\begin {htmlonly}
	  (\htmladdnormallink {view} {http://www.sympa.org/distribution/current/src/etc/scenari/visibility.[s->name]})
	\end {htmlonly}\\
	[s->title]

[END]
\end {itemize}


\section {Data source related}

\subsection {user\_data\_source}

    	\label {par-user-data-source}
	\index{user-data-source}

	\default {file|database, if using an RDBMS}

\lparam {user\_data\_source}
   \texttt {file} \texttt{|}
   \texttt {database} \texttt{|}
   \texttt {include} \texttt{|}
   \texttt {include2}

Sympa allows the mailing list manager to choose how \Sympa loads
subscriber and administartive data. User information can be stored in a text 
file or relational database, or included from various external
sources (list, flat file, result of \textindex {LDAP} or \textindex {SQL} query).

\begin {itemize}
\item  \lparam {user\_data\_source} \texttt {file}

       When this value is used, subscriber data
       are stored in a file whose name is defined by the
       \cfkeyword {subscribers} parameter in \file
       {sympa.conf}. This is maintained for backward compatibility.

\item  \lparam {user\_data\_source} \texttt {database} 

       This mode was been introduced to enable data to be stored
       in a relational database. This can be used for instance to share subscriber
       data with an HTTP interface, or simply to facilitate
       the administration of very large mailing lists. It has been
       tested with MySQL, using a list of 200 000 subscribers. 
       We strongly recommend the use of a database in place of text files.
       It will improve performance, and solve possible conflicts between
       \Sympa and \WWSympa. Please refer to the 
       \"\Sympa and its database\" section
       (\ref {sec-rdbms}, page~\pageref {sec-rdbms}).

\item \lparam {user\_data\_source} \texttt {include} 
\label {user-data-source}       

       Here, subscribers are not defined \emph {extensively} (enumeration
       of their e-mail addresses) but \emph {intensively} (definition of criteria
       subscribers must satisfy). Includes can be performed 
       by extracting e-mail addresses using an \textindex {SQL} or \textindex {LDAP} query, or 
       by including other mailing lists. At least one include 
       paragraph, defining a data source, is needed. Valid include paragraphs (see
       below) are \lparam {include\_file}, \lparam {include\_list}, \lparam {include\_remote\_sympa\_list}, 
	\lparam {include\_sql\_query} and \lparam {include\_ldap\_query}. 

\item \lparam {user\_data\_source} \texttt {include2} 

       This is a replacement for the \textindex {include} mode. In this mode, the members cache is no more maitained in
       a DB FIle but in the main database instead. The behavior of the cache is detailed in the database chapter 
       (see~\ref {include2-cache}, page~\pageref {include2-cache}). This is the only mode that run the database for administrative data 
       in the database


\end {itemize}


\subsection {ttl}

    	\label {ttl}
	\index{ttl}

	\default {3600}

\lparam {ttl} \texttt {delay\_in\_seconds} 

\Sympa caches user data extracted using the include parameter.
Their TTL (time-to-live) within \Sympa can be controlled using this
parameter. The default value is 3600.

\subsection {include\_list}

    	\label {include-list}
	\index{include-list}

\lparam {include\_list} \texttt {listname}

This parameter will be interpreted only if 
\lparam {user\_data\_source} is set to \texttt {include} or \texttt {include2}.
All subscribers of list \texttt {listname} become members 
of the current list. You may include as many lists as required, using one
\lparam {include\_list} \texttt {listname} line for each included
list. Any list at all may be included ; the \lparam {user\_data\_source} definition
of the included list is irrelevant, and you may therefore
include lists which are also defined by the inclusion of other lists. 
Be careful, however, not to include list \texttt {A} in list \texttt {B} and
then list \texttt {B} in list \texttt {A}, since this will give rise an 
infinite loop.

\example {include\_list  local-list}

\example {include\_list  other-local-list@other-local-robot}

\subsection {include\_remote\_sympa\_list}

\label {include-remote-sympa-list}
\index{include-remote-sympa-list}

\lparam {include\_remote\_sympa\_list}

Sympa can contact another \Sympa service using https to fetch
a remote list in order to include each member of a remote list
as subscriber. You may include as many lists as required, using one
\lparam {include\_remote\_sympa\_list} paragraph for each included
list. Be careful, however, not to give rise an infinite loop making cross includes.


For this operation, one \Sympa site act as a server while the other one
act as client. On the server side, the only  setting needed is to
give permition to the remote \Sympa to review the list. This is controled
by the review authorization scenario. 

From the client side you must define the remote list dump URI.

\begin{itemize}

\item
\label {remote-host}
\lparam {remote\_host} \textit {remote\_host\_name} 

\item
\label {port}
\lparam {port} \textit {port} (Default 443) 


\item
\label {path}
\lparam {path} \textit {absolute path} (In most cases, for a list name foo /sympa/dump/foo ) 

\end{itemize}

Because https offert a easy and secure client authentication, https is the only one
protocole currently supported. A additional parameter is needed : the name of the
certificate (and the private key) to be used :
\label {cert}

\begin {itemize}
\item  \lparam {cert} \texttt {list} the certificate to be use is the list
certificate (the certificate subject distinguished name email is the list adress).
Certificate and private key are located in the list directory.
 \item  \lparam {cert} \texttt {robot} the certificate used is then related to
sympa itself : the certificate subject distinguished name email look like
sympa@my.domain and files are located in virtual host etc dir if virtual host
is used otherwise in \dir {[ETCDIR]}.
\end{itemize}


\subsection {include\_sql\_query}
    \label {include-sql-query}

\lparam {include\_sql\_query}

This parameter will be interpreted only if the
\lparam {user\_data\_source} value is set to  \texttt {include}, and
is used to begin a paragraph defining the SQL query parameters :

\begin{itemize}

\item
\label {db-type}
\lparam {db\_type} \textit {dbd\_name} 

The database type (mysql, SQLite, Pg, Oracle, Sybase, CSV ...). This value identifies the PERL
DataBase Driver (DBD) to be used, and is therefore case-sensitive.

\item
\label {host}
\lparam {host} \textit {hostname}

The Database Server \Sympa will try to connect to.

\item
\label {db-port}
\lparam {db\_port} \textit {port}

If not using the default RDBMS port, you can specify it.

\item
\label {db-name}
\lparam {db\_name} \textit {sympa\_db\_name}

The hostname of the database system.


\item 
\label {user}
\lparam {user} \textit {user\_id}

The user id to be used when connecting to the database.

\item 
\label {passwd}
\lparam {passwd} \textit {some secret}

The user passwd for \lparam {user}.


\item
\label {sql-query}
\lparam {sql\_query} \textit {a query string}
The SQL query string. No fields other than e-mail addresses should be returned
by this query!

\item
\label {connect-options}
\lparam {connect\_options} \textit {option1=x;option2=y}

This parameter is optional and specific to each RDBMS.

These options are appended to the connect string.

Example :

\begin {quote}
\begin{verbatim}

include_sql_query
      db_type mysql
      host sqlserv.admin.univ-x.fr
      user stduser
      passwd mysecret
      db_name studentbody
      sql_query SELECT DISTINCT email FROM student
      connect_options mysql_connect_timeout=5
\end{verbatim}
\end {quote}

Connexion timeout is set to 5 seconds.

\item 
\lparam {db\_env} \textit {list\_of\_var\_def}

This parameter is optional ; it is needed for some RDBMS (Oracle).

Sets a list of environment variables to set before database connexion.
This is a ';' separated list of variable assignment.

Example for Oracle:
\begin {quote}
\begin{verbatim}
db_env	ORACLE_TERM=vt100;ORACLE_HOME=/var/hote/oracle/7.3.4
\end{verbatim}
\end {quote}

\item
\label {sql-name}
\lparam {name} \textit {short name}

This parameter is optional.

It provides a human-readable name to this datasource. It will be used within the REVIEW page to indicate what datasource
each list member comes from (usefull when having multiple data sources).

\item
\label {sql-fdir}
\lparam {f\_dir} \textit {/var/csvdir}

This parameter is optional, only used when accessing a CSV datasource.

When connecting to a CSV datasource, this parameter indicates the directory where the CSV files are located.



\end{itemize}

Example :

\begin {quote}
\begin{verbatim}

include_sql_query
      db_type oracle
      host sqlserv.admin.univ-x.fr
      user stduser
      passwd mysecret
      db_name studentbody
      sql_query SELECT DISTINCT email FROM student

\end{verbatim}
\end {quote}

\subsection {include\_ldap\_query}
    \label {include-ldap-query}

\lparam {include\_ldap\_query}

This paragraph defines parameters for a \textindex {LDAP} query returning a
list of subscribers. This paragraph is used only if \lparam
{user\_data\_source} is set to \texttt {include}. This feature
requires the \perlmodule {Net::LDAP} (perlldap) PERL module.

\begin{itemize}

\item
\label {host}
\lparam {host} \textit {ldap\_directory\_hostname} 

Name of the LDAP directory host or a comma separated list of host:port. The
second form is usefull if you are using some replication ldap host. 

Example :

\begin {quote}
\begin{verbatim}
    host ldap.cru.fr:389,backup-ldap.cru.fr:389

\end{verbatim}
\end {quote}


\item
\label {port}
\lparam {port} \textit {ldap\_directory\_port} (OBSOLETE) 

Port on which the Directory accepts connections.

\item
\label {user}
\lparam {user} \textit {ldap\_user\_name}

Username with read access to the LDAP directory.

\item
\label {passwd}
\lparam {passwd} \textit {LDAP\_user\_password}

Password for \lparam {user}.

\item
\lparam {use\_ssl} \textit {yes|no}

If set to yes, LDAPS protocol is used.


\item
\lparam {ssl\_version} \textit {sslv2|sslv3|tls}
\default {sslv3}

If using SSL, this parameter define if SSL or TLS is used.

\item
\lparam {ssl\_version} \textit {ciphers used}
\default {ALL}

If using SSL, this parameter specifies which subset of cipher suites are permissible for this connection, using the standard OpenSSL string format. The default value of Net::LDAPS for ciphers is ALL, which permits all ciphers, even those that don't encrypt!

\item
\label {suffix}
\lparam {suffix} \textit {directory name}

Defines the naming space covered by the search (optional, depending on
the LDAP server).

\item
\label {timeout}
\lparam {timeout} \textit {delay\_in\_seconds}

Timeout when connecting the remote server.

\item
\label {filter}
\lparam {filter} \textit {search\_filter}

Defines the LDAP search filter (RFC 2254 compliant).

\item
\label {attrs}
\lparam {attrs} \textit {mail\_attribute} 
\default {mail}

The attribute containing the e-mail address(es) in the returned object.

\item
\label {select}
\lparam {select} \textit {first \texttt{|} all}
\default {first}

Defines whether to use only the first address, or all the addresses, in
cases where multiple values are returned.

\item
\label {scope}
\lparam {scope} \textit {base \texttt{|} one \texttt{|} sub}
\default {sub}

By default the search is performed on the whole tree below the specified
base object. This may be changed by specifying a scope parameter with one
of the following values. 
\begin{itemize}

	\item \textbf {base} : 
	Search only the base object. 
	
	\item \textbf {one} : 
	Search the entries immediately below the base object.

	\item \textbf {sub} : 
	Search the whole tree below the base object. 

\end{itemize}

\end{itemize}

Example :

\begin {quote}
\begin{verbatim}

    include_ldap_query
    host ldap.cru.fr
    suffix dc=cru, dc=fr
    timeout 10
    filter (&(cn=aumont) (c=fr))
    attrs mail
    select first
    scope one

\end{verbatim}
\end {quote}


\subsection {include\_ldap\_2level\_query}
    \label {include-ldap-2level-query}

\lparam {include\_ldap\_2level\_query}

This paragraph defines parameters for a two-level \textindex {LDAP} query returning a
list of subscribers. Usually the first-level query returns a list of DNs
and the second-level queries convert the DNs into e-mail addresses.
This paragraph is used only if \lparam
{user\_data\_source} is set to \texttt {include}. This feature
requires the \perlmodule {Net::LDAP} (perlldap) PERL module.

\begin{itemize}

\item
\label {host}
\lparam {host} \textit {ldap\_directory\_hostname} 

Name of the LDAP directory host or a comma separated list of host:port. The
second form is usefull if you are using some replication ldap host. 

Example :

\begin {quote}
\begin{verbatim}
    host ldap.cru.fr:389,backup-ldap.cru.fr:389

\end{verbatim}
\end {quote}



\item
\label {port}
\lparam {port} \textit {ldap\_directory\_port} (OBSOLETE) 

Port on which the Directory accepts connections (this parameter is ignored if host definition include port specification).

\item
\label {user}
\lparam {user} \textit {ldap\_user\_name}

Username with read access to the LDAP directory.

\item
\label {passwd}
\lparam {passwd} \textit {LDAP\_user\_password}

Password for \lparam {user}.


\item
\lparam {use\_ssl} \textit {yes|no}

If set to yes, LDAPS protocol is used.


\item
\lparam {ssl\_version} \textit {sslv2|sslv3|tls}
\default {sslv3}

If using SSL, this parameter define if SSL or TLS is used.

\item
\lparam {ssl\_version} \textit {ciphers used}
\default {ALL}

If using SSL, this parameter specifies which subset of cipher suites are permissible for this connection, using the standard OpenSSL string format. The default value of Net::LDAPS for ciphers is ALL, which permits all ciphers, even those that don't encrypt!

\item
\label {suffix1}
\lparam {suffix1} \textit {directory name}

Defines the naming space covered by the first-level search (optional, depending
on the LDAP server).

\item
\label {timeout1}
\lparam {timeout1} \textit {delay\_in\_seconds}

Timeout for the first-level query when connecting to the remote server.

\item
\label {filter1}
\lparam {filter1} \textit {search\_filter}

Defines the LDAP search filter for the first-level query (RFC 2254 compliant).

\item
\label {attrs1}
\lparam {attrs1} \textit {attribute} 
%\default {mail}

[STOPPARSE]
The attribute containing the data in the returned object that will be used for
the second-level query.  This data is referenced using the syntax ``[attrs1]''.
[STARTPARSE]

\item
\label {select1}
\lparam {select1} \textit {first \texttt{|} all \texttt{|} regex}
\default {first}

Defines whether to use only the first attribute value, all the values, or only
those values matching a regular expression.

\item
\label {regex1}
\lparam {regex1} \textit {regular\_expression}
\default {}

The Perl regular expression to use if ``select1'' is set to ``regex''.

\item
\label {scope1}
\lparam {scope1} \textit {base \texttt{|} one \texttt{|} sub}
\default {sub}

By default the first-level search is performed on the whole tree below the
specified base object. This may be changed by specifying a scope parameter
with one of the following values. 
\begin{itemize}

	\item \textbf {base} : 
	Search only the base object. 
	
	\item \textbf {one} : 
	Search the entries immediately below the base object.

	\item \textbf {sub} : 
	Search the whole tree below the base object. 

\end{itemize}


\item
\label {suffix2}
\lparam {suffix2} \textit {directory name}

[STOPPARSE]
Defines the naming space covered by the second-level search (optional, depending
on the LDAP server).  The ``[attrs1]'' syntax may be used to substitute data
from the first-level query into this parameter.

\item
\label {timeout2}
\lparam {timeout2} \textit {delay\_in\_seconds}

Timeout for the second-level queries when connecting to the remote server.

\item
\label {filter2}
\lparam {filter2} \textit {search\_filter}

Defines the LDAP search filter for the second-level queries
(RFC 2254 compliant).  The ``[attrs1]'' syntax may be used to
substitute data from the first-level query into this parameter.

\item
\label {attrs2}
\lparam {attrs2} \textit {mail\_attribute} 
\default {mail}

The attribute containing the e-mail address(es) in the returned objects from the
second-level queries.

\item
\label {select2}
\lparam {select2} \textit {first \texttt{|} all \texttt{|} regex}
\default {first}

Defines whether to use only the first address, all the addresses, or only
those addresses matching a regular expression in the second-level queries.

\item
\label {regex2}
\lparam {regex2} \textit {regular\_expression}
\default {}

The Perl regular expression to use if ``select2'' is set to ``regex''.

\item
\label {scope2}
\lparam {scope2} \textit {base \texttt{|} one \texttt{|} sub}
\default {sub}

By default the second-level search is performed on the whole tree below the
specified base object. This may be changed by specifying a scope2 parameter
with one of the following values. 
\begin{itemize}

	\item \textbf {base} : 
	Search only the base object. 
	
	\item \textbf {one} : 
	Search the entries immediately below the base object.

	\item \textbf {sub} : 
	Search the whole tree below the base object. 

\end{itemize}

\end{itemize}

Example : (cn=testgroup,dc=cru,dc=fr should be a groupOfUniqueNames here)

\begin {quote}
\begin{verbatim}

    include_ldap_2level_query
    host ldap.univ.fr
    port 389
    suffix1 ou=Groups,dc=univ,dc=fr
    scope1 one
    filter1 (&(objectClass=groupOfUniqueNames) (| (cn=cri)(cn=ufrmi)))
    attrs1 uniquemember
    select1 all
    suffix2 [attrs1]
    scope2 base
    filter2 (objectClass=n2pers)
    attrs2 mail
    select2 first

\end{verbatim}
\end {quote}
[STARTPARSE]

\subsection {include\_file}
    \label {include-file}

\lparam {include\_file}    \texttt {path\_to\_file} 

This parameter will be interpreted only if the
\lparam {user\_data\_source} value is set to  \texttt {include}.
The file should contain one e-mail address per line with an optional user description, separated from the email address by spaces (lines beginning with a "\#" are ignored).

\textit {Sample included file:} 

\begin {quote}
\begin{verbatim}
## Data for Sympa member import
john.smith@sample.edu  John Smith - math department
sarah.hanrahan@sample.edu  Sarah Hanrahan - physics department
\end{verbatim}
\end {quote}


\subsection {include\_remote\_file}
    \label {include-remote-file}

\lparam {include\_remote\_file}

This parameter (organized as a paragraph) does the same as the \lparam {include\_file} parameter, except that
it gets a remote file. This paragraph is used only if \lparam {user\_data\_source} is set to \texttt {include}. 
Using this method you should be able to include any \textit {exotic} data source that is not supported by Sympa.
The paragraph is made of the following entries :

\begin{itemize}

\item
\label {url}
\lparam {url} \textit {url\_of\_remote\_file} 

This is the URL of the remote file to include.

\item
\label {user}
\lparam {user} \textit {user\_name} 

This entry is optional, only used if HTTP basic authentication is required to access the remote file.

\item
\label {passwd}
\lparam {passwd} \textit {user\_passwd} 

This entry is optional, only used if HTTP basic authentication is required to access the remote file.

\end {itemize}

\textit {Example:} 

\begin {quote}
\begin{verbatim}
include_remote_file
url     http://www.myserver.edu/myfile
user    john_netid
passwd  john_passwd
\end{verbatim}
\end {quote}


\section {Command related}

\subsection {subscribe}
    \label {par-subscribe}

	\default {open}

	\scenarized {subscribe}

The \lparam {subscribe} parameter defines the rules for subscribing to the list. 
Predefined authorization scenarios are :

\begin {itemize}

[FOREACH s IN scenari->subscribe]
     \item \lparam {subscribe} \texttt {[s->name]}
	\begin {htmlonly}
	  (\htmladdnormallink {view} {http://www.sympa.org/distribution/current/src/etc/scenari/subscribe.[s->name]})
	\end {htmlonly}\\
[s->title]

[END]

\end {itemize}

\subsection {unsubscribe}
    \label {par-unsubscribe}

	\default {open}

	\scenarized {unsubscribe}

This parameter specifies the unsubscription method for the list.
Use \texttt {open\_notify} or \texttt {auth\_notify} to allow owner
notification of each unsubscribe command. 
Predefined authorization scenarios are :

\begin {itemize}
[FOREACH s IN scenari->unsubscribe]
     \item \lparam {unsubscribe} \texttt {[s->name]} 
	\begin {htmlonly}
	  (\htmladdnormallink {view} {http://www.sympa.org/distribution/current/src/etc/scenari/unsubscribe.[s->name]})
	\end {htmlonly}\\
	[s->title]

[END]
\end {itemize}

\subsection {add}
    \label {par-add}

	\default {owner}

	\scenarized {add}

This parameter specifies who is authorized to use the \mailcmd {ADD} command.
Predefined authorization scenarios are :


\begin {itemize}
[FOREACH s IN scenari->add]
     \item \lparam {add} \texttt {[s->name]}
	\begin {htmlonly}
	  (\htmladdnormallink {view} {http://www.sympa.org/distribution/current/src/etc/scenari/add.[s->name]})
	\end {htmlonly}\\
	[s->title]

[END]
\end {itemize}


\subsection {del}
    \label {par-del}

	\default {owner}

	\scenarized {del}

This parameter specifies who is authorized to use the \mailcmd {DEL} command.
Predefined authorization scenarios are :


\begin {itemize}
[FOREACH s IN scenari->del]
     \item \lparam {del} \texttt {[s->name]} 
	\begin {htmlonly}
	  (\htmladdnormallink {view} {http://www.sympa.org/distribution/current/src/etc/scenari/del.[s->name]})
	\end {htmlonly}\\
	[s->title]

[END]
\end {itemize}


\subsection {remind}
    \label {par-remind}

	\default {owner}

	\scenarized {remind}

This parameter specifies who is authorized to use the \mailcmd {remind} command.
Predefined authorization scenarios are :


\begin {itemize}
[FOREACH s IN scenari->remind]
     \item \lparam {remind} \texttt {[s->name]} 
	\begin {htmlonly}
	  (\htmladdnormallink {view} {http://www.sympa.org/distribution/current/src/etc/scenari/remind.[s->name]})
	\end {htmlonly}\\
	[s->title]

[END]
\end {itemize}

\label {list-task-parameters}
\subsection {remind\_task}

	\default {no default value}

This parameter states which model is used to create a \texttt {remind} task. 
A \texttt {remind} task regurlaly sends to the subscribers a message which reminds them
their subscription to list.

example :

remind annual

\subsection {expire\_task}

	\default {no default value}

This parameter states which model is used to create a \texttt {remind} task.
A \texttt {expire} task regurlaly checks the inscription or reinscription date of subscribers
and asks them to renew their subscription. If they don't they are deleted.


example :

expire annual

\subsection {send}
    \label {par-send}

	\default {private}

	\scenarized {send}

This parameter specifies who can send messages to the list. Valid values for this
parameter are pointers to \emph {scenarios}.

\begin {itemize}
[FOREACH s IN scenari->send]
     \item \lparam {send} \texttt {[s->name]} 
	\begin {htmlonly}
	  (\htmladdnormallink {view} {http://www.sympa.org/distribution/current/src/etc/scenari/send.[s->name]})
	\end {htmlonly}\\
	[s->title]

[END]
\end {itemize}


\subsection {review}
    \label {par-review}

	\default {owner}

	\scenarized {review}

This parameter specifies who can use
\mailcmd {REVIEW} (see~\ref {cmd-review}, page~\pageref {cmd-review}),
administrative requests. 

Predefined authorization scenarios are :

\begin {itemize}
[FOREACH s IN scenari->review]
     \item \lparam {review} \texttt {[s->name]} 
	\begin {htmlonly}
	  (\htmladdnormallink {view} {http://www.sympa.org/distribution/current/src/etc/scenari/review.[s->name]})
	\end {htmlonly}\\
	[s->title]

[END]
\end {itemize}


\subsection {shared\_doc}
    \label {par-shared}
    \index{shared}

This paragraph defines read and edit access to the shared document 
repository.

\subsubsection {d\_read}

	\default {private}

	\scenarized {d\_read}

This parameter specifies who can read shared documents
(access the contents of a list's \dir {shared} directory).

Predefined authorization scenarios are :

\begin {itemize}
[FOREACH s IN scenari->d_read]
     \item \lparam {d\_read} \texttt {[s->name]} 
	\begin {htmlonly}
	  (\htmladdnormallink {view} {http://www.sympa.org/distribution/current/src/etc/scenari/d_read.[s->name]})
	\end {htmlonly}\\
	[s->title]

[END]
\end {itemize}


\subsubsection {d\_edit}

	\default {owner}

	\scenarized {d\_edit}

This parameter specifies who can perform changes
within a list's \dir {shared} directory (i.e. upload files
and create subdirectories).

Predefined authorization scenarios are :

\begin {itemize}
[FOREACH s IN scenari->d_edit]
     \item \lparam {d\_edit} \texttt {[s->name]} 
	\begin {htmlonly}
	  (\htmladdnormallink {view} {http://www.sympa.org/distribution/current/src/etc/scenari/d_edit.[s->name]})
	\end {htmlonly}\\
	[s->title]

[END]
\end {itemize}


Example:
\begin {quote}
\begin{verbatim}
shared_doc
d_read		public
d_edit		private
\end{verbatim}
\end {quote}

\subsubsection {quota}

\lparam {quota} \textit {number-of-Kbytes}

This parameter specifies the disk quota (the unit is Kbytes) for the document repository, in kilobytes.
If quota is exceeded, file uploads fail.

\section {List tuning}

\subsection {reply\_to\_header}
    \label {par-reply-to-header}

The \lparam {reply\_to\_header} parameter starts a paragraph defining
	what \Sympa will place in the \rfcheader {Reply-To} SMTP header field of
	the messages it distributes.

\begin {itemize}

\item \lparam {value}   \texttt {sender} \texttt{|}
    			\texttt {list}   \texttt{|}
    			\texttt {all}    \texttt{|}
    			\texttt {other\_email}
	\default {sender}

	This parameter indicates whether the \rfcheader {Reply-To} field
	should indicate the sender of the message (\texttt {sender}),
	the list itself (\texttt {list}), both list and sender (\texttt {all})
        or an arbitrary e-mail address (defined by the
	\lparam {other\_email} parameter).

Note: it is inadvisable to change this parameter, and particularly inadvisable to
set it to \texttt {list}. Experience has shown it to be almost inevitable that users,
mistakenly believing that they are replying only to the sender, will send private
messages to a list. This can lead, at the very least, to embarrassment, and sometimes
to more serious consequences.

\item \lparam {other\_email} \textit {an\_email\_address}

	If \lparam {value} was set to \texttt {other\_email}, this parameter
	defines the e-mail address used.

\item \lparam {apply}   \texttt {respect} \texttt{|}
    			\texttt {forced}  
	\default {respect}

	The default is to respect (preserve) the existing \rfcheader {Reply-To} SMTP header field
	in incoming messages. If set to \texttt {forced}, \rfcheader {Reply-To} SMTP header
	field will be overwritten.

\end {itemize}

Example :
\begin {quote}
\begin{verbatim}
reply_to_header
value other_email
other_email listowner@my.domain
apply forced
\end{verbatim}
\end {quote}

\subsection {max\_size}
 \label {par-max-size}
 \index{max-size}

	\default {\cfkeyword {max\_size} robot parameter}

\lparam {max\_size} \textit {number-of-bytes}

Maximum size of a message in 8-bit bytes. The default value is set in
 the \file {[CONFIG]} file.


\subsection {anonymous\_sender}
    	\label {par-anonymous-sender}
    	\index{anonymous\_sender}

	\lparam {anonymous\_sender} \textit {value}

If this parameter is set for a list, all messages distributed via the list are
rendered anonymous. SMTP \texttt {From:} headers in distributed messages are altered
to contain the value of the \lparam {anonymous\_sender} parameter. Various other
fields are removed (\texttt {Received:, Reply-To:, Sender:, 
X-Sender:, Message-id:, Resent-From:}

\subsection {custom\_header}
    	\label {par-custom-header}
    	\index{custom-header}

	\lparam {custom\_header} \textit {header-field}\texttt {:} \textit {value}

This parameter is optional. The headers specified
will be added to the headers of messages distributed via the
list. As of release 1.2.2 of \Sympa, it is possible to put several
custom header lines in the configuration file at the same time.

\example {custom\_header X-url: http://www.cru.fr/listes/apropos/sedesabonner.faq.html}.

\subsection {rfc2369\_header\_fields}
    	\label {par-rfc2369-header-fields}
    	\index{rfc2369-header-fields}

	\default {\cfkeyword {rfc2369\_header\_fields} sympa.conf parameter}
	\lparam {rfc2369\_header\_fields} \textit {help,archive}

RFC2369 compliant header fields (List-xxx) to be added to distributed messages. 
These header-fields should be implemented by MUA's, adding menus.

\subsection {loop\_prevention\_regex}
    	\label {par-loop-prevention-regex}
    	\index{loop-prevention-regex}

	\default {\cfkeyword {loop\_prevention\_regex} sympa.conf parameter}
	\lparam {loop\_prevention\_regex} \textit {mailer-daemon|sympa|listserv|majordomo|smartlist|mailman}

This regular expression is applied to messages sender address. If the sender address matches the regular expression, then
the message is rejected. The goal of this parameter is to prevent loops between Sympa and other robots.

\subsection {custom\_subject}

	\label {par-custom-subject}
	\index{custom-subject}

	\lparam {custom\_subject} \textit {value}

[STOPPARSE]
This parameter is optional. It specifies a string which is
added to the subject of distributed messages (intended to help
users who do not use automatic tools to sort incoming messages).
This string will be surrounded by [] characters.

The custom subject can also refer to list variables ([list->sequence] in the example bellow).

\example {custom\_subject sympa-users}.

\example {custom\_subject newsletter num [list->sequence]}.
[STARTPARSE]

\subsection {footer\_type}
    	\label {par-footer-type}
	\index{footer-type}

	\default {mime}

\lparam {footer\_type (optional, default value is mime)}
   \texttt {mime} \texttt{|}
   \texttt {append}

List owners may decide to add message headers or footers to messages
sent via the list. This parameter defines the way a footer/header is
added to a message.

\begin {itemize}
\item  \lparam {footer\_type} \texttt {mime}

       The default value. Sympa will add the
       footer/header as a new MIME part. If the message is in
       multipart/alternative format, no action is taken (since this would require another
       level of MIME encapsulation).


\item  \lparam {footer\_type} \texttt {append} 

        Sympa will not create new MIME parts, but
        will try to append the header/footer to the body of the
        message. \file {[EXPL_DIR]/\samplelist/message.footer.mime} will be
        ignored. Headers/footers may be appended to text/plain
        messages only.


\end {itemize}

\subsection {digest}

    	\label {par-digest}
    	\index{digest}

	\lparam {digest} \textit {daylist} \textit {hour}\texttt {:}\textit {minutes}

Definition of \lparam {digest} mode. If this parameter is present,
subscribers can select the option of receiving messages in multipart/digest
MIME format.  Messages are then grouped together, and compilations of messages
are sent to subscribers in accordance with the rythm selected
with this parameter.

\textit {Daylist} designates a list of days in the week in number
format (from 0 for Sunday to 6 for Saturday), separated by commas.

\example {digest 1,2,3,4,5 15:30} 

In this example, \Sympa sends digests at 3:30 PM from Monday to Friday.

\textbf {WARNING}: if the sending time is too late (ie around midnight), \Sympa may not
be able to process it in time. Therefore do not setuse a digest time
later than 23:00.

N.B.: In family context, \lparam{digest} can be constrainted only on days.

\subsection {\cfkeyword {digest\_max\_size}} 
 
	\default {25}
 
 	Maximum number of messages in a digest. If the number of messages exceeds this limit, then multiple 
 	digest messages are sent to each recipient.
 
\subsection {available\_user\_options}

    	\label {par-available-user-options}
	\index{available-user-options}

	The \lparam {available\_user\_options} parameter starts a paragraph to
	define available options for the subscribers of the list.

\begin {itemize}
   \item \lparam {reception} \textit {modelist}

	\default {\cfkeyword {reception} mail,notice,digest,summary,nomail}

\textit {modelist} is a list of modes (mail, notice, digest, summary, nomail),
separated by commas. Only these modes will be allowed for the subscribers of
this list. If a subscriber has a reception mode not in the list, sympa uses
the mode specified in the \textit {default\_user\_options} paragraph.

\end {itemize}

Example :
\begin {quote}
\begin{verbatim}
## Nomail reception mode is not available
available_user_options
reception  	digest,mail
\end{verbatim}
\end {quote}


\subsection {default\_user\_options}

    	\label {par-default-user-options}
	\index{default-user-options}

	The \lparam {default\_user\_options} parameter starts a paragraph to
	define a default profile for the subscribers of the list.

\begin {itemize}
    \item \lparam {reception}
            \texttt {notice} \texttt{|}
            \texttt {digest} \texttt{|}
            \texttt {summary} \texttt{|}
            \texttt {nomail} \texttt{|}
            \texttt {mail}

        Mail reception mode.

    \item \lparam {visibility}
            \texttt {conceal} \texttt{|}
            \texttt {noconceal} 

        Visibility of the subscriber with the \mailcmd {REVIEW}
        command.

\end {itemize}

Example :
\begin {quote}
\begin{verbatim}
default_user_options
reception  	digest
visibility	noconceal
\end{verbatim}
\end {quote}

\subsection {msg\_topic}

    	\label {par-msg-topic}
	\index{msg-topic}

	The \lparam {msg\_topic} parameter starts a paragraph to
	define a message topic used to tag a message. Foreach message topic, 
        you have to define a new paragraph.(See \ref {msg-topics}, page~\pageref {msg-topics})

\textit {Example:} 
\begin {quote}
\begin{verbatim}
msg_topic
name os
keywords linux,mac-os,nt,xp
title Operating System
\end{verbatim}
\end {quote}

Parameter \lparam{msg\_topic.name} and \lparam{msg\_topic.title} are mandatory. \lparam{msg\_topic.title} is used
on the web interface (``other'' is not allowed for msg\_topic.name parameter). The \lparam{msg\_topic.keywords} parameter allows to select automatically message topic by searching 
keywords in the message. 


N.B.: In a family context, \lparam{msg\_topic.keywords} parameter is uncompellable.

\subsection {msg\_topic\_keywords\_apply\_on}

    	\label {par-msg-topic-key-apply-on}
	\index{msg-topic-keywords-apply-on}

	The \lparam {msg\_topic\_keywords\_apply\_on} parameter defines on which part of the message is used to perform
	automatic tagging.(See \ref {msg-topics}, page~\pageref {msg-topics})

\textit {Example:} 
\begin {quote}
\begin{verbatim}
msg_topic_key_apply_on subject
\end{verbatim}
\end {quote}  
Its values can be : subject \(\mid\) body\(\mid\) subject\_and\_body.

\subsection {msg\_topic\_tagging}

    	\label {par-msg-topic-tagging}
	\index{msg-topic-tagging}

	The \lparam {msg\_topic\_tagging} parameter indicates if the tagging is optional or required for a list.
	(See \ref {msg-topics}, page~\pageref {msg-topics})

\textit {Example:} 
\begin {quote}
\begin{verbatim}
msg_topic_tagging optional
\end{verbatim}
\end {quote}  
Its values can be : optional \(\mid\) required

\subsection {pictures\_feature}

    	\label {par-pictures}
	\index{pictures}

	\default {\cfkeyword {pictures\_feature} robot parameter}

\lparam {pictures\_feature} \textit {on | off}

This enables the feature that allows list members to upload a picture that will be shown on review page.


\subsection {cookie}

    	\label {par-cookie}
	\index{cookie}

	\default {\cfkeyword {cookie} robot parameter}

\lparam {cookie} \textit {random-numbers-or-letters}

This parameter is a confidential item for generating \textindex
{authentication} keys for administrative commands (\mailcmd {ADD},
\mailcmd {DELETE}, etc.).  This parameter should remain concealed,
even for owners. The cookie is applied to all list owners, and is
only taken into account when the owner has the \lparam {auth}
parameter (\lparam {owner} parameter, see~\ref {par-owner},
page~\pageref {par-owner}).

\example {cookie secret22}

\subsection {priority}
    \label {par-priority}

	\default {\cfkeyword {default\_list\_priority} robot parameter}

\lparam {priority} \textit {0-9}

The priority with which \Sympa will process messages for this list.
This level of priority is applied while the message is going through the spool. 

0 is the highest priority. The following priorities can be used:  
\texttt {0...9~z}.
\texttt {z} is a special priority causing messages to
remain spooled indefinitely (useful to hang up a list).

Available since release 2.3.1.

\section {Bounce related}

\subsection {bounce}
    \label {bounce}

This paragraph defines bounce management parameters :

\begin{itemize}

\item
\label {warn-rate}
\lparam {warn\_rate} 

	\default {\cfkeyword {bounce\_warn\_rate} robot parameter}

	The list owner receives a warning whenever a message is distributed and
	the number (percentage) of bounces exceeds this value.

\item
\label {halt-rate}
\lparam {halt\_rate} 

	\default {\cfkeyword {bounce\_halt\_rate} robot parameter}

	\texttt {NOT USED YET}

	If bounce rate reaches the \texttt {halt\_rate}, messages 
	for the list will be halted, i.e. they are retained for subsequent 
	moderation. Once the number of bounces exceeds this value,
	messages for the list are no longer distributed. 

\item
\label {expire-bounce-task}
\lparam {expire\_bounce\_task} 

	\default daily

	Name of the task template use to remove old bounces. Usefull to
        remove bounces for a subscriber email if some message are
        distributed without receiving new bounce. In this case, the
        subscriber email seems to be OK again. Active if
        task\_manager.pl is running. 
	
\end{itemize}

\textit {Example:} 

\begin {quote}
\begin{verbatim}
## Owners are warned with 10% bouncing addresses
## message distribution is halted with 20% bouncing rate
bounce
warn_rate	10
halt_rate	20
\end{verbatim}
\end {quote}


\subsection {bouncers\_level1}
    \label {bouncerslevel1}

\begin{itemize}

\item
\label {rate}
\lparam {rate} 

	\default {\cfkeyword {bouncers\_level1\_rate} config parameter}

	 Each bouncing user have a score (from 0 to 100).This parameter define the lower score 
	 for a user to be a \"level1 bouncing user\". For example, with default values : Users with a score
	 between 45 and 80 are level1 bouncers.
\item
\label {action}
\lparam {action} 

	\default {\cfkeyword {bouncers\_level1\_action} config parameter}

	This parameter define which task is automaticaly applied on level 1 bouncing
	users: for exemple, automaticaly notify all level1 users.

\item
\label {notification}
\lparam {Notification} 

	\default {owner}

	When automatic task is executed on level 1 bouncers, a notification
	email can be send to listowner or listmaster. This email contain the adresses
	of concerned users and the name of the action executed.

\end{itemize}

\subsection {bouncers\_level2}
    \label {bouncers-level2}

\begin{itemize}

\item
\label {rate2}
\lparam {rate} 

	\default {\cfkeyword {bouncers\_level2\_rate} config parameter}

	 Each bouncing user have a score (from 0 to 100).This parameter define the lower score 
	 for a user to be a \"level 2 bouncing user\". For example, with default values : Users with a score
	 between 75 and 100 are level 2 bouncers.
\item
\label {action2}
\lparam {action} 

	\default {\cfkeyword {bouncers\_level1\_action} config parameter}

	This parameter define which task is automaticaly applied on level 2 bouncing
	users: for exemple, automaticaly notify all level1 users.

\item
\label {Notification2}
\lparam {Notification} 

	\default {owner}

	When automatic task is executed on level 2 bouncers, a notification
	email can be send to listowner or listmaster. This email contain the adresses
	of concerned users and the name of the action executed.

\end{itemize}

\textit {Example:} 

\begin {quote}
  \begin{verbatim}
    ## All bouncing adresses with a score between 75 and 100 
    ## will be unsubscribed, and listmaster will recieve an email
    Bouncers level 2
    rate :75 Points
    action : remove\_bouncers 
    Notification : Listmaster
   
  \end{verbatim}
\end {quote}

\subsection {welcome\_return\_path}
\label {welcome-return-path}

	\default {\cfkeyword {welcome\_return\_path} robot parameter}
	\lparam {welcome\_return\_path} unique \texttt{|} owner

	If set to \cfkeyword {unique}, the welcome message is sent using
        a unique return path in order to remove the subscriber immediately in
	the case of a bounce. See \cfkeyword {welcome\_return\_path} \file {sympa.conf}
	parameter (\ref{kw-welcome-return-path}, page~\pageref{kw-welcome-return-path}).

\subsection {remind\_return\_path} 
\label {remind-return-path}

	\default {\cfkeyword {remind\_return\_path} robot parameter}
	\lparam {remind\_return\_path} unique \texttt{|} owner

	Same as \cfkeyword {welcome\_return\_path}, but applied to remind
        messages. See \cfkeyword {remind\_return\_path} \file {sympa.conf}
	parameter (\ref{kw-remind-return-path}, page~\pageref{kw-remind-return-path}).

\subsection {verp\_rate} 
\label {verp-rate}

	\default {\cfkeyword {verp\_rate} host parameter}

        See \ref {verp},page~\pageref {verp} for more information on VERP in Sympa.

        When \cfkeyword {verp\_rate} is null VERP is not used ; if  \lparam {verp\_rate} is 100\% VERP is alway in use.

	VERP requires plussed aliases to be supported and the bounce+* alias to be installed.


\section {Archive related}

\Sympa maintains 2 kinds of archives: mail archives and web archives.

Mail archives can be retrieved via a mail command send to the robot,
they are stored in \dir {[EXPL_DIR]/\samplelist/archives/} directory.

Web archives are accessed via the web interface (with access control), they
are stored in a directory defined in \file {wwsympa.conf}.

\subsection {archive}
    \label {par-archive}
    \index{archive}

If the \file {config} file contains an \lparam {archive} paragraph
\Sympa will manage an archive for this list.

\textit {Example:} 

\begin {quote}
\begin{verbatim}
archive
period week
access private
\end{verbatim}
\end {quote}

If the \lparam {archive} parameter is specified, archives are
accessible to users through the \mailcmd {GET} command, 
and the index of the list archives is provided in reply to the \mailcmd {INDEX}
command (the last message of a list can be consulted using the \mailcmd {LAST} command).


\lparam {period}
    \texttt {day} \texttt{|}
    \texttt {week} \texttt{|}
    \texttt {month} \texttt{|}
    \texttt {quarter} \texttt{|}
    \texttt {year}


This parameter specifies how archiving is organized: by \texttt
{day}, \texttt {week}, \texttt {month}, \texttt {quarter},
or \texttt {year}.  Generation of automatic list archives requires
the creation of an archive directory at the root of the list directory 
(\dir {[EXPL_DIR]/\samplelist/archives/}), used to store these documents.

\lparam {access}
    \texttt {private} \texttt{|}
    \texttt {public} \texttt{|}
    \texttt {owner} \texttt{|}
    \texttt {closed} \texttt{|}


This parameter specifies who is authorized to use the \mailcmd {GET}, \mailcmd {LAST} and \mailcmd {INDEX} commands.


\subsection {web\_archive}
    \label {par-web-archive}
    \index{web\_archive}

If the \file {config} file contains a \lparam {web\_archive} paragraph
\Sympa will copy all messages distributed via the list to the
"queueoutgoing"  spool. It is intended to be used with WWSympa html
archive tools. This paragraph must contain at least the access
parameter to control who can browse the web archive.

\textit {Example:} 

\begin {quote}
\begin{verbatim}
web_archive
access private
quota 10000
\end{verbatim}
\end {quote}

\subsubsection {access}

    \scenarized {access\_web\_archive}

Predefined authorization scenarios are :

\begin {itemize}
[FOREACH s IN scenari->access_web_archive]
     \item \lparam {access} \texttt {[s->name]} 
	\begin {htmlonly}
	  (\htmladdnormallink {view} {http://www.sympa.org/distribution/current/src/etc/scenari/access_web_archive.[s->name]})
	\end {htmlonly}\\
	[s->title]

[END]
\end {itemize}

\subsubsection {quota}

\lparam {quota} \textit {number-of-Kbytes}

This parameter specifies the disk quota for the list's web archives, in kilobytes. This parameter's default is
\cfkeyword {default\_archive\_quota} \file {sympa.conf} parameter. If quota is exceeded, messages are no more 
archived, list owner is notified. When archives are 95\% full, the list owner is warned.

\subsection {archive\_crypted\_msg}
\label {archive-crypted-msg}

	\default {cleartext}

	\lparam {archive\_crypted\_msg} cleartext \texttt{|} decrypted

	This parameter defines Sympa behavior while archiving S/MIME crypted messages.
	If set to \texttt {cleartext} the original crypted form of the message will
	be archived ; if set to  \texttt {decrypted} a decrypted message will be
	archived. Note that this apply to both mail and web archives ; also to
	digests.

\section {Spam protection}

\subsection {spam\_protection}  

    \index{spam\_protection}
	\default {\cfkeyword {spam\_protection} robot parameter}

	There is a need to protection Sympa web site against spambot which collect
        email adresse in public web site. Various method are available into Sympa
        and you can choose it with \cfkeyword {spam\_protection} and
        \cfkeyword {web\_archive\_spam\_protection} parameters.
        Possible value are :
\begin {itemize}
\item javascript : the adresse is hidden using a javascript. User who enable javascript can
see a  nice mailto adresses where others have nothing.
\item at : the @ char is replaced by the string " AT ".
\item none : no protection against spammer.
\end{itemize}


\subsection {web\_archive\_spam\_protection}
	\default {\cfkeyword {web\_archive\_spam\_protection} robot parameter}

	Idem \cfkeyword {spam\_protection} but restricted to web archive.
        A additional value is available : cookie which mean that users
        must submit a small form in order to receive a cookie before
        browsing archives. This block all robot, even google and co.

\section {Intern parameters}
   

\subsection {family\_name}
     \label {par-family-name}
     \index{family\_name}

This parameter indicates the name of the family that the list belongs to. 

\textit {Example:} 

\begin {quote}
\begin{verbatim}
family_name my_family
\end{verbatim}
\end {quote}

\subsection {latest\_instantiation}
     \label {par-latest-instantiation}
     \index{latest\_instantiation}

This parameter indicates the date of the latest instantiation.

\textit {Example:} 

\begin {quote}
\begin{verbatim}
latest_instantiation
email serge.aumont@cru.fr
date 27 jui 2004 at 09:04:38
date_epoch 1090911878
\end{verbatim}
\end {quote}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Reception mode 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\cleardoublepage
\chapter {Reception mode}
    \label {reception-mode}
    \index{reception mode}

\section {Message topics}
\label{msg-topics}
\index{message topic}

A list can be configured to have message topics (this notion is different from topics used to class
mailing lists). Users can subscribe to these message topics in order to receive a subset of distributed messages :
a message can have one or more topics and subscribers will receive only messages that have been 
tagged with a topic they are subscribed to. A message can be tagged automatically, by the message 
sender or by the list moderator.

\subsection {Message topic definition in a list}

Available message topics are defined by list parameters. Foreach new message topic, create a new \lparam{msg\_topic} paragraph
that defines the name and the title of the topic. If a thread is identified for the current message then the automatic procedure is performed.
Else, to use automatic tagging, you should define keywords (See (\ref {par-msg-topic}, page~\pageref {par-msg-topic}) 
To define which part of the message is used for automatic tagging
you have to define \lparam{msg\_topic\_keywords\_apply\_on} list parameter (See \ref {par-msg-topic-key-apply-on}, 
page~\pageref {par-msg-topic-key-apply-on}). Tagging a message can be optional or it can be required, depending on the
\lparam{msg\_topic\_tagging} list parameter (See (\ref {par-msg-topic-tagging},page~\pageref {par-msg-topic-tagging}).

\subsection {Subscribing to message topic for list subscribers}

This functionnality is only available via ``normal'' reception mode. Subscribers can select message topic to receive messages tagged with this topic.
To receive messages that were not tagged, users can subscribe to the topic ``other''. Message topics selected by a subscriber are stored in \Sympa 
database (subscriber\_table table).

\subsection {Message tagging}

First of all, if one or more \lparam{msg\_topic.keywords} are defined, \Sympa tries to tag messages automatically. 
To trigger manual tagging, by message sender or list moderator, on the web interface, \Sympa uses authorization scenarios : if the resulted action is ``editorkey'' 
(for example in scenario send.editorkey), the list moderator is asked to tag the message. 
If the resulted action is ``request\_auth'' (for example in scenario send.privatekey), the message sender is asked to tag the message. 
The following variables are available as scenario variables to customize tagging : topic, topic-sender, topic-editor, topic-auto, topic-needed.
(See (\ref {scenarios}, page~\pageref {scenarios}) If message tagging is required and if it was not yet performed, \Sympa will ask to the list moderator.


Tagging a message will create a topic information file in the \dir {[SPOOLDIR]/topic/} spool. Its name is based on the listname and the Message-ID. 
For message distribution, a ``X-Sympa-Topic'' field is added to the message to allow members to use mail filters.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Shared documents
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\cleardoublepage
\chapter {Shared documents}
    \label {shared}
    \index{shared}

Shared documents are documents that different users can manipulate
on-line via the web interface of \Sympa, provided that the are authorized
to do so. A shared space is associated with a list, and users of the list 
can upload, download, delete, etc, documents in the shared space.

\WWSympa shared web features are fairly rudimentary. It is not our aim to provide
a sophisticated tool for web publishing, such as are provided by products
like \textit {Rearsite}.
It is nevertheless very useful to be able to define privilege on
web documents in relation to list attributes such as \textit {subscribers},
\textit {list owners}, or \textit {list editors}. 

All file and directory names are lowercased by Sympa. It is consequently
impossible to create two different documents whose names differ only
in their case. The reason Sympa does this is to allow correct URL links
even when using an HTML document generator (typically Powerpoint) which uses 
random case for file names!

In order to have better control over the documents and to enforce security in
the shared space, each document is linked to a set of specific control information : 
its access rights.

A list's shared documents are stored in the \dir {[EXPL_DIR]/\samplelist/shared}
directory. 

This chapter describes how the shared documents are managed, 
especially as regards their access rights. 
We shall see :  

\begin {itemize}
       	\item the kind of operations which can be performed on shared documents 

        \item access rights management  

        \item access rights control specifications
	
	\item actions on shared documents
        
	\item template files
\end {itemize}

\section {The three kind of operations on a document}
    \label {shared-operations}
Where shared documents are concerned, there are three kinds of operation which
have the same constraints relating to access control :
\begin{itemize}
	\item The read operation :\\
	\begin{itemize}
		\item If applied on a directory, opens it and lists its contents (only those
		sub-documents the user is authorized to ``see'').
		\item If applied on a file, downloads it, and in the case of a viewable file (\textit {text/plain}, \textit {text/html},
		or image), displays it. 
	\end{itemize}
	\item The edit operation allows :\\
		\begin{itemize}
		\item Subdirectory creation
		\item File uploading
		\item File unzipping
		\item Description of a document (title and basic information)
		\item On-line editing of a text file
		\item Document (file or directory) removal. If on a directory, it must be empty.
		\end{itemize}
	These different edit actions are equivalent as regards access rights. Users who are
	authorized to edit a directory can create a subdirectory or upload a file to it,
	as well as describe or delete it. Users authorized to edit a file can edit
	it on-line, describe it, replace or remove it.  
	\item The control operation :\\
	The control operation is directly linked to the notion of access rights. If we wish
	shared documents to be secure, we have to control the access to them. Not everybody
	must be authorized to do everything to them. Consequently, each document has
	specific access rights for reading and editing. Performing a control action on a document
	involves changing its Read/Edit rights.\\
	The control operation has more restrictive access rights than the other two operations.
	Only the owner of a document, the privileged owner of the list and the listmaster have
	control rights on a document. Another possible control action on a document is therefore
	specifying who owns it.  
\end{itemize}
	


\section {The description file}
\label {shared-desc-file}
The information (title, owner, access rights...) relative to each document must be stored, and so
each shared document is linked to a special file called a description file, whose name includes
the \file {.desc} prefix.

The description file of a directory having the path \dir {mydirectory/mysubdirectory} has the path
\dir {mydirectory/mysubdirectory/.desc} .
The description file of a file having the path \dir {mydirectory/mysubdirectory/myfile.myextension} has the path
\dir {mydirectory/mysubdirectory/.desc.myfile.myextension} .

\subsection {Structure of description files}

The structure of a document (file or directory) description file is given below.
You should \textit {never} have to edit a description file.
 
\begin {quote}
\begin{verbatim}
title
  <description of the file in a few words>

creation
  email        <e-mail of the owner of the document> 
  date_epoch   <date_epoch of the creation of the document>

access
 read <access rights for read>
 edit <access rights for edit>
\end{verbatim}
\end {quote}

The following example is for a document that subscribers can read, but which only the owner of the document
and the owner of the list can edit.
\begin {quote}
\begin{verbatim}
title
  module C++ which uses the class List

creation
  email foo@some.domain.com
  date_epoch 998698638

access
 read  private
 edit  owner
\end{verbatim}
\end {quote}

\section {The predefined authorization scenarios}
    \label {shared-scenarios}

\subsection {The public scenario}
The \textbf {public} scenario is the most permissive scenario. It enables anyone (including
unknown users) to perform the corresponding action.

\subsection {The private scenario}
The \textbf {private} scenario is the basic scenario for a shared space. Every subscriber of
the list is authorized to perform the corresponding action. The \textbf {private} scenario is the default
read scenario for \dir {shared} when this shared space is created. This can be modified by editing
the list configuration file.

\subsection {The scenario owner}
The scenario \textbf {owner} is the most restrictive scenario for a shared space.
Only the listmaster, list owners and the owner of the document
(or those of a parent document) are allowed to perform the corresponding action.
The \textbf {owner} scenario is the default scenario for editing. 

\subsection {The scenario editor}
The scenario \textbf {editor} is for a moderated shared space for editing. Every suscriber of the list is 
allowed to editing a document. But this document will have to be installed or rejected by the editor of the 
list. Documents awaiting for moderation are visible by their author and the editor(s) of the list in the
shared space. The editor has also an interface with all documents awaiting. When there is a new document,
the editor is notiied and when the document is installed, the author is notiied too. In case of reject, 
the editor can notify the author or not.  


\section {Access control}
    \label {shared-access}
Access control is an important operation performed
every time a document within the shared space is accessed.

The access control relative to a document in the hierarchy involves an iterative
operation on all its parent directories. 

\subsection {Listmaster and privileged owners}
The listmaster and privileged list owners are special users in the shared
web. They are allowed to perform every action on every document in
the shared space. This privilege enables control over
the shared space to be maintained. It is impossible to prevent the listmaster and
privileged owners from performing whatever action they please on any document
in the shared space.
 
\subsection {Special case of the \dir {shared} directory}
In order to allow access to a root directory to be more restrictive than
that of its subdirectories, the \dir {shared} directory (root directory) is
a special case as regards access control.
The access rights for read and edit are those specified in the list configuration file.
Control of the root directory is specific. 
Only those users authorized to edit a list's configuration may change access rights on
its \dir {shared} directory. 
 
\subsection {General case}
\dir {mydirectory/mysubdirectory/myfile} is an arbitrary document in the shared space,
but {not} in the \textit {root} directory. A user \textbf {X} wishes to perform one
of the three operations (read, edit, control) on this document.
The access control will proceed as follows :
\begin{itemize}
	\item Read operation\\
	To be authorized to perform a read action on
	\dir {mydirectory/mysubdirectory/myfile}, \textbf {X} must be
	authorized to read every document making up the path; in other words, she
	must be allowed to read \dir {myfile} (the authorization scenario of the description file
	of \dir {myfile} must return \textit {do\_it} for user \textbf {X}), and the
	same goes for \dir {mysubdirectory} and \dir {mydirectory}).\\
	In addition, given that the owner of a document or one of its parent directories
	is allowed to perform \textbf {all actions on that document},
	\dir {mydirectory/mysubdirectory/myfile} may also have read operations performed
	on it by the owners of \dir {myfile}, \dir {mysubdirectory},
	and \dir {mydirectory}.

	This can be schematized as follows :
\begin {quote}
\begin{verbatim}
	X can read <a/b/c> 

	if			  

	(X can read <c>
	AND X can read <b>
	AND X can read <a>)
					
	OR

	(X owner of <c>
	OR X owner of <b>
	OR X owner of <a>)
\end{verbatim}			
\end {quote}

	\item Edit operation\\
	The access algorithm for edit is identical to the algorithm for read :
\begin {quote}
\begin{verbatim}
	X can edit <a/b/c> 
	
	if 
		
	(X can edit <c>
	AND X can edit <b>				
	AND X can edit <a>)
					
	OR

	(X owner of <c>
	OR X owner of <b>
	OR X owner of <a>)
\end{verbatim}			
\end {quote}

	\item Control operation\\
	The access control which precedes a control action (change rights
	or set the owner of a document) is much more restrictive.
	Only the owner of a document or the owners of a parent
	document may perform a control action :
\begin {quote}
\begin{verbatim}
	X can control <a/b/c> 

	if
					
	(X owner of <c>
	OR X owner of <b>
	OR X owner of <a>)
\end{verbatim}			
\end {quote}

\end{itemize}

\section {Shared document actions}

The shared web feature has called for some new actions.
\begin{itemize}
	\item action D\_ADMIN\\
	Create the shared web, close it or restore it. The d\_admin action is accessible
	from a list's \textbf {admin} page.
	\item action D\_READ\\
	Reads the document after read access control. If a folder, lists all the subdocuments that can
	be read. If a file, displays it if it is viewable, else downloads it to disk.
	If the document to be read contains a file named \file {index.html} or \file {index.htm}, and if
	the user has no permissions other than read on all contained subdocuments, the read action will
	consist in displaying the index.
	The d\_read action is accessible from a list's \textbf {info} page.
	\item action D\_CREATE\_DIR\\
	Creates a new subdirectory in a directory that can be edited without moderation. 
	The creator is the owner of the directory. The access rights are
	those of the parent directory.
	\item action D\_DESCRIBE\\
	Describes a document that can be edited.
	\item action D\_DELETE\\
	Deletes a document after edit access control. If applied to a folder, it has to be empty.
	\item action D\_UPLOAD\\
	Uploads a file into a directory that can be edited.  
	\item action D\_UNZIP\\
	Unzip a file into a directory that can be edited without moderation. The whole file hierarchy contained in the zip file
	is installed into the directory.
	\item action D\_OVERWRITE\\
	Overwrites a file if it can be edited. The new owner of the file is the one who has done
	the overwriting operation.
	\item actions D\_EDIT\_FILE and D\_SAVE\_FILE\\
	Edits a file and saves it after edit access control. The new owner of the file is the one 
	who has done the saving operation. 
	\item action D\_CHANGE\_ACCESS\\
	Changes the access rights of a document (read or edit), provided that control of this document is
	authorized. 
	\item action D\_SET\_OWNER\\
	Changes the owner of a directory, provided that control of this document is
	authorized. The directory must be empty. The new owner can be anyone, but authentication is necessary
	before any action may be performed on the document.

\end{itemize}

\section {Template files}
The following template files have been created for the shared web:

\subsection {d\_read.tt2} 
The default page for reading a document. If for a file, displays it (if 
viewable) or downloads it. If for a directory, displays all readable
subdocuments, each of which will feature buttons corresponding
to the different actions this subdocument allows. If the directory is
editable, displays buttons to describe it or upload a file to it. If the
directory is editable without moderation, it displays button to
create a new subdirector or to upload a zip file in order to install a file hierarchy. 
If access to the document is editable,
displays a button to edit the access to it. 

\subsection {d\_editfile.tt2} 
The page used to edit a file. If for a text file, allows it to be edited on-line.
This page also enables another file to be substituted in its place.

\subsection {d\_control.tt2}
The page to edit the access rights and the owner of a document. 

\subsection {d\_upload.tt2}
This page to upload a file is only used when the name of the file already exists.

\subsection {d\_properties.tt2}
This page is used to edit description file and to rename it.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Using Sympa commands
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\cleardoublepage
\chapter {Bounce management}

\Sympa allows bounce (non-delivery report) management. This
prevents list owners from receiving each bounce (1 per message
sent to a bouncing subscriber) in their own mailbox. Without
automatic processing of bounces, list owners either go
mad, or just delete them without further attention.

Bounces are received at \samplelist-owner address (note that the -owner 
suffix can be customized, see~\ref {kw-return-path-suffix}, 
page~\pageref {kw-return-path-suffix}), which should
be sent to the \file {bouncequeue} program via aliases :

\begin {quote}
\begin{verbatim}
	\samplelist-owner: "|[MAILERPROGDIR]/bouncequeue \samplelist"
\end{verbatim}
\end {quote}

\file {bouncequeue} (see \ref{binaries}, page~\pageref{binaries}) stores bounces in a
\dir {[SPOOLDIR]/bounce/} spool.

Bounces are then processed by the \file {bounced.pl} daemon.
This daemon analyses bounces to find out which
e-mail addresses are concerned and what kind of error was generated.
If bouncing addresses match a subscriber's address, information 
is stored in the \Sympa database (in subscriber\_table). Moreover, the most recent
bounce itself is archived in \dir {bounce\_path/\samplelist/email}
(where bounce\_path is defined in a \file {wwsympa.conf} parameter and
email is the user e-mail address).

When reviewing a list, bouncing addresses are tagged as bouncing.
You may access further information such as dates of first and last bounces,
number of received bounces for the address, the last bounce itself.

With these informations, the automatic bounce management is possible:

\begin{itemize}

\item
  The automatic task \cfkeyword {eval\_bouncer} gives a score foreach bouncing user.
  The score, between 0 to 100, allows the classification of bouncing users in two levels.
  (Level 1 or 2). 
  According to the level, automatic actions are executed periodicaly by \cfkeyword {process\_bouncers}
  task.

\item The score evaluation main parameters are: 
  
  \cfkeyword {Bounces count}: The number of bouncing messages received by sympa for the user.

  \cfkeyword {Type rate} : Bounces are classified depending on the type of errors generated on the user
  side. If the error type is "mailbox is full" (ie a temporary 4.2.2 error type) the type rate will be
  0.5 whereas permanent errors (5.x.x) have a type rate equal to 1.

  \cfkeyword {Regularity rate} : This rate tells if the bounces where received regularly, compared to list
 traffic. The list traffic is deduced from \file {msg\_count} file data.


  \begin {quote}
    \begin{verbatim}
      The score formula is  :
  
      Score = bounce_count * type_rate * regularity_rate

    \end{verbatim}
  \end {quote}


  To avoid making decisions (ie defining a score) without enough relevant data, the score is not
  evaluated if :
	
\begin {itemize}
	\item The number of the number of received bounces is lower than \cfkeyword {minimum\_bouncing\_count} 
	(see \ref {kw-minimum-bouncing-count}, page~\pageref {kw-minimum-bouncing-count})

	\item The bouncing period is shorter than \cfkeyword {minimum\_bouncing\_period} 
	(see \ref {kw-minimum-bouncing-period}, page~\pageref {kw-minimum-bouncing-period})

\end {itemize}
  
Bouncing list members entries get expired after a given period of time. The default period is 10 days but it can 
be customized if you write a new \textbf {expire\_bounce} task (see \ref {kw-expire-bounce-task} ,page~\pageref {kw-expire-bounce-task}).

\item
  You can define the limit between each level via the \textbf {List configuration pannel}, 
  in subsection \textbf {Bounce settings}. (see \ref {rate}) The principle consists in
  associating a score interval with a level.

\item 
  You can also define which action must be applied on each category of user.(see \ref {action})
  Each time an action will be done, a notification email will be send to the person of your choice.
  (see \ref {notification})


%It's possible to add your own actions, by editing the task \cfkeyword {process\_bouncers}
%in the \file {task\_manager.pl}: 
%- First, just add in the Hash \cfkeyword {\%actions} 
%the location of your action subroutine (by default in \file {List.pm}), 
%- Then add the name of your action in the Hash \cfkeyword {\%::pinfo} 
%(file:\file {List.pm}), in the field \cfkeyword {bouncers\_levelX->bounce\_level1\_action->format}

\end{itemize}

\section {VERP}
\label {verp}

	VERP (Variable Envelop Return Path) is used to ease automatic recognition of
        subscribers email address when receiving a bounce. If VERP is enabled, the subscriber address is encoded
        in the return path itself so Sympa bounce management processus (bounced) will use the address the bounce
        was received for to retreive the subscriber email. This is very usefull because sometimes, non delivery
        report don't contain the initial subscriber email address but an alternative address where messages
        are forwarded. VERP is the only solution to detect automaticaly these subscriber errors but the cost
        of VERP is significant, indeed VERP requires to distribute a separate message for each subscriber and
        break the bulk emailer grouping optimization.

	In order to benefit from VERP and keep distribution process fast, Sympa enables VERP only for a share
        of the list members. If texttt \cfkeyword {verp\_rate} (see \ref {kw-verp-rate},page~\pageref {kw-verp-rate}) is 10\% then after 10 messages distributed in the list
        all subscribers have received at least one message where VERP was enabled. Later distribution message enable
        VERP also for all users where some bounce wer collected and analysed by previous VERP mechanism. 


	If VERP is enabled, the format of the messages return path are as follows :
\begin {quote}
\begin{verbatim}
Return-Path: <bounce+user==a==userdomain==listname@listdomain>
\end{verbatim}
\end {quote}
        Note that you need to set a mail alias for the generic bounce+* alias (see \ref {robot-aliases},
page~\pageref {robot-aliases}).

\section {ARF}
\label {ARF}

 ARF (Abuse Feedback Reporting Format) is standard for reporting abuse. It is
implemented mainly in AOL email user interface. Aol server propose to mass mailer to received automatically the users complain by formated messages. Because many subscribers don't want to remind
how to unsubscribe tey use ARF when provided by user interface. It may usefull to configure the ARF managment in Sympa. It really simple : all what you have to do is to create a new alias for
each virtual robot as the following :

\begin {quote}
\begin{verbatim}
abuse-feedback-report:       "| [MAILERPROGDIR]/bouncequeue sympa@\samplerobot"\\
\end{verbatim}
\end {quote}

Then register this address as your loop back email address with ISP (for exemple AOL). This way messages to that email adress are processed by bounced deamon and opt-out opt-out-list abuse and automatically processed. If bounce service can remove a user the message report feedback is forwarded to the list owner. Unrecognize message are forwarded to the listmaster.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Using Sympa commands
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\cleardoublepage
\chapter {Antivirus}
\label {antivirus}

\Sympa lets you use an external antivirus solution to check incoming mails.
In this case you must set the \cfkeyword {antivirus\_path} and 
\cfkeyword {antivirus\_args} configuration parameters
 (see \ref {Antivirus plug-in}, page~\pageref {Antivirus plug-in}.
\Sympa is already compatible with McAfee/uvscan, Fsecure/fsav, Sophos, AVP, Trend Micro/VirusWall and Clam Antivirus.
For each mail received, \Sympa extracts its MIME parts in the \dir {[SPOOLDIR]/tmp/antivirus} directory and
then calls the antivirus software to check them.
When a virus is detected, \Sympa looks for the virus name in the virus scanner STDOUT and sends a
\file {your\_infected\_msg.tt2} warning to the sender of the mail.
The mail is saved as 'bad' and the working directory is deleted (except if \Sympa is running in debug mode).
  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Using Sympa with LDAP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\cleardoublepage
\chapter {Using \Sympa with LDAP}
\label {ldap}

\textindex {LDAP} is a client-server protocol for accessing a directory service. Sympa
provide various features based on access to one or more LDAP directories :

\begin{itemize}

	\item{authentication using LDAP directory instead of sympa internal storage of password}\\
	  see ~\ref {auth-conf}, page~\pageref {auth-conf}

	\item{named filters used in authorization scenario condition}\\ 
	  see ~\ref {named-filters}, page~\pageref {named-filters}
	
 	\item{LDAP extraction of list subscribers (see ~\ref {par-user-data-source})}\\         

	\item{LDAP extraction of list owners or editors}\\  
	  see ~\ref {data-inclusion-file}, page~\pageref {data-inclusion-file}

	\item{mail aliases stored in LDAP}\\
	  see ~\ref {ldap-aliases}, page~\pageref {ldap-aliases}
	
\end{itemize}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SMIME
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


\cleardoublepage
\chapter {\Sympa with S/MIME and HTTPS}
    \label {smime}

S/MIME is a cryptographic method for Mime messages based on X509 certificates.
Before installing \Sympa S/Mime features (which we call S/Sympa), you should be
under no illusion about what the S stands for : ``S/MIME'' means ``Secure MIME''.
That S certainly does not stand for ``Simple''.

The aim of this chapter is simply to describe what security level is provided
by \Sympa while
using S/MIME messages, and how to configure \Sympa for it. It is not intended
to teach anyone what S/Mime is and why it is so complex ! RFCs numbers 2311,
2312, 2632, 2633 and 2634, along with a lot of literature about S/MIME, PKCS\#7
and PKI is available on the Internet. \Sympa 2.7 is the first version of
\Sympa to include S/MIME features as beta-testing features.

\section {Signed message distribution}

No action required.
You probably imagine that any mailing list manager (or any mail forwarder)
is compatible with S/MIME signatures, as long as it respects the MIME structure of
incoming messages. You are right. Even Majordomo can distribute a signed message!
As \Sympa provides MIME compatibility, you don't need to do
anything in order to allow subscribers to verify signed messages distributed
through a list. This is not an issue at all, since any processe that
distributes messages  is compatible with end user
signing processes. Sympa simply skips the message footer attachment
(ref \ref {messagefooter}, page~\pageref {messagefooter}) to prevent any
body corruption which would break the signature.

\section {Use of S/MIME signature by Sympa itself}
    \label {smime-sig}

Sympa is able to verify S/MIME signatures in order to apply S/MIME
authentication methods for message handling. 
Currently, this feature is limited to the
distribution process, and to any commands \Sympa might find in the message
body.  The reasons for this restriction are related to current S/MIME
usage.
S/MIME signature structure is based on the encryption of a digest of the
message. Most S/MIME agents do not include any part of the
message headers in the message digest, so anyone can modify the message
header without signature corruption! This is easy to do : for example, anyone
can edit a signed message with their preferred message agent, modify whatever
header they want (for example \texttt {Subject:} , \texttt {Date:} and
\texttt {To:}, and redistribute the message to a list or to the robot
without breaking the signature.

So Sympa cannot apply the S/MIME
authentication method to a command parsed in the \texttt {Subject:} field of a
message or via the \texttt {-subscribe} or \texttt {-unsubscribe} e-mail
address. 

\section {Use of S/MIME encryption} 

S/Sympa is not an implementation of the ``S/MIME Symmetric Key Distribution''
internet draft. This sophisticated scheme is required for large lists
with encryption. So, there is still some scope for future developments :) 


We assume that S/Sympa distributes message as received, i.e. unencrypted when the
list receives an unencrypted message, but otherwise encrypted.

In order to be able to send encrypted messages to a list, the sender needs
to use the X509 certificate of the list. Sympa will send an encrypted message
to each subscriber using the subscriber's certificate. To provide this feature,
\Sympa needs to manage one certificate for each list and one for each
subscriber. This is available in Sympa version 2.8 and above.

\section {S/Sympa configuration} 

\subsection {Installation}
\label {smimeinstall}

The only requirement is OpenSSL (http://www.openssl.org) version 0.9.5a and above.
OpenSSL is used by \Sympa as an external plugin
(like sendmail or postfix), so it must be installed with the appropriate access
(x for sympa.sympa). 

\subsection {managing user certificates}
\label {smimeusercert}

User certs are automatically catched by Sympa when receiving a signed s/mime messsage 
so if Sympa needs to send encrypted message to this user it can perform encryption 
using this certificate. This works fine but it's not conpliant with the PKI theory : 
Sympa should be able to search for user certificates using PKI certificate directory (LDAP) .

That's why Sympa tests the key usage certificate attribute to known if the certificate 
allows both encryption and signature.

Certificates are stored as PEM files in the \dir {[EXPL_DIR]/X509-user-certs/} directory. 
Files are named user@some.domain@enc or user@some.domain@sign  (@enc and @sign suffix 
are used according to certificates usage.  No other tool is provided by Sympa in order 
to collect this certificate repository but you can easily imagine your own tool to create 
those files. 

\subsection {configuration in sympa.conf}
\label {smimeconf}

S/Sympa configuration is very simple. If you are used to Apache SSL,
you should not feel lost. If you are an OpenSSL guru, you will
feel at home, and there may even be changes you will wish to suggest to us.
 
The basic requirement is to let \Sympa know where to find the binary file for the OpenSSL program
and the certificates of the trusted certificate authority. 
This is done using the optional parameters \unixcmd {openSSL} and
\cfkeyword {capath} and / or \cfkeyword {cafile}.

\begin{itemize}

  \item \cfkeyword {openSSL} : the path for the OpenSSL binary file,
         usually \texttt {/usr/local/ssl/bin/openSSL}
  \item \cfkeyword {cafile} : the path of a bundle of trusted ca certificates. 
        The file \tildefile {[ETCBINDIR]/ca\-bundle.crt} included in Sympa distribution can be used.

	Both the \cfkeyword  {cafile} file and the \cfkeyword {capath} directory
        should be shared with your Apache+mod\_ssl configuration. This is useful
	for the S/Sympa web interface.  Please refer to the OpenSSL documentation for details.

  \item \cfkeyword {key\_password} : the password used to protect all list private keys. xxxxxxx	
\end{itemize}


\subsection {configuration to recognize S/MIME signatures}
\label {smimeforsign}

Once  \texttt {OpenSSL} has been installed, and \texttt {sympa.conf} configured,
your S/Sympa is ready to use S/Mime signatures for any authentication operation. You simply need
to use the appropriate authorization scenario for the operation you want to secure. 
(see \ref {scenarios}, page~\pageref {scenarios}).

When receiving a message, \Sympa applies
the authorization scenario with the appropriate authentication method parameter.
In most cases the authentication method is ``\texttt {smtp}'', but in cases
where the message is signed and the signature has been checked and matches the
sender e-mail, \Sympa applies the ``\texttt {smime}'' authentication
method.

It is vital to ensure that if the authorization scenario does not recognize this authentication method, the
operation requested will be rejected. Consequently, authorization scenarios distributed
prior to version 2.7 are not compatible with the OpenSSL configuration of Sympa. 
All
standard authorization scenarios (those distributed with sympa)
now include the \texttt {smime} method. The following example is
named \texttt {send.private\_smime}, and restricts sends to subscribers using an S/mime signature :

\begin {quote}
\begin{verbatim}
[STOPPARSE]
title.us restricted to subscribers check smime signature
title.fr limité aux abonnés, vérif de la signature smime

is_subscriber([listname],[sender])             smime  -> do_is_editor([listname],[sender])                 smime  -> do_it
is_owner([listname],[sender])                  smime  -> do_it
[STARTPARSE]
\end{verbatim}
\end {quote}

It as also possible to mix various authentication methods in a single authorization scenario. The following
example, \texttt {send.private\_key}, requires either an md5 return key or an S/Mime signature :
\begin {quote}
\begin{verbatim}
[STOPPARSE]
title.us restricted to subscribers with previous md5 authentication
title.fr réservé aux abonnés avec authentification MD5 préalable

is_subscriber([listname],[sender]) smtp          -> request_auth
true()                             md5,smime     -> do_it
[STARTPARSE]
\end{verbatim}
\end {quote}

\subsection {distributing encrypted messages}
\label {smimeforencrypt}

In this section we describe S/Sympa encryption features. The goal is to use
S/MIME encryption for distribution of a message to subscribers whenever the message has been
received encrypted from the sender. 

Why is S/Sympa concerned by the S/MIME encryption distribution process ?
It is because encryption is performed using the \textbf {recipient} X509
certificate, whereas the signature requires the sender's private key. Thus, an encrypted
message can be read by the recipient only if he or she is the owner of the private
key associated with the certificate.
Consequently, the only way to encrypt a message for a list of recipients is
to encrypt and send the message for each recipient. This is what S/Sympa
does when distributing an encrypted message.

The S/Sympa encryption feature in the distribution process supposes that Sympa
has received an encrypted message for some list. To be able to encrypt a message
for a list, the sender must have some access to an X509 certificate for the list.
So the first requirement is to install a certificate and a private key for
the list.
The mechanism whereby certificates are obtained and managed is complex. Current versions
of S/Sympa assume that list certificates and private keys are installed by
the listmaster using \dir {[SCRIPTDIR]/p12topem.pl} script. This script allows
you to install a PKCS\#12 bundle file containing a private key and
a certificate using the appropriate format.

It is a good idea to have a look at the OpenCA (http://www.openssl.org)
documentation and/or PKI providers' web documentation.
You can use commercial certificates or home-made ones. Of course, the
certificate must be approved for e-mail applications, and issued by one of
the trusted CA's described in the \cfkeyword{cafile} file or the
\cfkeyword{capath} Sympa configuration parameter. 

The list private key must be installed in a file named
\dir {[EXPL_DIR]/\samplelist/private\_key}. All the list private
keys must be encrypted using a single password defined by the
\cfkeyword {password} parameter in \cfkeyword {sympa.conf}.

\subsubsection {Use of navigator to obtain X509 list certificates}

In many cases e-mail X509 certificates are distributed via a web server and
loaded into the browser using your mouse :) Mozilla or internet explorer allows
certificates to be exported to a file.

Here is a way to install a certificat for a list:

\begin {itemize} 
\item Get a list certificate is to obtain an personal e-mail
certificate for the canonical list address in your browser as if it was your personal certificate, 

\item export the intended certificate
it. The format used by Netscape is  ``pkcs\#12''. 
Copy this file to the list home directory.
\item convert the pkcs\#12 file into a pair of pem files :
\cfkeyword {cert.pem} and \cfkeyword {private\_key} using
the \unixcmd {[SCRIPTDIR]/p12topem.pl} script. Use \unixcmd
{p12topem.pl -help} for details.
\item be sure that \cfkeyword {cert.pem} and \cfkeyword {private\_key}
are owned by sympa with ``r'' access.
\item As soon as a certificate is installed for a list, the list  home page
includes a new link to load the certificate to the user's browser, and the welcome
message is signed by the list.
\end {itemize} 


\section {Managing certificates with tasks}

You may automate the management of certificates with two global task models provided with
\Sympa. See \ref {tasks}, page~\pageref {tasks} to know more about tasks.
Report to \ref {certificate-task-config}, page~\pageref {certificate-task-config} to configure your \Sympa to use these facilities.

\subsection {chk\_cert\_expiration.daily.task model}

A task created with the model \file {chk\_cert\_expiration.daily.task} checks every day the expiration date of
certificates stored in the \dir {[EXPL_DIR]/X509-user-certs/} directory.
The user is warned with the \file {daily\_cert\_expiration} template when his certificate has expired
or is going to expire within three days.

\subsection {crl\_update.daily.task model}

You may use the model \file {crl\_update.daily.task} to create a task which daily updates the certificate revocation
lists when needed.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Using Sympa commands
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\cleardoublepage
\chapter {Using \Sympa commands}

Users interact with \Sympa, of course, when they send messages to
one of the lists, but also indirectly through administrative requests
(subscription, list of users, etc.).

This section describes administrative requests, as well as interaction
modes in the case of private and moderated lists.  Administrative
requests are messages whose body contains commands understood by
\Sympa, one per line. These commands can be indiscriminately placed
in the \rfcheader {Subject} or in the body of the message. The
\rfcheader {To} address is generally the \mailaddr {sympa{\at}domain}
alias, although it is also advisable to recognize the \mailaddr
{listserv{\at}domain} address.

Example:

\begin {quote}
\begin{verbatim}
From: pda@prism.uvsq.fr
To: sympa@cru.fr

LISTS
INFO sympa-users
REVIEW sympa-users
QUIT
\end{verbatim}
\end {quote}

Most user commands have three-letter abbreviations (e.g. \texttt
{REV} instead of \mailcmd {REVIEW}).

\section {User commands}

\begin {itemize}
    \item  \mailcmd {HELP}

        Provides instructions for the use of \Sympa commands.  The
        result is the content of the \file {helpfile.tt2} template
        file. 

    \item  \mailcmd {INFO} \textit {listname}

[STOPPARSE]
        Provides the parameters of the specified list (owner,
        subscription mode, etc.) and its description. The
        result is the content of \tildefile {welcome[.mime]}.
[STARTPARSE]

    \item  \mailcmd {LISTS}
        \label {cmd-lists}

        Provides the names of lists managed by \Sympa.  This list
        is generated dynamically, using the \lparam {visibility}
        (see \ref {par-visibility}, page~\pageref {par-visibility}).
	The \texttt {lists.tt2} template defines the message return
	by the \mailcmd {LISTS} command.

    \item  \mailcmd {REVIEW} \textit {listname}
        \label {cmd-review}

        Provides the addresses of subscribers if the run mode authorizes it. 
	See the \lparam {review} parameter (\ref {par-review}, page~\pageref
        {par-review}) for the configuration file of each list,
        which controls consultation authorizations for the subscriber
        list. Since subscriber addresses can be abused by spammers,
        it is strongly recommended that you \textbf {only authorize owners
        to access the subscriber list}.

    \item  \mailcmd {WHICH}
         \label {cmd-which}

        Returns the list of lists to which one is subscribed,
        as well as the configuration of his or her subscription to
        each of the lists (DIGEST, NOMAIL, SUMMARY, CONCEAL).

\item  \mailcmd {STATS} \textit {listname}
        \label {cmd-stats}

        Provides statistics for the specified list:
        number of messages received, number of messages sent,
        megabytes received, megabytes sent. This is the contents
        of the \file {stats} file.

	Access to this command is controlled by the \lparam {review} parameter.

    \item  \mailcmd {INDEX} \textit {listname}
        \label {cmd-index}

        Provides index of archives for specified list. Access rights
        to this function are the same as for the \mailcmd {GET}
        command. 

    \item  \mailcmd {GET} \textit {listname} \textit {archive}
        \label {cmd-get}

        To retrieve archives for list (see above).  Access
        rights are the same as for the \mailcmd {REVIEW} command.
        See \lparam {review} parameter (\ref {par-review},
        page~\pageref {par-review}).

    \item  \mailcmd {LAST} \textit {listname}
        \label {cmd-last}

        To receive the last message distributed in a list (see above).  Access
        rights are the same as for the \mailcmd {GET} command.

    \item  \mailcmd {SUBSCRIBE} \textit {listname firstname name}
        \label {cmd-subscribe}

        Requests sign-up to the specified list. The \textit
        {firstname} and \textit {name} are optional. If the
        list is parameterized with a restricted subscription (see
        \lparam {subscribe} parameter, \ref {par-subscribe},
        page~\pageref {par-subscribe}), this command is sent to the
        list owner for approval.

    \item  \mailcmd {INVITE} \textit {listname user@host name}
        \label {cmd-invite}

        Invite someone to subscribe to the specified list. The 
        \textit {name} is optional. The command is similar to the
        \mailcmd {ADD} but the specified person is not added to the
        list but invited to subscribe to it in accordance with the 
        \lparam {subscribe} parameter, \ref {par-subscribe},
        page~\pageref {par-subscribe}).


    \item  \mailcmd {SIGNOFF} \textit {listname} [ \textit {user@host} ]
        \label {cmd-signoff}

        Requests unsubscription from the specified list.
        \mailcmd {SIGNOFF *} means unsubscription from all lists.

    \item  \mailcmd {SET} \textit {listname} \texttt {DIGEST}
        \label {cmd-setdigest}

        Puts the subscriber in \textit {digest} mode for the \textit
        {listname} list.  Instead of receiving mail from the list
        in a normal manner, the subscriber will periodically receive
        it in a DIGEST. This DIGEST compiles a group of messages
        from the list, using multipart/digest mime format.

        The sending period for these DIGESTs is regulated by the
        list owner using the \lparam {digest} parameter (see~\ref
        {par-digest}, page~\pageref {par-digest}).  See the \mailcmd
        {SET~LISTNAME~MAIL} command (\ref {cmd-setmail}, page~\pageref
        {cmd-setmail}) and the \lparam {reception} parameter (\ref
        {par-reception}, page~\pageref {par-reception}).

    \item  \mailcmd {SET} \textit {listname} \texttt {SUMMARY}
        \label {cmd-setsummary}

        Puts the subscriber in \textit {summary} mode for the \textit
        {listname} list.  Instead of receiving mail from the list
        in a normal manner, the subscriber will periodically receive
        the list of messages. This mode is very close to the DIGEST
        reception mode but the subscriber receives only the list of messages.

        This option is available only if the digest mode is set.

    \item  \mailcmd {SET} \textit {listname} \texttt {NOMAIL}
        \label {cmd-setnomail}

        Puts subscriber in \textit {nomail} mode for the \textit
        {listname} list.  This mode is used when a subscriber no longer wishes
        to receive mail from the list, but nevertheless wishes to retain
        the possibility of posting to the list.
        This mode therefore prevents the subscriber from unsubscribing
        and subscribing later on.  See the \mailcmd {SET~LISTNAME~MAIL}
        command (\ref {cmd-setmail}, page~\pageref {cmd-setmail}) and
        the \lparam {reception} (\ref {par-reception}, page~\pageref
        {par-reception}). 

    \item  \mailcmd {SET} \textit {listname} \texttt {TXT}
        \label {cmd-settxt}

        Puts subscriber in \textit {txt} mode for the \textit
        {listname} list.  This mode is used when a subscriber wishes
        to receive mails sent in both format txt/html and txt/plain 
        only in txt/plain format.
        See the \lparam {reception} (\ref {par-reception}, page~\pageref
        {par-reception}). 

    \item  \mailcmd {SET} \textit {listname} \texttt {HTML}
        \label {cmd-sethtml}

        Puts subscriber in \textit {html} mode for the \textit
        {listname} list.  This mode is used when a subscriber wishes
        to receive mails sent in both format txt/html and txt/plain 
        only in txt/html format.
        See the \lparam {reception} (\ref {par-reception}, page~\pageref
        {par-reception}). 

    \item  \mailcmd {SET} \textit {listname} \texttt {URLIZE}
        \label {cmd-seturlize}

        Puts subscriber in \textit {urlize} mode for the \textit
        {listname} list.  This mode is used when a subscriber wishes
        not to receive attached files. The attached files are replaced by
        an URL leading to the file stored on the list site. 
        
        See the \lparam {reception} (\ref {par-reception}, page~\pageref
        {par-reception}). 

    \item  \mailcmd {SET} \textit {listname} \texttt {NOT\_ME}
        \label {cmd-not-me}

        Puts subscriber in \textit {not\_me} mode for the \textit
        {listname} list.  This mode is used when a subscriber wishes
        not to receive back the message that he has sent to the list. 
        
        See the \lparam {reception} (\ref {par-reception}, page~\pageref
        {par-reception}). 

    \item  \mailcmd {SET} \textit {listname} \texttt {MAIL}
        \label {cmd-setmail}

        Puts the subscriber in normal mode (default) for the \textit
        {listname} list.  This option is mainly used to cancel the
        \textit {nomail}, \textit {summary} or \textit {digest} modes. If the subscriber
        was in \textit {nomail} mode, he or she will again receive
        mail from the list in a normal manner.  See the \mailcmd
        {SET~LISTNAME~NOMAIL} command (\ref {cmd-setnomail},
        page~\pageref {cmd-setnomail}) and the \lparam {reception}
        parameter (\ref {par-reception}, page~\pageref {par-reception}).
	Moreover, this mode allows message topic subscription  
	(\ref {msg-topics}, page~\pageref {msg-topics})

    \item  \mailcmd {SET} \textit {listname} \texttt {CONCEAL}
        \label {cmd-setconceal}

        Puts the subscriber in \textit {conceal} mode for the
        \textit {listname} list.  The subscriber will then become
        invisible during \mailcmd {REVIEW} on this list. Only owners
        will see the whole subscriber list.

        See the \mailcmd {SET~LISTNAME~NOCONCEAL} command (\ref
        {cmd-setnoconceal}, page~\pageref {cmd-setnoconceal}) and
        the \lparam {visibility} parameter (\ref {par-visibility},
        page~\pageref {par-visibility}).


    \item  \mailcmd {SET} \textit {listname} \texttt {NOCONCEAL}
        \label {cmd-setnoconceal}

        Puts the subscriber in \textit {noconceal} mode (default)
        for \textit {listname} list. The subscriber will then
        become visible during \mailcmd {REVIEW} of this list. The
        \textit {conceal} mode is then cancelled.

        See \mailcmd {SET~LISTNAME~CONCEAL} command (\ref
        {cmd-setconceal}, page~\pageref {cmd-setconceal}) and
        \lparam {visibility} parameter (\ref {par-visibility},
        page~\pageref {par-visibility}).


    \item  \mailcmd {QUIT}
        \label {cmd-quit}

        Ends acceptance of commands. This can prove useful when
        the message contains additional lines, as for example in
        the case where a signature is automatically added by the
        user's mail program (MUA).

    \item  \mailcmd {CONFIRM} \textit {key}
        \label {cmd-confirm}

        If the \lparam {send} parameter of a list is set to \texttt
        {privatekey, publickey} or \texttt {privateorpublickey},
        messages are only distributed in the list after an
        \textindex {authentication} phase by return mail, using a
        one-time password (numeric key). For this authentication,
        the sender of the message is requested to post the ``\mailcmd
        {CONFIRM}~\textit {key}'' command to \Sympa.

    \item  \mailcmd {QUIET}

        This command is used for silent (mute) processing: no
        performance report is returned for commands prefixed with
        \mailcmd {QUIET}.

\end {itemize}

\section {Owner commands}

Some administrative requests are only available to list owner(s).
They are indispensable for all procedures in limited access mode,
and to perform requests in place of users.
These comands are:

\begin {itemize}
    \item \mailcmd {ADD} \textit {listname user@host firstname name}
        \label {cmd-add}

        Add command similar to \mailcmd {SUBSCRIBE}. 
	You can avoid user notification by using the \mailcmd {QUIET}
	prefix (ie: \mailcmd {QUIET ADD}).

    \item \mailcmd {DELETE} \textit {listname user@host}
        \label {cmd-delete}

        Delete command similar to \mailcmd {SIGNOFF}.
	You can avoid user notification by using the \mailcmd {QUIET}
	prefix (ie: \mailcmd {QUIET DELETE}).

    \item \mailcmd {REMIND} \textit {listname}
	\label {cmd-remind}

        \mailcmd {REMIND} is used by list owners in order to send
        an individual service reminder message to each subscriber. This
        message is made by parsing the remind.tt2 file.

    \item \mailcmd {REMIND} \textit {*}

        \mailcmd {REMIND} is used by the listmaster to send to each subscriber of any list a single
        message with a summary of his/her subscriptions. In this case the 
        message sent is constructed by parsing the global\_remind.tt2 file.
        For each list, \Sympa tests whether the list is configured as hidden 
	to each subscriber (parameter lparam {visibility}). By default the use 
	of this command is restricted to listmasters. 
	Processing may take a lot of time !
	
\end {itemize}

As above, these commands can be prefixed with \mailcmd {QUIET} to
indicate processing without acknowledgment of receipt.


\section {Moderator commands}
    \label {moderation}

If a list is moderated, \Sympa only distributes messages enabled by one of
its moderators (editors). Moderators have several
methods for enabling message distribution, depending on the \lparam
{send} list parameter (\ref {par-send}, page~\pageref {par-send}).

\begin {itemize}
    \item  \mailcmd {DISTRIBUTE} \textit {listname} \textit {key}
        \label {cmd-distribute}

        If the \lparam {send} parameter of a list is set to \texttt
        {editorkey} or \texttt {editorkeyonly}, each message queued
        for \textindex {moderation} is stored in a spool (see~\ref
        {cf:queuemod}, page~\pageref {cf:queuemod}), and linked
        to a key.

        The \textindex {moderator} must use this command to enable
        message distribution.

    \item  \mailcmd {REJECT} \textit {listname} \textit {key}
        \label {cmd-reject}

        The message with the \textit {key} key is deleted from the
        moderation \textindex {spool} of the \textit {listname}
        list.

    \item  \mailcmd {MODINDEX} \textit {listname}
        \label {cmd-modindex}

        This command returns the list of messages queued for
        moderation for the \textit {listname} list.

        The result is presented in the form of an index, which
        supplies, for each message, its sending date, its sender,
        its size, and its associated key, as well as all
        messages in the form of a digest.

\end {itemize}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Internals
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\cleardoublepage
\chapter {Internals}
\label {internals}

This chapter describes these modules (or a part of) :
\begin {itemize}
  \item \file {src/mail.pm} : low level of mail sending
  \item \file {src/List.pm} : list processing and informations about structure and access to list configuration parameters  
  \item \file {src/sympa.pm} : the main script, for messages and mail commands processing. 
  \item \file {src/Commands.pm} : mail commands processing
  \item \file {src/wwsympa.pm} : web interface
  \item \file {src/report.pm} :  notification and error reports about requested services (mail and web)
  \item \file {src/tools.pm} : various tools 
  \item \file {src/Message.pm} : Message object used to encapsule a received message.
\end {itemize}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%% mail.pm %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\section {mail.pm}
\index{mail.pm}

This module deals with mail sending and does the SMTP job. It provides a function for message distribution to a list, 
the message can be encrypted. There is also a function to send service messages by parsing tt2 files, 
These messages can be signed.
For sending, a call to sendmail is done or the message is pushed in a spool according to calling context.

\subsection {public functions}

  mail\_file(), mail\_message(), mail\_forward(), set\_send\_spool(), reaper().


\subsubsection {\large{mail\_file()}}
\label{mail-mail-file}
\index{mail::mail\_file()}

   Message is written by parsing a tt2 file (or with a string ). It writes mail headers if they are missing and they are encoded. 
   Then the message is sent by calling mail::sending() function (see \ref {mail-sending}, page~\pageref {mail-sending}).

   \textbf{IN} : 
   \begin{enumerate}
     \item \lparam{filename} : string - tt2 filename \(\mid\) '' - no tt2 filename sent
     \item \lparam{rcpt} (+) : SCALAR \(\mid\) ref(ARRAY) - SMTP "RCPT To:" field
     \item \lparam{data} (+) : ref(HASH) - used to parse tt2 file, contains header values, keys are : 
       \begin{itemize}
         \item \lparam{return\_path} (+) : SMTP "MAIL From:" field \emph{if send by SMTP}, q
	                                "X-Sympa-From:" field \emph{if send by spool}
         \item \lparam{to} : "To:" header field \emph{else it is \$rcpt}
         \item \lparam{from} : "From:" field  \emph{if \$filename is not a full msg}
         \item \lparam{subject} : "Subject:" field \emph{if \$filename is not a full msg}
         \item \lparam{replyto} : "Reply-to:" field \emph{if \$filename is not a full msg}
         \item \lparam{headers} : ref(HASH), keys are other mail headers
         \item \lparam{body} : body message \emph{if not \$filename}
         \item \lparam{lang} : tt2 language \emph{if \$filename}  
         \item \lparam{list} : ref(HASH) \emph{if sign\_mode='smime'} - keys are :
	   \begin{itemize}
             \item \lparam{name} : list name
             \item \lparam{dir} : list directory
	   \end{itemize}
       \end{itemize}
     \item \lparam{robot} (+) : robot
     \item \lparam{sign\_mode} : 'smime'- the mail is signed with smime  \(\mid\)  undef - no signature 
   \end{enumerate}

   \textbf{OUT} : 1

\subsubsection   {\large{mail\_message()}}
\label{mail-mail-message}  
\index{mail::mail\_message()}

   Distributes a message to a list. The message is encrypted if needed, in this case, only one SMTP session is used for each recepient 
   otherwise, recepient are grouped by domain for sending (it controls the number recepient arguments to call sendmail). 
   Message is sent by calling mail::sendto() function (see \ref {mail-sendto}, page~\pageref {mail-sendto}).

   \textbf{IN} : 
   \begin{enumerate}
     \item \lparam{message} (+) : ref(Message) - message to distribute
     \item \lparam{from} (+) : message from
     \item \lparam{robot} (+) : robot
     \item \lparam{rcpt} (+) : ARRAY - recepients     
   \end{enumerate}

   \textbf{OUT} : \lparam{\$numsmtp} = number of sendmail process  \(\mid\)  undef 

\subsubsection   {\large{mail\_forward()}}
\label{mail-mail-forward}  
\index{mail::mail\_forward()}

   Forward a message by calling mail::sending() function (see \ref {mail-sending}, page~\pageref {mail-sending}).

   \textbf{IN} : 
   \begin{enumerate}
     \item \lparam{msg} (+) : ref(Message) \(\mid\) ref(MIME::Entity) \(\mid\) string - message to forward
     \item \lparam{from} (+) : message from
     \item \lparam{rcpt} (+) : ref(SCALAR) \(\mid\) ref(ARRAY) - recepients     
     \item \lparam{robot} (+) : robot
   \end{enumerate}

   \textbf{OUT} : 1 \(\mid\)  undef 

\subsubsection {\large{set\_send\_spool()}}
\label{mail-set-send-spool}  
\index{mail::set\_send\_spool()}

   Used by other processes than sympa.pl to indicate to send message by 
   writting message in spool instead of calling mail::smtpto() function (see \ref {mail-smtpto}, page~\pageref {mail-smtpto}). 
   The concerned spool is set in \lparam{\$send\_spool} global variable, used by mail::sending() function
  (see \ref {mail-sending}, page~\pageref {mail-sending}).

   \textbf{IN} : 
   \begin{enumerate}
     \item \lparam{spool} (+) : the concerned spool for sending.
   \end{enumerate}

   \textbf{OUT} : -

\subsubsection {\large{reaper()}}
\label{mail-reaper}  
\index{mail::reaper()}

   Non blocking function used to clean the defuncts child processes by waiting for them and then
   decreasing the counter. For exemple, this function is called by mail::smtpto() (see 
   \ref {mail-smtpto}, page~\pageref {mail-smtpto}), main loop of sympa.pl, task\_manager.pl,
   bounced.pl.

   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{block}
   \end{enumerate}

   \textbf{OUT} : the pid of the defunct process \(\mid\) -1 \emph{if there is no such child process}.


\subsection {private functions}

  sendto(), sending(), smtpto().

\subsubsection {\large{sendto()}}
\label{mail-sendto}
\index{mail::sendto()}

   Encodes subject header. Encrypts the message if needed. In this case, it checks if there is
   only one recepient. Then the message is sent by calling mail::sending() function 
   (see \ref {mail-sending}, page~\pageref {mail-sending}).

   \textbf{IN} : 
   \begin{enumerate}
     \item \lparam{msg\_header} (+) : ref(MIME::Head) - message header 
     \item \lparam{msg\_body} (+) : message body
     \item \lparam{from} (+) : message from
     \item \lparam{rcpt} (+) : ref(SCALAR) \(\mid\) ref(ARRAY) - message recepients (ref(SCALAR) for encryption)
     \item \lparam{robot} (+) : robot
     \item \lparam{encrypt} : 'smime\_crypted' the mail is encrypted with smime \(\mid\)  undef - no encryption
   \end{enumerate}

   \textbf{OUT} : 1 - sending by calling smtpto (sendmail) \(\mid\) 0 - sending by push in spool \(\mid\)  undef 

\subsubsection {\large{sending()}}
\label{mail-sending}
\index{mail::sending()}

   Signs the message according to \lparam{\$sign\_mode}. Chooses sending mode according to context. If \lparam{\$send\_spool} global variable is empty, the message is
   sent by calling mail::smtpto() function  (see \ref {mail-smtpto}, page~\pageref {mail-smtpto})
   else the message is written in spool \lparam{\$send\_spool} in order to be handled by sympa.pl process (because only this 
   is allowed to make a fork).
   When the message is pushed in spool, these mail headers are added :
   \begin{itemize}
     \item ``X-Sympa-To:'' : recepients
     \item ``X-Sympa-From:'' : from
     \item ``X-Sympa-Checksum:'' : to check allowed program to push in spool 
   \end{itemize}
   A message pushed in spool like this will be handled later by sympa::DoSendMessage() function 
   (see \ref {sympa-dosendmessage}, page~\pageref {sympa-dosendmessage})

   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{msg} (+) : ref(MIME::Entity) \(\mid\) string - message to send
      \item \lparam{rcpt} (+) : ref(SCALAR) \(\mid\) ref(ARRAY) - recepients (for SMTP : "RCPT To:" field)
      \item \lparam{from} (+) : for SMTP : "MAIL From:" field  \(\mid\) for spool sending : "X-Sympa-From" field
      \item \lparam{robot} (+) : robot 
      \item \lparam{listname} : listname \(\mid\) ''
      \item \lparam{sign\_mode} (+) : 'smime' \(\mid\) 'none'for signing
      \item \lparam{sympa\_email} : for the file name for spool sending
   \end{enumerate}

   \textbf{OUT} : 1 - sending by calling smtpto() (sendmail) \(\mid\) 0 - sending by pushing in spool \(\mid\)  undef 

\subsubsection {\large{smtpto()}}
\label{mail-smtpto}
\index{mail::smtpto()}

   Calls to sendmail for the recipients given as argument by making a fork and an exec. Before, 
   waits for number of children process \(<\) number allowed by sympa.conf by calling mail::reaper() function
   (see \ref {mail-reaper}, page~\pageref {mail-repaer}).

   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{from} (+) : SMTP "MAIL From:" field
      \item \lparam{rcpt} (+) : ref(SCALAR)) \(\mid\) ref(ARRAY) - SMTP "RCPT To:" field
      \item \lparam{robot} (+) : robot 
   \end{enumerate}

   \textbf{OUT} : \lparam{mail::\$fh} - file handle on opened file for ouput, for SMTP "DATA" field \(\mid\) undef \\

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%% List.pm %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\section {List.pm}
\index{List.pm}

 This module includes list processing functions. 

 Here are described functions about : 
 \begin{itemize}
   \item Message distribution in a list
   \item Sending using templates
   \item Service messages
   \item Notification message
   \item Topic messages
   \item Scenario evaluation  
 \end{itemize}

 Follows a description of structure and access on list parameters.

%%%%%%%%%%%%%%% message distribution %%%%%%%%%%%%%%%%%%%%
\subsection {Functions for message distribution} 

   distribute\_message(), send\_msg(), send\_msg\_digest().

   These functions are used to message distribution in a list.

\subsubsection {\large{distribute\_msg()}}
\label{list-distribute-msg}
\index{List::distribute\_msg()}

   Prepares and distributes a message to a list : 
   \begin{itemize}
     \item updates the list stats
     \item Loads information from message topic file if exists and adds X-Sympa-Topic header  
     \item hides the sender if the list is anonymoused (list config : anonymous\_sender)
           and changes name of msg topic file if exists.
     \item adds custom subject if necessary (list config : custom\_subject)
     \item archives the message 
     \item changes the reply-to header if necessary (list config : reply\_to\_header)
     \item removes unwanted headers if present (config : remove\_headers))
     \item adds useful headers (X-Loop,X-Sequence,Errors-to,Precedence,X-no-archive - list config : custom\_header) 
     \item adds RFC 2919 header field (List-Id) and RFC 2369 header fields (list config : rfc2369\_header\_fields)
     \item stores message in digest if the list accepts digest mode (encrypted message can't be included in digest) 
     \item sends the message by calling List::send\_msg() (see \ref {list-send-msg}, 
           page~\pageref {list-send-msg}). 
   \end{itemize}

   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{self} (+) : ref(List) - the list concerned by distribution
      \item \lparam{message} (+): ref(Message) - the message to distribute
   \end{enumerate}

   \textbf{OUT} : result of List::send\_msg() function (number of sendmail process)


\subsubsection {\large{send\_msg()}}
\label{list-send-msg}
\index{List::send\_msg()}


  This function is called by List::distribute\_msg() (see \ref {list-distribute-msg}, 
  page~\pageref {list-distribute-msg})  to select subscribers
  according to their reception mode and to the ``Content-Type'' header field of the message.
  Sending are grouped according to their reception mode : \begin{itemize}
    \item normal : add a footer if the message is not protected (then the message is ``altered'')
          In a message topic context, selects only one who are subscribed to the topic of the
          message to distribute (calls to select\_subcribers\_for\_topic(), see \ref {list-select-subscribers-for-topic}, 
  page~\pageref {list-select-subscribers-for-topic}). 
    \item notice
    \item txt : add a footer 
    \item html : add a footer 
    \item urlize : add a footer and create an urlize directory for Web access
  \end{itemize}
  The message is sent by calling List::mail\_message() (see \ref {mail-mail-message}, 
  page~\pageref {mail-mail-message}). 
  If the message is ``smime\_crypted'' and the user has not got any certificate, a message service is sent to him.
 
   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{self} (+) : ref(List) - the list concerned by distribution
      \item \lparam{message} (+): ref(Message) - the message to distribute
   \end{enumerate}

   \textbf{OUT} : \lparam{\$numsmtp} : addition of mail::mail\_message() function results 
   ( = number of sendmail process ) \(\mid\) undef 

\subsubsection {\large{send\_msg\_digest()}}
\label{list-send-msg-digest}
\index{List::send\_msg\_digest()}

   Sends a digest message to the list subscribers with reception digest, digestplain or summary : 
   it creates the list of subscribers in various digest modes and then creates the list of
   messages. Finally sending to subscribers is done by calling List::send\_file() function
   (see \ref {list-send-file}, page~\pageref {list-send-file})
   with mail template ``digest'', ``digestplain'' or ``summary''.
   
   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{self} (+): ref(List) - the concerned list 
   \end{enumerate}

   \textbf{OUT} : \begin{itemize}
     \item 1  \emph{if sending} 
     \item 0  \emph{if no subscriber for sending digest, digestplain or summary} 
     \item undef
   \end{itemize}

%%%%%%%%%%%%%%% template sending %%%%%%%%%%%%%%%%%%%%%
\subsection {Functions for template sending} 

   send\_file(), send\_global\_file().

   These functions are used by others to send files. These files are made from template given in parameters.

\subsubsection {\large{send\_file()}}
\label{list-send-file}
\index{List::send\_file()}

   Sends a message to a user, relative to a list. It finds the \$tpl.tt2 file to make the message.
   If the list has a key and a certificat and if openssl is in the configuration, the message is signed.
   The parsing is done with variable \$data set up first with parameter \$context and then with configuration, here are 
   set keys :
   \begin{itemize}
     \item \emph{if \$who=SCALAR then} \begin{itemize}
                    \item \lparam{user.password}
		    \item \emph{if \$user key is not defined in \$context then} \lparam{user.email}(:= \$who), \lparam{user.lang} (:= list lang)  
		          \emph{and if the user is in DB then} \lparam{user.attributes} (:= attributes in DB user\_table) are defined
		    \item \emph{if \$who is subscriber of \$self then} \lparam{subscriber.date subscriber.update\_date}	  
			  \emph{and if exists then} \lparam{subscriber.bounce subscriber.first\_bounce} are defined
           \end{itemize}
     \item \lparam{return\_path} : used for SMTP ``MAIL From'' field or "X-Sympa-From:" field 
     \item \lparam{lang} : the user lang or list lang or robot lang
     \item \lparam{fromlist} : "From:" field, pointed on list
     \item \lparam{from} : "From:" field, pointed on list \emph{if no defined in \$context}
     \item \lparam{replyto} : \emph{if openssl is is sympa.conf and the list has a key ('private\_key') and a certificat ('cert.pem') in its directory}
     \item \lparam{boundary} : boundary for multipart message \emph{if no contained in \$context}
     \item \lparam{conf.email conf.host conf.sympa conf.request conf.listmaster conf.wwsympa\_url conf.title} : updated with robot config
     \item \lparam{list.lang list.name list.domain list.host list.subject list.dir list.owner}(ref(ARRAY)) : updated with list config
   \end{itemize}
   The message is sent by calling mail::mail\_file() function 
   (see \ref {mail-mail-file}, page~\pageref {mail-mail-file}).

   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{self} (+) : ref(List) 
      \item \lparam{tpl} (+) : template file name without .tt2 extension (\$tpl.tt2)
      \item \lparam{who} (+) : SCALAR \(\mid\) ref(ARRAY) - recepient(s)
      \item \lparam{robot} (+) : robot
      \item \lparam{context} : ref(HASH) - for the \$data set up 
   \end{enumerate}

   \textbf{OUT} : 1 \(\mid\) undef 


\subsubsection {\large{send\_global\_file()}}
\label{list-send-global-file}
\index{List::send\_global\_file()}

   Sends a message to a user not relative to a list. It finds the \$tpl.tt2 file to make the message.
   The parsing is done with variable \$data set up first with parameter \$context and then with configuration, here are 
   set keys :
   \begin{itemize}
     \item \lparam{user.password user.lang}
     \item \emph{if \$user key is not defined in \$context then} \lparam{user.email} (:= \$who)
     \item \lparam{return\_path} : used for SMTP ``MAIL From'' field or "X-Sympa-From:" field 
     \item \lparam{lang} : the user lang or robot lang
     \item \lparam{from} : "From:" field, pointed on SYMPA \emph{if no defined in \$context}
     \item \lparam{boundary} : boundary for multipart message \emph{if no defined in \$context}
     \item \lparam{conf.email conf.host conf.sympa conf.request conf.listmaster conf.wwsympa\_url conf.title} : updated with robot config
     \item \lparam{conf.version} : \Sympa version
     \item \lparam{robot\_domain} : the robot
    \end{itemize}
   The message is sent by calling mail::mail\_file() function 
   (see \ref {mail-mail-file}, page~\pageref {mail-mail-file}).

   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{tpl} (+) : template file name (filename.tt2), without .tt2 extension
      \item \lparam{who} (+) : SCALAR \(\mid\) ref(ARRAY) - recepient(s)
      \item \lparam{robot} (+) : robot
      \item \lparam{context} : ref(HASH) - for the \$data set up 
   \end{enumerate}

   \textbf{OUT} : 1 \(\mid\) undef 


%%%%%%%%%%%%%%% service messages %%%%%%%%%%%%%%%%%%%%%
\subsection {Functions for service messages} 

  archive\_send(), send\_to\_editor(), request\_auth(), send\_auth().

  These functions are used to send services messgase, correponding to a result of a command. 

\subsubsection {\large{archive\_send()}}
\label{list-archive-send}
\index{List::archive\_send()}

   Sends an archive file (\$file) to \$who. The archive is a text file, independant from web archives.
   It checks if the list is archived. Sending is done by callingList::send\_file() 
   (see \ref {list-send-file}, page~\pageref {list-send-file})
   with mail template ``archive''.
   
   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{self} (+): ref(List) - the concerned list 
      \item \lparam{who} (+): recepient
      \item \lparam{file} (+): name of the archive file to send
   \end{enumerate}

   \textbf{OUT} : - \(\mid\) undef 

\subsubsection {\large{send\_to\_editor()}}
\label{list-send-to-editor}
\index{List::send\_to\_editor()}

   Sends a message to the list editor for a request concerning a message to distribute. 
   The message awaiting for moderation is named with a key and is set in the spool queuemod.
   The key is a reference on the message for editor.
   The message for the editor is sent by calling List::send\_file() (see \ref {list-send-file}, 
   page~\pageref {list-send-file}) with mail template ``moderate''. In msg\_topic context, the editor is 
   asked to tag the message.


   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{self} (+): ref(List) - the concerned list 
      \item \lparam{method} : 'md5' - for "editorkey" \(\mid\) 'smtp' - for "editor"
      \item \lparam{message} (+): ref(Message) - the message to moderate
   \end{enumerate}

   \textbf{OUT} : \$modkey - the moderation key for naming message waiting for moderation
          in spool queuemod. \(\mid\) undef 

\subsubsection {\large{request\_auth()}}
\label{list-request-auth}
\index{List::request\_auth()}

   Sends an authentification request for a requested command. The authentification request contains
   the command to be send next and it is authentified by a key. The message is
   sent to user by calling  List::send\_file() (see \ref {list-send-file}, 
   page~\pageref {list-send-file}) with mail template ``request\_auth''.

   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{self} : ref(List) \emph{not required if \$cmd = ``remind''}.
      \item \lparam{email}(+): recepient, the requesting command user
      \item \lparam{cmd} : 
	\begin{itemize}
          \item \emph{if \$self then} 'signoff' \(\mid\) 'subscribe' \(\mid\) 'add' \(\mid\) 'del' \(\mid\) 'remind'
          \item \emph{else} 'remind'	  
	\end{itemize}
      \item \lparam{robot} (+): robot
      \item \lparam{param} : ARRAY  
	\begin{itemize}
          \item 0 : used \emph{if \$cmd ='subscribe' \(\mid\) 'add' \(\mid\) 'del' \(\mid\) 'invite'} 
          \item 1 : used \emph{if \$cmd ='add'} 
	\end{itemize}
   \end{enumerate}

   \textbf{OUT} : 1 \(\mid\) undef 

\subsubsection {\large{send\_auth()}}
\label{list-send-auth}
\index{List::send\_auth()}

   Sends an authentifiaction request for a message sent for distribution.
   The message for distribution is copied in the authqueue spool to wait for confirmation by its sender .
   This message is named with a key. The request is sent to user by calling  List::send\_file() 
   (see \ref {list-send-file}, page~\pageref {list-send-file}) with mail template ``send\_auth''.
   In msg\_topic context, the sender is asked to tag his message.

   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{self}(+): ref(List) - the concerned list
      \item \lparam{message}(+): ref(Message) - the message to confirm
   \end{enumerate}

   \textbf{OUT} : \$modkey, the key for naming message waiting for confirmation in spool queuemod. \(\mid\) undef 

%%%%%%%%%%%%%%% message notification %%%%%%%%%%%%%%%%%%%%%
\subsection {Functions for message notification} 

   send\_notify\_to\_listmaster(), send\_notify\_to\_owner(), send\_notify\_to\_editor(), send\_notify\_to\_user().

   These functions are used to notify listmaster, list owner, list editor or user
   about events.

\subsubsection {\large{send\_notify\_to\_listmaster()}}
\label{list-send-notify-listmaster}
\index{List::send\_notify\_to\_listmaster()}

   Sends a notice to listmaster by parsing ``listmaster\_notification'' template. The template makes a specified or a 
   generic treatement according to variable \$param.type (:= \$operation parameter).
   The message is sent by calling List::send\_file() (see \ref {list-send-file}, page~\pageref {list-send-file})
   or List::send\_global\_file() (see \ref {list-send-global-file}, page~\pageref {list-send-global-file})
   according to the context  : global or list context.
   Available variables for the template are set up by this function, by \$param parameter and by 
   List::send\_global\_file() or List::send\_file().

   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{operation} (+) : notification type, corresponds to \$type in the template
      \item \lparam{robot} (+): robot
      \item \lparam{param} (+): ref(HASH) \(\mid\) ref (ARRAY) - values for variable used in the template  : 
	\begin{itemize}
	  \item \emph{if ref(HASH) then} variables used in the template are keys of this HASH. These following 
	    keys are required in the function, according to \$operation value : 
	    \begin{itemize}
	      \item 'listname'(+) \emph{if \$operation=('request\_list\_creation' \(\mid\) 'automatic\_bounce\_management')}
	    \end{itemize}
	  \item \emph{if ref(ARRAY) then} variables used in template are named as : \$param0, \$param1, \$param2, ...  
	\end{itemize}
   \end{enumerate}

   \textbf{OUT} : 1 \(\mid\) undef 

\subsubsection {\large{send\_notify\_to\_owner()}}
\label{list-send-notify-owner}
\index{List::send\_notify\_to\_owner()}

   Sends a notice to list owner(s) by parsing ``listowner\_notification'' template. The template makes a specified or a 
   generic treatement according to variable \$param.type ( := \$operation parameter).
   The message is sent by calling List::send\_file() (see \ref {list-send-file}, page~\pageref {list-send-file}).
   Available variables for the template are set up by this function, by \$param parameter and by
   List::send\_file(). 

   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{self} (+): ref(List) - the list for owner notification
      \item \lparam{operation} (+) : notification type, corresponds to \$type in the template
      \item \lparam{param} (+): ref(HASH) \(\mid\) ref (ARRAY) - values for variable used in the template  : 
	\begin{itemize}
	  \item \emph{if ref(HASH) then} variables used in the template are keys of this HASH. 
	  \item \emph{if ref(ARRAY) then} variables used in template are named as : \$param0, \$param1, \$param2, ...  
	\end{itemize}
   \end{enumerate}

   \textbf{OUT} : 1 \(\mid\) undef 

\subsubsection {\large{send\_notify\_to\_editor()}}
\label{list-send-notify-editor}
\index{List::send\_notify\_to\_editor()}

   Sends a notice to list editor(s) by parsing ``listeditor\_notification'' template. The template makes a specified or a 
   generic treatement according to variable \$param.type ( := \$operation parameter).
   The message is sent by calling List::send\_file() (see \ref {list-send-file}, page~\pageref {list-send-file}).
   Available variables for the template are set up by this function, by \$param parameter and by
 List::send\_file(). 

   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{self} (+): ref(List) - the list for editor notification
      \item \lparam{operation} (+) : notification type, corresponds to \$type in the template
      \item \lparam{param} (+): ref(HASH) \(\mid\) ref (ARRAY) - values for variable used in the template  : 
	\begin{itemize}
	  \item \emph{if ref(HASH) then} variables used in the template are keys of this HASH. 
	  \item \emph{if ref(ARRAY) then} variables used in template are named as : \$param0, \$param1, \$param2, ...  
	\end{itemize}
   \end{enumerate}

   \textbf{OUT} : 1 \(\mid\) undef 


\subsubsection {\large{send\_notify\_to\_user()}}
\label{list-send-notify-user}
\index{List::send\_notify\_to\_user()}

   Sends a notice to a user by parsing ``user\_notification'' template. The template makes a specified or a 
   generic treatement according to variable \$param.type ( := with \$operation parameter).
   The message is sent by calling List::send\_file() (see \ref {list-send-file}, page~\pageref {list-send-file}).
   Available variables for the template are set up by this function, by \$param parameter and by
 List::send\_file(). 

   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{self} (+): ref(List) - the list for owner notification
      \item \lparam{operation} (+) : notification type, corresponds to \$type in the template
      \item \lparam{user} (+) : user email to notify
      \item \lparam{param} (+): ref(HASH) \(\mid\) ref (ARRAY) - values for variable used in the template  : 
	\begin{itemize}
	  \item \emph{if ref(HASH) then} variables used in the template are keys of this HASH. 
	  \item \emph{if ref(ARRAY) then} variables used in template are named as : \$param0, \$param1, \$param2, ...  
	\end{itemize}
   \end{enumerate}

   \textbf{OUT} : 1 \(\mid\) undef 

%%%%%%%%%%%%%%% topic messages %%%%%%%%%%%%%%%%%%%%%
\subsection {Functions for topic messages} 

is\_there\_msg\_topic(), is\_available\_msg\_topic(), get\_available\_msg\_topic(), is\_msg\_topic\_tagging\_required, 
automatic\_tag(), compute\_topic(), tag\_topic(), load\_msg\_topic\_file(), modifying\_msg\_topic\_for\_subscribers(), 
select\_subscribers\_for\_topic().

These functions are used to manages message topics.\\

N.B.: There is some exception to use some parameters : msg\_topic.keywords for list parameters and topics\_subscriber
for subscribers options in the DB table. These parameters are used as string splitted by ',' but to access to each one, use the function 
tools::get\_array\_from\_splitted\_string() (see \ref {tools-get-array-from-splitted-string}, 
page~\pageref {tools-get-array-from-splitted-string}) allows to access the enumeration.




\subsubsection {\large{is\_there\_msg\_topic()}}
\label{list-is-there-msg--topic}
\index{List::is\_there\_msg\_topic()}

Tests if some message topic are defined (\lparam{msg\_topic} list parameter, see \ref {msg-topic}, page~\pageref {msg-topic}).

   \textbf{IN} : \lparam{self} (+): ref(List)

   \textbf{OUT} :  1 - some msg\_topic are defined \(\mid\) 0 - no msg\_topic
 
\subsubsection {\large{is\_available\_msg\_topic()}}
\label{list-is-available-msg--topic}
\index{List::is\_available\_msg\_topic()}

Checks for a topic if it is available in the list : 
look foreach \lparam{msg\_topic.name} list parameter (see \ref {msg-topic}, page~\pageref {msg-topic}).

   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{self} (+): ref(List)
      \item \lparam{topic} (+) : the name of the requested topic
   \end{enumerate}

   \textbf{OUT} : \lparam{topic} \emph{if it is available} \(\mid\) undef 

\subsubsection {\large{get\_available\_msg\_topic()}}
\label{list-get-available-msg-topic}
\index{List::get\_available\_msg\_topic()}

Returns an array of available message topics (\lparam{msg\_topic.name} list parameter, see \ref {msg-topic}, page~\pageref {msg-topic}).

   \textbf{IN} : \lparam{self} (+): ref(List)

   \textbf{OUT} : ref(ARRAY)

\subsubsection {\large{is\_msg\_topic\_tagging\_required()}}
\label{list-is-msg-topic-tagging-required}
\index{List::is\_msg\_topic\_tagging\_required()}

Returns if the message must be tagged or not (\lparam{msg\_topic\_tagging} list parameter set to 'required', see \ref {msg-topic-tagging}, page~\pageref {msg-topic-tagging}).

   \textbf{IN} : \lparam{self} (+): ref(List)

   \textbf{OUT} : 1 - the message must be tagged \(\mid\) 0 - the msg can be no tagged

\subsubsection {\large{automatic\_tag()}}
\label{list-automatic-tag}
\index{List::automatic\_tag()}

Computes topic(s) (with compute\_topic() function) and tags the message (with tag\_topic() function) if there are some topics defined.

   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{self} (+): ref(List) 
      \item \lparam{msg} (+): ref(MIME::Entity)- the message to tag
      \item \lparam{robot} (+): robot	
   \end{enumerate}

   \textbf{OUT} : list of tagged topic : strings separated by ','. It can be empty. \(\mid\) undef 

\subsubsection {\large{compute\_topic()}}
\label{list-compute-topic}
\index{List::compute\_topic()}

Computes topic(s) of the message. If the message is in a thread, topic is got from the previous message else topic is got from 
applying a regexp on the subject and/or the body of the message (\lparam{msg\_topic\_keywords\_apply\_on} list parameter, 
see\ref {msg-topic-keywords-apply-on}, page~\pageref {msg-topic-keywords-apply-on}). Regexp is based on \lparam{msg\_topic.keywords} 
list parameters (See \ref {msg-topic}, page~\pageref {msg-topic}).

   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{self} (+): ref(List) 
      \item \lparam{msg} (+): ref(MIME::Entity)- the message to tag
   \end{enumerate}

   \textbf{OUT} : list of computed topic : strings separated by ','. It can be empty.

\subsubsection {\large{tag\_topic()}}
\label{list-tag-topic}
\index{List::tag\_topic()}

Tags the message by creating its topic information file in the \dir {[SPOOLDIR]/topic/} spool. 
The file contains the topic list and the method used to tag the message. Here is the format :
\begin {quote}
\begin{verbatim}
TOPIC topicname,...
METHOD editor|sender|auto  
\end{verbatim}
\end {quote}
 
   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{self} (+): ref(List) 
      \item \lparam{msg\_id} (+): string - the message ID of the message to tag
      \item \lparam{topic\_list} (+): the list of topics (strings splitted by ',')
      \item \lparam{method} (+): 'auto' \(\mid\)'editor'\(\mid\)'sender' - the method used for tagging
   \end{enumerate}

   \textbf{OUT} : name of the created topic information file (\file{directory/listname.msg\_id}) \(\mid\) undef 

\subsubsection {\large{load\_msg\_topic\_file()}}
\label{list-load-msg-topic-file}
\index{List::load\_msg\_topic\_file()}

Search and load msg topic file corresponding to the message ID  (\file{directory/listname.msg\_id}). It returns information contained inside.

   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{self} (+): ref(List) 
      \item \lparam{msg\_id} (+): the message ID
      \item \lparam{robot} (+): the robot
   \end{enumerate}

   \textbf{OUT} :  undef \(\mid\) ref(HASH), keys are :
   \begin{itemize}
     \item \lparam{topic} : list of topics (strings separated by ',')
     \item \lparam{method} : 'auto' \(\mid\)'editor'\(\mid\)'sender' - the method used for tagging
     \item \lparam{msg\_id} : message ID of the tagged message
     \item \lparam{filename} : name of the file
   \end{itemize}

\subsubsection {\large{modifying\_msg\_topic\_for\_subscribers()}}
\label{list-modifying-msg-topic-for-subscribers}
\index{List::modifying\_msg\_topic\_for\_subscribers()}

 Deletes topics of subscriber that does not exist anymore
 and send a notify to concerned subscribers. 
 (Makes a diff on msg\_topic parameter between the list configuration before modification
  and a new state by calling tools::diff\_on\_arrays() function, see \ref{tools-diff-on-arrays}, 
 page~\pageref{tools-diff-on-arrays}). This function is used by wwsympa::do\_edit\_list().

   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{self} (+): ref(List) - the concerned list before modification
      \item \lparam{new\_msg\_topic} (+) : ref(ARRAY) - new state of msg\_topic parameters
   \end{enumerate}

   \textbf{OUT} :
   \begin{enumerate}
      \item 1 \emph{if some subscriber topics have been deleted}
      \item 0 \emph{else}	
   \end{enumerate}

\subsubsection {\large{select\_subscribers\_for\_topic()}}
\label{list-select-subscriber-for-topic}
\index{List::select\_subscribers\_for\_topic()}

 Selects subscribers that are subscribed to one or more topic
 appearing in the topic list incoming when their reception mode is 'mail', and selects the other subscribers 
 (reception mode different from 'mail'). This function is used by List::send\_msg() function during message 
 diffusion (see \ref {list-send-msg}, page~\pageref {list-send-msg} ).

   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{self} (+): ref(List) 
      \item \lparam{string\_topic} (+): string splitted by ',' - the topic list
      \item \lparam{subscribers} (+): ref(ARRAY) - list of subscriber emails 
   \end{enumerate}

   \textbf{OUT} : ARRAY - list of selected subscribers

%%%%%%%%%%%%%%% scenario evaluation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\subsection {Scenario evaluation} 
\label{list-scenario-evaluation}

The following function is used to evaluate scenario file ``\texttt{<}action\texttt{>}.\texttt{<}parameter\_value\texttt{>}'',
where \texttt{<}action\texttt{>}action corresponds to a configuration parameter for an action and 
\texttt{<}parameter\_value\texttt{>} corresponds to its value.
 
\subsubsection {\large{request\_action()}}
 Return the action to perform for one sender 
 using one authentication method to perform an operation

   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{operation} (+): SCALAR - the requested action corresponding to config parameter
      \item \lparam{auth\_method} (+): 'smtp'\(\mid\)'md5'\(\mid\)'pgp'\(\mid\)'smime'
      \item \lparam{robot} (+): robot
      \item \lparam{context} (): ref(HASH) - contains value to instantiate scenario variables (hash keys)
      \item \lparam{debug} (): boolean - \emph{if true} adds keys 'condition' and 'auth\_method' to the returned hash.
   \end{enumerate}

   \textbf{OUT} : undef \(\mid\) ref(HASH) with keys : 
     \begin{itemize}
       \item action : 'do\_it'\(\mid\)'reject'\(\mid\)'request\_auth'\(\mid\)'owner'\(\mid\)'editor'\(\mid\)'editorkey'\(\mid\)'listmaster' 
       \item reason : 'value' \emph{if action == 'reject' in scenario and if there is  reject(reason='value')} to match a key in
	 mail\_tt2/authorization\_reject.tt2. This is used in errors reports (see \ref {report.pm}, page~\pageref {report.pm})
       \item tt2 : template name {if action == 'reject' in scenario and there is  reject(tt2='template\_name')}.
       \item condition : the checked condition.
       \item auth\_method : the checked auth\_method.
     \end{itemize}


%%%%%%%%%%%%%%% structure and access to list parameters %%%%%%%%%%%%%%%%%%%%
\subsection {Structure and access to list configuration parameters} 

List parameters are representated in the list configuration file, in the list object (\lparam{list->\{'admin'\}})
and on the Web interface. Here are translation and access functions :


\begin{tabular}{c|c|c|c|c}
             &                        &      other (3)  &                        &               \\
             & (1)\(\longrightarrow\) &   \(\uparrow\)  & (5)\(\longrightarrow\) &               \\
CONFIG FILE  &                        &   LIST OBJECT   &                        & WEB INTERFACE \\
             & \(\longleftarrow\) (2) &   (4)           & \(\longleftarrow\) (6) &              
\end{tabular}


\begin{enumerate}
  \item Loading file in memory : \begin{verbatim} List::_load_admin_file(),_load_include_admin_user_file(),_load_list_param() \end{verbatim}
  \item Saving list configuration in file : \begin{verbatim} List::_save_admin_file(),_save_list_param() \end{verbatim}
  \item Tools to get parameter values : \begin{verbatim} List::get_param_value(),_get_param_value_anywhere(),_get_single_param_value() \end{verbatim}
  \item Tools to initialize list parameter with defaults :\begin{verbatim} List::_apply_default() \end{verbatim}
  \item To present list parameters on the web interface : \begin{verbatim} wwsympa::do_edit_list_request(),_prepare_edit_form(),_prepare_data() \end{verbatim}
  \item To get updates on list parameters from the web interface : \begin{verbatim} wwsympa::do_edit_list(),_check_new_value \end{verbatim}
\end{enumerate}

List parameters can be simple or composed in paragraph, they can be unique or multiple and they can singlevalued or multivalued. Here are the different kinds 
of parameters and an exemple : 

\begin{tabular}{|c|c||c|c|}
\hline
\multicolumn{2}{|c||}{parameters}  &          SIMPLE          &               COMPOSED               \\
\hline\hline 
SINGLE & singlevalued            &           (a)             &                 (b)                  \\
       &                         &       \emph{lang}         &       \emph{archiv.period}            \\  
\cline{2-4}
       & multivalued             &           (c)             &                 (d)                  \\
       &                         &      \emph{topics}        &    \emph{available\_user\_option.reception}\\
\hline
MULTIPLE & singlevalued          &            (e)            &                 (f)                  \\
         &                       &      \emph{include\_list} &         \emph{owner.email}               \\ 
\cline{2-4}  
       & multi values            &          not defined      &          not defined                  \\
\hline
\end{tabular}


Here are these list parameters format in list configuration file in front of perl representation in memory :

\begin{tabular}{|c||l|l|}
\hline
              & List Configuration FILE                   &     \lparam{\$list->\{'admin'\}}                          \\
\hline\hline
(a)           & param value                               &          'scalar'                                         \\ 
\hline
(b)           & param                                     &                                                           \\
              & p1 val1                                   &          'HASH\(\rightarrow\)scalar'                      \\    
	      &	p2 val2                                   &                                                           \\
\hline
(c)           & param val1,val2,val3                      &          'ARRAY(scalar \& split\_char)'                   \\
\hline
(d)           & param                                     &                                                           \\
              & p1 val11, val12, val13                    &          'HASH\(\rightarrow\)ARRAY(scalar \& split\_char)'\\ 
	      &	p2 val21, val22, val23                    &                                                            \\
\hline
(e)           & param val1                                &          'ARRAY(scalar)'                                   \\
	      &	param val2                                &                                                            \\
\hline
(d)           & param                                     &                                                            \\
              & p1 val11                                  &          'ARRAY(HASH\(\rightarrow\)scalar)'                \\  
	      &	p2 val12                                  &                                                            \\
              &                                           &                                                            \\
              & param                                     &                                                            \\
              & p1 val21                                  &                                                            \\ 
	      &	p2 val22                                  &                                                            \\
\hline
\end{tabular}
                                        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%% sympa.pl %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\section {sympa.pl}
\index{sympa.pl}

   This is the main script ; it runs as a daemon and does the messages/commands processing.  It uses these funstions :
   DoFile(), DoMessage(), DoCommand(), DoSendMessage(), DoForward(), SendDigest(), CleanSpool(), sigterm(), sighup().
   
   Concerning reports about message distribution, function List::send\_file() 
   (see \ref {list-send-file}, page~\pageref {list-send-file}) or List::send\_global\_file() 
   (see \ref {list-send-global-file}, page~\pageref {list-send-global-file}) is called with 
   mail template ``message\_report''. Concernong reports about commands, it is the mail template
   ``command\_report''.

\subsubsection {\large{DoFile()}}
\label{sympa-dofile}
\index{sympa::DoFile()}

   Handles a received file : function called by the sympa.pl main loop in order to process files 
   contained in the queue spool. The file is encapsulated in a Message object not to alter it. Then 
   the file is read, the header and the body of the message are separeted. Then the adequate function 
   is called whether a command has been received or a message has to be redistributed to a list.

   So this function can call various functions : \begin{itemize}
     \item sympa::DoMessage() for message distribution (see \ref {sympa-domessage}, page~\pageref {sympa-domessage}) 
     \item sympa::DoCommand() for command processing (see \ref {sympa-docommand}, page~\pageref {sympa-docommand})
     \item sympa::DoForward() for message forwarding to administrators (see \ref {sympa-doforward}, page~\pageref {sympa-doforward}) 
     \item sympa::DoSendMessage() for wwsympa message sending (see \ref {sympa-dosendmessage}, page~\pageref {sympa-dosendmessage}).
   \end{itemize}
   About command process a report can be sent by calling List::send\_global\_file() (see \ref {list-send-global-file}, 
   page~\pageref {list-send-global-file}) with template ``command\_report''. For message report it is the template ``message\_report''.
  
   \textbf{IN} : \lparam{file}(+): the file to handle

   \textbf{OUT} : \$status - result of the called function \(\mid\) undef

\subsubsection {\large{DoMessage()}}
\label{sympa-domessage}
\index{sympa::DoMessage()}

   Handles a message sent to a list (Those that can make loop and those containing a command are 
   rejected). This function can call various functions : \begin{itemize}
     \item List::distribute\_msg() for distribution (see \ref {list-distribute-msg}, page~\pageref {list-distribute-msg})
     \item List::send\_auth() for authentification or topic tagging by message sender(see \ref {list-send-auth}, page~\pageref {list-send-auth})
     \item List::send\_to\_editor() for moderation or topic tagging by list moderator(see \ref {list-send-to-editor}, page~\pageref {list-send-to-editor}).
     \item List::automatic\_tag() for automatic topic tagging (see \ref {list-automatic-tag}, page~\pageref {list-automatic-tag}).
   \end{itemize}
  
   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{which}(+): 'list\_name@domain\_name - the concerned list
      \item \lparam{message}(+): ref(Message) - sent message 
      \item \lparam{robot}(+): robot
   \end{enumerate}

   \textbf{OUT} : 1  \emph{if everything went fine} in order to remove the file from the queue \(\mid\) undef

\subsubsection {\large{DoCommand()}}
\label{sympa-docommand}
\index{sympa::DoCommand()}

   Handles a command sent to sympa. The command is parse by calling Commands::parse() (see 
   \ref {commands-parse}, page~\pageref {commands-parse}).
  
   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{rcpt} : recepient \(\mid\) \texttt{<}listname\texttt{>}-\texttt{<}subscribe\(\mid\)unsubscribe\texttt{>}
      \item \lparam{robot}(+): robot
      \item \lparam{msg}(+): ref(MIME::Entity) - message containing the command
      \item \lparam{file}(+): file containing the message
   \end{enumerate}

   \textbf{OUT} : \$success - result of Command::parse() function \(\mid\) undef.

\subsubsection {\large{DoSendMessage()}}
\label{sympa-dosendmessage}
\index{sympa::DoSendMessage()}

   Sends a message pushed in spool by another process (ex : wwsympa.fcgi) by calling function
   mail::mail\_forward() (see \ref {mail-mail-forward}, page~\pageref {mail-mail-forward}).
  
   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{msg}(+): ref(MIME::Entity)
      \item \lparam{robot}(+): robot	
   \end{enumerate}

   \textbf{OUT} : 1  \(\mid\) undef 

\subsubsection {\large{DoForward()}}
\label{sympa-doforward}
\index{sympa::DoForward()}

   Handles a message sent to \texttt{<}listname\texttt{>}-editor : the list editor,  \texttt{<}list\texttt{>}-request : the list owner or the listmaster. 
   The message is forwarded according to \$function by calling function
   mail::mail\_forward() (see \ref {mail-mail-forward}, page~\pageref {mail-mail-forward}).
  
   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{name}(+): list name \emph{if (\$function != 'listmaster')}
      \item \lparam{function}(+): 'listmaster' \(\mid\) 'request' \(\mid\) 'editor'
      \item \lparam{robot}(+): robot
      \item \lparam{msg}(+): ref(MIME::Entity)
   \end{enumerate}

   \textbf{OUT} : 1   \(\mid\) undef


\subsubsection {\large{SendDigest()}}
\label{sympa-sendigest}
\index{sympa::SendDigest()}

   Reads the queuedigest spool and send old digests to the subscribers with the digest option by 
   calling List::send\_msg\_digest() function mail::mail\_forward() (see \ref {list-send-msg-digest}, 
   page~\pageref {list-send-msg-digest}).
  
   \textbf{IN} : -
   \textbf{OUT} : -  \(\mid\) undef 

\subsubsection {\large{CleanSpool()}}
\label{sympa-cleanspool}
\index{sympa::cleanspool()}

  Cleans old files from spool \$spool\_dir older than \$clean\_delay.
  
   \textbf{IN} :   
   \begin{enumerate}
     \item \lparam{spool\_dir}(+) : the spool directory 
     \item \lparam{clean\_delay}(+) : the delay in days
   \end{enumerate}

   \textbf{OUT} : 1 


\subsubsection {\large{sigterm()}}
\label{sympa-sigterm}
\index{sympa::sigterm()}

   This function is called when a signal -TERM is received by sympa.pl.
   It just changes the value of \$signal loop variable in order to stop sympa.pl after endding its message distribution
   if in progress. (see \ref {stop-signals}, page~\pageref {stop-signals})

   \textbf{IN} : -
   \textbf{OUT} : -

\subsubsection {\large{sighup()}}
\label{sympa-sighup}
\index{sympa::sighup()}

   This function is called when a signal -HUP is received by sympa.pl.
   It changes the value of \$signal loop variable and switchs of the "--mail" (see \ref {stop-signals}, 
   page~\pageref {stop-signals}) logging option and continues current task.

   \textbf{IN} : -
   \textbf{OUT} : -

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%% Commands.pm %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\section {Commands.pm}
\index{Commands.pm}

   This module does the mail commands processing.

\subsection {Commands processing}

   parse(), add(), del(), subscribe(), signoff(), invite(), last(), index(), getfile(), confirm(),
   set(), distribute(), reject(), modindex(), review(), verify(), remind(), info(), stats(), help(),
   lists(), which(), finished().

\subsubsection {\large{parse()}}
\label{commands-parse}
\index{commands::parse()}

   Parses the command line and calls the adequate subroutine (following functions)
   with the arguments of the command. This function is called by sympa::DoCommand() (see \ref {sympa-docommand}, 
   page~\pageref {sympa-docommand}).

   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{sender}(+): the command sender
      \item \lparam{robot}(+): robot
      \item \lparam{i}(+): command line	
      \item \lparam{sign\_mod} : 'smime' \(\mid\) undef
   \end{enumerate}

   \textbf{OUT} : 'unknown\_cmd' \(\mid\)  \$status - command process result

\subsubsection {\large{add()}}
\label{commands-add}
\index{commands::add()}

   Adds a user to a list (requested by another user), and can send acknowledgements.
   New subscriber can be notified by sending template 'welcome'.  

   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{what}(+): command parameters : listname, email and comments eventually
      \item \lparam{robot}(+): robot
      \item \lparam{sign\_mod} : 'smime' \(\mid\) undef - authentification
   \end{enumerate}

   \textbf{OUT} : 'unknown\_list' \(\mid\) 'wrong\_auth' \(\mid\) 'not\_allowed' \(\mid\) 1  \(\mid\) undef

\subsubsection {\large{del()}}
\label{commands-del}
\index{commands::del()}

   Removes a user to a list (requested by another user), and can send acknowledgements.
   Unsubscriber can be notified by sending template 'removed'.

   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{what}(+): command parameters : listname and email 
      \item \lparam{robot}(+): robot
      \item \lparam{sign\_mod} : 'smime' \(\mid\) undef - authentification
   \end{enumerate}

   \textbf{OUT} : 'unknown\_list' \(\mid\) 'wrong\_auth' \(\mid\) 'not\_allowed' \(\mid\) 1

\subsubsection {\large{subscribe()}}
\label{commands-subscribe}
\index{commands::subscribe()}

   Subscribes a user to a list. New subscriber can be notified by sending him template 'welcome'.

   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{what}(+): command parameters : listname and comments eventually
      \item \lparam{robot}(+): robot
      \item \lparam{sign\_mod} : 'smime' \(\mid\) undef - authentification
   \end{enumerate}

   \textbf{OUT} : 'unknown\_list' \(\mid\) 'wrong\_auth' \(\mid\) 'not\_allowed' \(\mid\) 1  \(\mid\) undef

\subsubsection {\large{signoff()}}
\label{commands-signoff}
\index{commands::signoff()}

   Unsubscribes a user from a list. He can be notified by sending him template 'bye'.

   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{which}(+): command parameters : listname and email 
      \item \lparam{robot}(+): robot
      \item \lparam{sign\_mod} : 'smime' \(\mid\) undef - authentification
   \end{enumerate}

   \textbf{OUT} : 'syntax\_error' \(\mid\) 'unknown\_list' \(\mid\) 'wrong\_auth' \(\mid\) 'not\_allowed' \(\mid\) 1 \(\mid\) undef

\subsubsection {\large{invite()}}
\label{commands-invite}
\index{commands::invite()}

   Invites someone to subscribe to a list by sending him the template 'invite'.

   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{what}(+): command parameters : listname, email and comments 
      \item \lparam{robot}(+): robot
      \item \lparam{sign\_mod} : 'smime' \(\mid\) undef - authentification
   \end{enumerate}

   \textbf{OUT} : 'unknown\_list' \(\mid\) 'wrong\_auth' \(\mid\) 'not\_allowed' \(\mid\) 1 \(\mid\) undef

\subsubsection {\large{last()}}
\label{commands-last}
\index{commands::last()}

   Sends back the last archive file by calling List::archive\_send() function
   (see \ref {list-archive-send}, page~\pageref {list-archive-send}).

   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{which}(+): listname
      \item \lparam{robot}(+): robot
   \end{enumerate}

   \textbf{OUT} : 'unknown\_list' \(\mid\) 'no\_archive' \(\mid\) 'not\_allowed' \(\mid\) 1 

\subsubsection {\large{index()}}
\label{commands-index}
\index{commands::index()}

   Sends the list of archived files of a list.

   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{which}(+): listname
      \item \lparam{robot}(+): robot
   \end{enumerate}

   \textbf{OUT} : 'unknown\_list' \(\mid\) 'no\_archive' \(\mid\) 'not\_allowed' \(\mid\) 1 

\subsubsection {\large{getfile()}}
\label{commands-last}
\index{commands::last()}

   Sends back the requested archive file by calling List::archive\_send() function
   (see \ref {list-archive-send}, page~\pageref {list-archive-send}).

   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{which}(+): commands parameters : listname and filename(archive file)
      \item \lparam{robot}(+): robot
   \end{enumerate}

   \textbf{OUT} : 'unknown\_list' \(\mid\) 'no\_archive' \(\mid\) 'not\_allowed' \(\mid\) 1

\subsubsection {\large{confirm()}}
\label{commands-confirm}
\index{commands::confirm()}

   Confirms the authentification of a message for its distribution on a list by calling function
   List::distribute\_msg() for distribution (see \ref {list-distribute-msg}, page~\pageref {list-distribute-msg}) 
   or by calling  List::send\_to\_editor() for moderation (see \ref {list-send-editor}, page~\pageref {list-send-editor}).
   
   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{what}(+): authentification key (command parameter)
      \item \lparam{robot}(+): robot
   \end{enumerate}

   \textbf{OUT} : 'wrong\_auth' \(\mid\) 'msg\_not\_found' \(\mid\) 1 \(\mid\) undef

\subsubsection {\large{set()}}
\label{commands--set}
\index{commands::set()}

   Changes subscription options (reception or visibility)

   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{what}(+): command parameters : listname and 
        reception mode (digest\(\mid\)digestplain\(\mid\)nomail\(\mid\)normal...) or visibility mode(conceal\(\mid\)noconceal).
      \item \lparam{robot}(+): robot
   \end{enumerate}

   \textbf{OUT} : 'syntax\_error' \(\mid\) 'unknown\_list' \(\mid\) 'not\_allowed' \(\mid\) 'failed' \(\mid\) 1

\subsubsection {\large{distribute()}}
\label{commands-distribute}
\index{commands::distribute()}

   Distributes the broadcast of a validated moderated message.

   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{what}(+): command parameters : listname and authentification key
      \item \lparam{robot}(+): robot
   \end{enumerate}

   \textbf{OUT} : 'unknown\_list' \(\mid\) 'msg\_not\_found' \(\mid\) 1 \(\mid\) undef

\subsubsection {\large{reject()}}
\label{commands-reject}
\index{commands::reject()}
   
   Refuses and deletes a moderated message. Rejected message sender can be notified by sending him template 'reject'.

   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{what}(+): command parameters : listname and authentification key
      \item \lparam{robot}(+): robot
   \end{enumerate}

   \textbf{OUT} : 'unknown\_list' \(\mid\) 'wrong\_auth' \(\mid\) 1  \(\mid\) undef

\subsubsection {\large{modindex()}}
\label{commands-modindex}
\index{commands::modindex()}

   Sends a list of current messages to moderate of a list (look into spool queuemod)
   by using template 'modindex'.

   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{name}(+): listname
      \item \lparam{robot}(+): robot
   \end{enumerate}

   \textbf{OUT} : 'unknown\_list' \(\mid\) 'not\_allowed' \(\mid\) 'no\_file' \(\mid\) 1

\subsubsection {\large{review()}}
\label{commands-review}
\index{commands::review()}

   Sends the list of subscribers of a list to the requester by using template 'review'.

   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{listname}(+): list name
      \item \lparam{robot}(+): robot
      \item \lparam{sign\_mod} : 'smime' \(\mid\) undef - authentification
   \end{enumerate}

   \textbf{OUT} : 'unknown\_list' \(\mid\) wrong\_auth \(\mid\) no\_subscribers \(\mid\) 'not\_allowed' \(\mid\) 1 \(\mid\) undef

\subsubsection {\large{verify()}}
\label{commands-verify}
\index{commands::verify()}

   Verifies an S/MIME signature.

   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{listname}(+): list name
      \item \lparam{robot}(+): robot
      \item \lparam{sign\_mod} : 'smime' \(\mid\) undef - authentification
   \end{enumerate}

   \textbf{OUT} : 1


\subsubsection {\large{remind()}}
\label{commands-remind}
\index{commands::remind()}

   Sends a personal reminder to each subscriber of a list or of every list (if \$which = *) 
   using template 'remind' or 'global\_remind'.

   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{which}(+): * \(\mid\) listname
      \item \lparam{robot}(+): robot
      \item \lparam{sign\_mod} : 'smime' \(\mid\) undef - authentification
   \end{enumerate}

   \textbf{OUT} : 'syntax\_error' \(\mid\) 'unknown\_list' \(\mid\) 'wrong\_auth' \(\mid\) 'not\_allowed' \(\mid\) 1 \(\mid\) undef

\subsubsection {\large{info()}}
\label{commands-info}
\index{commands::info()}

   Sends the list information file to the requester by using template 'info\_report'.

   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{listname}(+): name of concerned list
      \item \lparam{robot}(+): robot
      \item \lparam{sign\_mod} : 'smime' \(\mid\) undef - authentification
   \end{enumerate}

   \textbf{OUT} : 'unknown\_list' \(\mid\) 'wrong\_auth' \(\mid\) 'not\_allowed' \(\mid\) 1 \(\mid\) undef 

\subsubsection {\large{stats()}}
\label{commands-stats}
\index{commands::stats()}

   Sends the statistics about a list using template 'stats\_report'.

   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{listname}(+): list name
      \item \lparam{robot}(+): robot
      \item \lparam{sign\_mod} : 'smime' \(\mid\) undef - authentification
   \end{enumerate}

   \textbf{OUT} : 'unknown\_list' \(\mid\) 'not\_allowed' \(\mid\) 1  \(\mid\) undef

\subsubsection {\large{help()}}
\label{commands-help}
\index{commands::help()}

  Sends the help file for the software by using template 'helpfile'.

   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{} : ?
      \item \lparam{robot}(+): robot
   \end{enumerate}

   \textbf{OUT} : 1 \(\mid\) undef

\subsubsection {\large{lists()}}
\label{commands-lists}
\index{commands::lists()}

  Sends back the list of public lists on this node by using template 'lists'. 

   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{} : ?
      \item \lparam{robot}(+): robot
   \end{enumerate}

   \textbf{OUT} : 1 \(\mid\) undef

\subsubsection {\large{which()}}
\label{commands-lists}
\index{commands::lists()}

   Sends back the list of lists that sender is subscribed to. If he is owner or
   editor, managed lists are noticed. Message is sent by using template 'which'.

   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{} : ?
      \item \lparam{robot}(+): robot
   \end{enumerate}

   \textbf{OUT} : 1

\subsubsection {\large{finished()}}
\label{commands-finished}
\index{commands::finished()}
   
   Called when 'quit' command is found. It sends a notification to sender : no
   process will be done after this line.

   \textbf{IN} : -

   \textbf{OUT} : 1



\subsection {tools for command processing}

   get\_auth\_method()

\subsubsection {\large{get\_auth\_method()}}
\label{commands-get-auth-method}
\index{commands::get\_auth\_method()}
   
   Called by processing command functions to return the authentification method
   and to check the key if it is 'md5' method.

   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{cmd}(+): requesting command 
      \item \lparam{email}(+): used to compute auth if needed in command
      \item \lparam{error}(+): ref(HASH) - keys are :
	   \begin{itemize}
             \item \lparam{type} : \$type for ``message\_report'' template parsing
             \item \lparam{data} : ref(HASH) for ``message\_report'' template parsing
             \item \lparam{msg} : for do\_log()
	   \end{itemize}
      \item \lparam{sign\_mod}(+): 'smime' - smime authentification \(\mid\) undef - smtp or md5 authentification 
      \item \lparam{list}: ref(List) \(\mid\) undef - in a list context or not
   \end{enumerate}
   \textbf{OUT} : 'smime' \(\mid\) 'md5' \(\mid\) 'smtp' - authentification method if checking not failed \(\mid\) undef


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%% wwsympa.fcgi %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\section {wwsympa.fcgi}
\index{wwsympa.fcgi}

This script provides the web interface to \Sympa.

do\_subscribe(), do\_signoff(), do\_add(), do\_del(), do\_change\_email(), do\_reject(),
do\_send\_mail(), do\_sendpasswd(), do\_remind(), do\_set(), do\_send\_me(), do\_request\_topic(),
do\_tag\_topic\_by\_sender().

\subsubsection {\large{do\_subscribe()}}
\label{wwsympa-do-subscribe}
\index{wwsympa::do\_subscribe()}

  Subscribes a user to a list. New subscriber can be notified
  by sending him template 'welcome'.\begin{itemize}   
   \item \textbf{IN} : -
   \item \textbf{OUT} : 'subrequest' \(\mid\) 'login' \(\mid\) 'info' \(\mid\) \$in.previous\_action \(\mid\) undef
  \end{itemize}    

\subsubsection {\large{do\_signoff()}}
\label{wwsympa-do-signoff}
\index{wwsympa::do\_signoff()}

  Unsubscribes a user from a list.  The unsubscriber can be notified
  by sending him template 'bye'.\begin{itemize}   
   \item \textbf{IN} : -
   \item \textbf{OUT} : 'sigrequest' \(\mid\) 'login' \(\mid\) 'info' \(\mid\) undef
  \end{itemize}    

\subsubsection {\large{do\_add()}}
\label{wwsympa-do-add}
\index{wwsympa::do\_add()}

   Adds a user to a list (requested by another user) and can send acknowledgements. 
   New subscriber can be notified by sending him template 'welcome'.\begin{itemize}
    \item \textbf{IN} : -
    \item \textbf{OUT} : 'loginrequest' \(\mid\) (\$in.previous\_action \(\mid\mid\) 'review') \(\mid\) undef
  \end{itemize}    

\subsubsection {\large{do\_del()}}
\label{wwsympa-do-del}
\index{wwsympa::do\_del()}

   Removes a user from a list (requested by another user) and can send acknowledgements.
   Unsubscriber can be notified by sending template 'removed'.\begin{itemize} 
   \item \textbf{IN} : -
   \item \textbf{OUT} : 'loginrequest' \(\mid\) (\$in.previous\_action \(\mid\mid\) 'review') \(\mid\) undef
  \end{itemize}    

\subsubsection {\large{do\_change\_email()}}
\label{wwsympa-do-change-email}
\index{wwsympa::do\_change\_email()}

  Changes a user's email address in \Sympa environment. Password can be send to user by sending
  template 'sendpasswd'.\begin{itemize} 
   \item \textbf{IN} : -
   \item \textbf{OUT} : '1' \(\mid\) 'pref' \(\mid\) undef
  \end{itemize}    

\subsubsection {\large{do\_reject()}}
\label{wwsympa-do-reject}
\index{wwsympa::do\_reject()}

  Refuses and deletes moderated messages. Rejected message senders are notified by
  sending them template 'reject'.\begin{itemize} 
   \item \textbf{IN} : -
   \item \textbf{OUT} : 'loginrequest' \(\mid\) 'modindex' \(\mid\) undef
  \end{itemize}    

\subsubsection {\large{do\_distribute()}}
\label{wwsympa-do-distribute}
\index{wwsympa::do\_distribute()}

  Distributes moderated messages by sending a command DISTRIBUTE to sympa.pl. For it, it calls mail::mail\_file()
 (see \ref {mail-mail-file}, page~\pageref {mail-mail-file}). As it is in a Web context, the message will be 
 set in spool. In a context of message topic, tags the message by calling to function List::tag\_topic() 
 (see \ref {list-tag-topic}, page~\pageref {list-tag-topic}).\begin{itemize} 
   \item \textbf{IN} : -
   \item \textbf{OUT} : 'loginrequest' \(\mid\) 'modindex' \(\mid\) undef
  \end{itemize}    

\subsubsection {\large{do\_modindex()}}
\label{wwsympa-do-modindex}
\index{wwsympa::do\_modindex()}

  Allows a moderator to moderate a list of messages and documents and/or tag message in message topic context.
  \begin{itemize} 
   \item \textbf{IN} : -
   \item \textbf{OUT} : 'loginrequest' \(\mid\) 'admin' \(\mid\) 1 \(\mid\) undef
  \end{itemize}    

\subsubsection {\large{do\_viewmod()}}
\label{wwsympa-do-viewmod}
\index{wwsympa::do\_modindex()}

  Allows a moderator to moderate a message and/or tag message in message topic context.
  \begin{itemize} 
   \item \textbf{IN} : -
   \item \textbf{OUT} : 'loginrequest' \(\mid\) 1 \(\mid\) undef
  \end{itemize}    

\subsubsection {\large{do\_send\_mail()}}
\label{wwsympa-do-send-mail}
\index{wwsympa::do\_send\_mail()}

  Sends a message to a list by the Web interface.
  It uses mail::mail\_file() (see \ref {mail-mail-file}, page~\pageref {mail-mail-file})
  to do it. As it is in a Web context, the message will be set in spool.\begin{itemize} 
   \item \textbf{IN} : -
   \item \textbf{OUT} : 'loginrequest' \(\mid\) 'info' \(\mid\) undef
  \end{itemize}    

\subsubsection {\large{do\_sendpasswd()}}
\label{wwsympa-do-sendpasswd}
\index{wwsympa::do\_sendpasswd()}

  Sends a message to a user, containing his password, by sending him template 'sendpasswd' list by the Web interface.
  \begin{itemize} 
   \item \textbf{IN} : -
   \item \textbf{OUT} : 'loginrequest' \(\mid\) 'info' \(\mid\) undef
  \end{itemize}    

\subsubsection {\large{do\_request\_topic()}}
\label{wwsympa-do-request-topic()}
\index{wwsympa::do\_request\_topic()}

  Allows a sender to tag his mail in message topic context.\begin{itemize} 
   \item \textbf{IN} : -
   \item \textbf{OUT} : 'loginrequest' \(\mid\) 1 \(\mid\) undef
  \end{itemize}    

\subsubsection {\large{do\_tag\_topic\_by\_sender()}}
\label{wwsympa-do-tag-topic-by-sender()}
\index{wwsympa::do\_tag\_topic\_by\_sender()}

  Tags a message by its sender by calling List::tag\_topic() and allows its diffusion by sending a command CONFIRM 
  to sympa.pl.
  \begin{itemize} 
   \item \textbf{IN} : -
   \item \textbf{OUT} : 'loginrequest' \(\mid\) 'info' \(\mid\) undef
  \end{itemize}    

\subsubsection {\large{do\_remind()}}
\label{wwsympa-do-remind}
\index{wwsympa::do\_remind()}

  Sends a command remind to sympa.pl by calling mail::mail\_file() (see \ref {mail-mail-file}, 
  page~\pageref {mail-mail-file}). As it is in a Web context, the message will be set in spool.
  \begin{itemize} 
   \item \textbf{IN} : -
   \item \textbf{OUT} : 'loginrequest' \(\mid\) 'admin' \(\mid\) undef
  \end{itemize}    

\subsubsection {\large{do\_set()}}
\label{wwsympa-do-set}
\index{wwsympa::do\_set()}

   Changes subscription options (reception or visibility)
   \begin{itemize} 
    \item \textbf{IN} : -
    \item \textbf{OUT} : 'loginrequest' \(\mid\) 'info' \(\mid\) undef
   \end{itemize}    

\subsubsection {\large{do\_send\_me()}}
\label{wwsympa-do-send-me}
\index{wwsympa::do\_send\_me()}

   Sends a web archive message to a requesting user It calls mail::mail\_forward() to do it 
   (see \ref {mail-mail-forward}, page~\pageref {mail-mail-forward}). As it is in a Web context, 
   the message will be set in spool.
   \begin{itemize} 
    \item \textbf{IN} : -
    \item \textbf{OUT} : 'arc' \(\mid\) 1 \(\mid\) undef
   \end{itemize}    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%% report.pm %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\section {report.pm}
\index{report.pm}

This module provides various tools for notification and error reports in every Sympa interface 
(mail diffusion, mail command and web command).

For a requested service, there are four kinds of reports to users:
\begin{itemize} 
   \item \textbf{success notification}\\
     when the action does not involve any specific mail report or else,
     the user is notified of the well done of the processus.
   \item \textbf{non authorization}\file{(auth)}\\
     a user is not allowed to perform an action, Sympa provides reason of rejecting. 
     The template used to provides this information is \file{mail\_tt2/authorization\_reject.tt2}. It contains a list of reasons, indexed
     by keywords that are mentioned in reject action scenario (see \ref {rules}, page~\pageref {rules})
   \item \textbf{user error}\file{(user)}\\
     a error caused by the user, the user is informed about the error reason
   \item \textbf{internal server error}\file{(intern)}\\
     an error independent from the user, the user is succintly informed 
     about the error reason but a mail with more information is sent to listmaster using template 
     \file{mail\_tt2/listmaster\_notification.tt2}(If it is not necessary, keyword used is \file{'intern\_quiet'}.
\end{itemize} 
   

For other reports than non authorizations templates used depends on the interface :
\begin{itemize} 
   \item message diffusion : \file{mail\_tt2/message\_report.tt2}
   \item mail commands : \file{mail\_tt2/command\_report.tt2}
   \item web commands : \file{web\_tt2/notice.tt2} for positive notifications and \file{web\_tt2/error.tt2} for rejects.
\end{itemize}  


%%%%%%%%%%%%%%% message diffusion %%%%%%%%%%%%%%%%%%%%
\subsection {Message diffusion} 
\label {report-message-diffusion}

These reports use template \file{mail\_tt2/message\_report.tt2} and there are two functions :
\file{reject\_report\_msg()} and \file{notice\_report\_msg()}.


\subsubsection {\large{reject\_report\_msg()}}
\label{report-reject-report-msg}
\index{report::reject\_report\_msg()}

   Sends a notification to the user about an error rejecting his requested message diffusion.

   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{type}(+): 'intern'\(\mid\)'intern\_quiet'\(\mid\)'user'\(\mid\)'auth' - the error type 
      \item \lparam{error}: SCALAR - depends on \$type :
	 \begin{itemize}
	   \item 'intern' : string error sent to listmaster
	   \item 'user' : \$entry  in \file{message\_report.tt2}
	   \item 'auth' : \$reason  in \file{authorization\_reject.tt2}
	 \end{itemize}
      \item \lparam{user}(+): SCALAR - the user to notify
      \item \lparam{param}: ref(HASH) - for variable instantiation \file{message\_report.tt2}
	(key \lparam{msgid}(+) is required \emph{if type == 'intern'})
      \item \lparam{robot}: SCALAR - robot
      \item \lparam{msg\_string}: SCALAR - rejected message
      \item \lparam{list}: ref(List) - in a list context
   \end{enumerate}

   \textbf{OUT} : 1 \(\mid\) undef

\subsubsection {\large{notice\_report\_msg()}}
\label{report-reject-report-msg}
\index{report::reject\_report\_msg()}

   Sends a notification to the user about a success about his requested message diffusion.

   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{entry}(+): \$entry  in \file{message\_report.tt2}
      \item \lparam{user}(+): SCALAR - the user to notify
      \item \lparam{param}: ref(HASH) - for variable instantiation \file{message\_report.tt2}
      \item \lparam{robot}(+): SCALAR - robot
      \item \lparam{list}: ref(List) - in a list context
   \end{enumerate}

   \textbf{OUT} : 1 \(\mid\) undef


%%%%%%%%%%%%%%% Mail commands  %%%%%%%%%%%%%%%%%%%%
\subsection {Mail commands} 
\label {report-mail-commands}

A mail can contains many commands. Errors and notices are stored in module global arrays before sending
(\@intern\_error\_cmd, \@user\_error\_cmd, \@global\_error\_cmd, \@auth\_reject\_cmd, \@notice\_cmd). 
Moreover used errors here we can have global errors on mail containing commands, so there is a function for that.
These reports use template \file{mail\_tt2/command\_report.tt2} and there are many functions :

\subsubsection {\large{init\_report\_cmd()}}
\label{report-init-report-cmd}
\index{report::init\_report\_cmd()}

   Inits global arrays for mail command reports.

   \textbf{IN} : -

   \textbf{OUT} : -


\subsubsection {\large{is\_there\_any\_report\_cmd()}}
\label{report-is-there-any-report-cmd}
\index{report::is\_there\_any\_report\_cmd()}

   Looks for some mail command reports in one of global arrays.

   \textbf{IN} : -

   \textbf{OUT} : 1 \emph{if there are some reports to send}


\subsubsection {\large{global\_report\_cmd()}}
\label{report-send-report-cmd}
\index{report::send\_report\_cmd()}

   Concerns global reports of mail commands. There are many uses cases :

   \begin{enumerate}
      \item \textbf{internal server error} for a differed sending at the end of the mail processing :
	\begin{itemize}
	   \item \file{global\_report\_cmd('intern',\$error,\$data,\$sender,\$robot)}
           \item \file{global\_report\_cmd('intern\_quiet',\$error,\$data)} : the listmaster won't be noticied
         \end{itemize}
      \item \textbf{internal server error} for sending every reports directly (by calling \file{send\_report\_cmd()}) :
	\begin{itemize}
	   \item \file{global\_report\_cmd('intern',\$error,\$data,\$sender,\$robot,1)}
           \item \file{global\_report\_cmd('intern\_quiet',\$error,\$data,\$sender,\$robot,1)} : the listmaster won't be noticied
        \end{itemize}
      \item \textbf{user error} for a differed sending at the end of the mail processing : \\
	\file{global\_report\_cmd('user',\$error,\$data}
      \item \textbf{user error} for sending every reports directly (by calling \file{send\_report\_cmd()}) : \\
	\file{global\_report\_cmd('user',\$error,\$data,\$sender,\$robot,1)}
  \end{enumerate}

  \textbf{IN} : 
  \begin{enumerate}
     \item \lparam{type}(+): 'intern'\(\mid\)'intern\_quiet'\(\mid\)'user'
     \item \lparam{error}: SCALAR - depends on \$type :
	 \begin{itemize}
	   \item 'intern' : string error sent to listmaster
	   \item 'user' : \$glob.entry  in \file{command\_report.tt2}
	 \end{itemize}
     \item \lparam{data}: ref(HASH) - for variable instantiation in \file{command\_report.tt2}
     \item \lparam{sender}: SCALAR - the user to notify
     \item \lparam{robot}: SCALAR - robot
     \item \lparam{now}: BOOLEAN - send reports now \emph{if true}
  \end{enumerate}

  \textbf{OUT} : 1 \(\mid\) undef

\subsubsection {\large{reject\_report\_cmd()}}
\label{report-reject-report-cmd}
\index{report::reject\_report\_cmd()}

Concerns reject reports of mail commands. These informations are sent at the end of the mail processing.
There are many uses cases :

   \begin{enumerate}
      \item \textbf{internal server error} :
	\begin{itemize}
	   \item \file{reject\_report\_cmd('intern',\$error,\$data,\$cmd,\$sender,\$robot)}
           \item \file{reject\_report\_cmd('intern\_quiet',\$error,\$data,\$cmd)} : the listmaster won't be noticied
         \end{itemize}
       \item \textbf{user error} : \\
	\file{reject\_report\_cmd('user',\$error,\$data,\$cmd)}
      \item \textbf{non authorization} : \\
	\file{reject\_report\_cmd('auth',\$error,\$data,\$cmd)}
  \end{enumerate}

  \textbf{IN} : 
  \begin{enumerate}
     \item \lparam{type}(+): 'intern'\(\mid\)'intern\_quiet'\(\mid\)'user'\(\mid\)'auth'
     \item \lparam{error}: SCALAR - depends on \$type :
	 \begin{itemize}
	   \item 'intern' : string error sent to listmaster
	   \item 'user' : \$u\_err.entry  in \file{command\_report.tt2}
	   \item 'auth' : \$reason  in \file{authorization\_reject.tt2}
	 \end{itemize}
     \item \lparam{data}: ref(HASH) - for variable instantiation in \file{command\_report.tt2}
     \item \lparam{cmd}: SCALAR - the rejected command, \$xx.cmd in \file{command\_report.tt2}
     \item \lparam{sender}: SCALAR - the user to notify
     \item \lparam{robot}: SCALAR - robot
  \end{enumerate}

  \textbf{OUT} : 1 \(\mid\) undef

\subsubsection {\large{notice\_report\_cmd()}}
\label{report-notice-report-cmd}
\index{report::notice\_report\_cmd()}

Concerns positive notices  of mail commands. These informations are sent at the end of the mail processing.

  \textbf{IN} : 
  \begin{enumerate}
     \item \lparam{entry}: \$notice.entry in \file{command\_report.tt2}
     \item \lparam{data}: ref(HASH) - for variable instantiation in \file{command\_report.tt2}
     \item \lparam{cmd}: SCALAR - the rejected command, \$xx.cmd in \file{command\_report.tt2}
  \end{enumerate}

  \textbf{OUT} : 1 \(\mid\) undef


\subsubsection {\large{send\_report\_cmd()}}
\label{report-send-report-cmd}
\index{report::send\_report\_cmd()}

   Sends the template \file{command\_report.tt2} to \$sender with global arrays and then calls to
   \file{init\_report\_command.tt2} function. (It is used by sympa.pl at the end of mail process if there are some reports in gloal arrays)

   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{sender}(+): SCALAR - the user to notify
      \item \lparam{robot}(+): SCALAR - robot
   \end{enumerate}
   \textbf{OUT} : 1 

%%%%%%%%%%%%%%% Web commands  %%%%%%%%%%%%%%%%%%%%
\subsection {Web commands} 
\label {report-web-commands}

It can have many errors and notices so they are stored in module global arrays before html sending.
(\@intern\_error\_web, \@user\_error\_web, \@auth\_reject\_web, \@notice\_web). 
These reports use \file{web\_tt2/notice.tt2} template for notices and \file{web\_tt2/error.tt2} template
for rejects.


\subsubsection {\large{init\_report\_web()}}
\label{report-init-report-web}
\index{report::init\_report\_web()}

   Inits global arrays for web command reports.

   \textbf{IN} : -

   \textbf{OUT} : -

\subsubsection {\large{is\_there\_any\_reject\_report\_web()}}
\label{report-is-there-any-reject-report-web}
\index{report::is\_there\_any\_reject\_report\_web()}

   Looks for some rejected web command reports in one of global arrays for reject. 

   \textbf{IN} : -

   \textbf{OUT} : 1 \emph{if there are some reject reports to send (not notice)}

\subsubsection {\large{get\_intern\_error\_web()}}
\label{report-get-intern-error-web}
\index{report::get\_intern\_error\_web()}

   Return array of web intern error

   \textbf{IN} : -

   \textbf{OUT} : ref(ARRAY) - clone of \@intern\_error\_web

\subsubsection {\large{get\_user\_error\_web()}}
\label{report-get-user-error-web}
\index{report::get\_user\_error\_web()}

   Return array of web user error

   \textbf{IN} : -

   \textbf{OUT} : ref(ARRAY) - clone of \@user\_error\_web

\subsubsection {\large{get\_auth\_reject\_web()}}
\label{report-get-auth-reject-web}
\index{report::get\_auth\_reject\_web()}

   Return array of web authorisation reject

   \textbf{IN} : -

   \textbf{OUT} : ref(ARRAY) - clone of \@auth\_reject\_web

\subsubsection {\large{get\_notice\_web()}}
\label{report-get-notice-web}
\index{report::get\_notice\_web()}

   Return array of web notice

   \textbf{IN} : -

   \textbf{OUT} : ref(ARRAY) - clone of \@notice\_web

\subsubsection {\large{reject\_report\_web()}}
\label{report-reject-report-web}
\index{report::reject\_report\_web()}

Concerning reject reports of web commands, there are many uses cases :

   \begin{enumerate}
      \item \textbf{internal server error} :
	\begin{itemize}
	   \item \file{reject\_report\_web('intern',\$error,\$data,\$action,\$list,\$user,\$robot)}
           \item \file{reject\_report\_web('intern\_quiet',\$error,\$data,\$action,\$list)} : the listmaster won't be noticied
         \end{itemize}
       \item \textbf{user error} :\\
	\file{reject\_report\_web('user',\$error,\$data,\$action, \$list)}
      \item \textbf{non authorization} :\\
	\file{reject\_report\_web('auth',\$error,\$data,\$action, \$list)}
  \end{enumerate}

  \textbf{IN} : 
  \begin{enumerate}
     \item \lparam{type}(+): 'intern'\(\mid\)'intern\_quiet'\(\mid\)'user'\(\mid\)'auth'
     \item \lparam{error}(+): SCALAR - depends on \$type :
	 \begin{itemize}
	   \item 'intern' : \$error in \file{listmaster\_notification.tt2} and possibly \$i\_err.msg in \file{error.tt2}
	   \item 'intern\_quiet' : possibly \$i\_err.msg in \file{error.tt2}
	   \item 'user' : \$u\_err.msg  in \file{error.tt2}
	   \item 'auth' : \$reason  in \file{authorization\_reject.tt2}
	 \end{itemize}
     \item \lparam{data}: ref(HASH) - for variable instantiation in \file{notice.tt2}
     \item \lparam{action}(+): SCALAR - the rejected actin, \$xx.action in \file{error.tt2}, \$action in \file{listmaster\_notification.tt2}
     \item \lparam{list}: '' \(\mid\) ref(List)
     \item \lparam{user}: SCALAR - the user for listmaster notification
     \item \lparam{robot}: SCALAR - robot for listmaster notification
  \end{enumerate}

  \textbf{OUT} : 1 \(\mid\) undef








\subsubsection {\large{notice\_report\_web()}}
\label{report-notice-report-web}
\index{report::notice\_report\_web()}

Concerns positive notices of web commands.

  \textbf{IN} : 
  \begin{enumerate}
     \item \lparam{msg}: \$notice.msg in \file{notice.tt2}
     \item \lparam{data}: ref(HASH) - for variable instantiation in \file{notice.tt2}
     \item \lparam{action}: SCALAR - the noticed command, \$notice.cmd in \file{notice.tt2}
  \end{enumerate}

  \textbf{OUT} : 1 \(\mid\) undef





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%% tools.pl %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\section {tools.pl}
\index{tools.pl}

 This module provides various tools for Sympa.

\subsubsection {\large{checkcommand()}}
\label{tools-checkcommand}
\index{tools::checkcommand()}

   Checks for no command in the body of the message. If there are some command in it, 
   it returns true and sends a message to \$sender by calling  List::send\_global\_file() 
   (see \ref {list-send-global-file}, page~\pageref {list-send-global-file}) with mail 
   template ``message\_report''.

   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{msg}(+): ref(MIME::Entity) - the message to check
      \item \lparam{sender}(+): the message sender
      \item \lparam{robot}(+): robot
   \end{enumerate}

   \textbf{OUT} : 
     \begin{itemize}
       \item 1 \emph{if there are some command in the message}
       \item 0 \emph{else}
     \end{itemize}

\subsubsection {\large{get\_array\_from\_splitted\_string()}}
\label{tools-get-array-from-splitted-string}
\index{tools::get\_array\_from\_splitted\_string()}  

  Return an array made from a string splitted by ','.
 It removes spaces.

   \textbf{IN} : \lparam{string}(+): string to split

   \textbf{OUT} : ref(ARRAY) - 

\subsubsection {\large{diff\_on\_arrays()}}
\label{tools-diff-on-arrays}
\index{tools::diff\_on\_arrays()}

Makes set operation on arrays seen as set (with no double) :

   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{A}(+):  ref(ARRAY) - set
      \item \lparam{B}(+):  ref(ARRAY) - set
   \end{enumerate}

   \textbf{OUT} : ref(HASH) with keys : 
     \begin{itemize}
       \item deleted : A \(\setminus\) B
       \item added : B \(\setminus\) A
       \item intersection : A \(\cap\) B
       \item union : A \(\cup\) B
     \end{itemize}

\subsubsection {\large{clean\_msg\_id()}}
\label{tools-clean-msg-id}
\index{tools::clean\_msg\_id()}  

  Cleans a msg\_id to use it without '\\n', '\\s', < and >.

   \textbf{IN} : \lparam{msg\_id}(+): the message id

   \textbf{OUT} : the clean msg\_id

\subsubsection {\large{clean\_email()}}
\label{tools-clean-email}
\index{tools::clean\_email()}  

  Lower-case it and remove leading and trailing spaces.

   \textbf{IN} : \lparam{msg\_id}(+): the email

   \textbf{OUT} : the clean email

\subsubsection {\large{make\_tt2\_include\_path()}}
\label{tools-make-tt2-include-path}
\index{tools::make\_tt2\_include\_path()}  

 Make an array of include path for tt2 parsing

   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{robot}(+):  SCALAR - the robotset
      \item \lparam{dir}:  SCALAR - directory ending each path
      \item \lparam{lang}:  SCALAR - for lang directories
      \item \lparam{list}:  ref(List) - for list directory
   \end{enumerate}  

   \textbf{OUT} : ref(ARRAY) - include tt2 path, respecting 
       path priorities.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%% Message.pm %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\section {Message.pm}
\index{Message.pm}

 This module provides objects to encapsulate file message in order to prevent it from its alteration
 for using signatures.

\subsubsection {\large{new()}}
\label{message-new}
\index{message::new()}  

  Creates an object Message and initialize it :
  \begin{itemize}
    \item \lparam{msg} : ref(MIME::Entity)
    \item \lparam{altered} \emph{if the message is altered} 
    \item \lparam{filename} : the file containing the message
    \item \lparam{size} : the message size
    \item \lparam{sender} : the first email address, in the 'From' field
    \item \lparam{decoded\_subject} : the 'Subject' field decoded by MIME::Words::decode\_mimewords
    \item \lparam{subject\_charset} : the charset used to encode the 'Subject' field
    \item \lparam{rcpt} : the 'X-Sympa-To' field
    \item \lparam{list} : ref(List) \emph{if it is a message no addressed to \Sympa or a listmaster} 
    \item \lparam{topic} : the 'X-Sympa-Topic' field. 
    \item \emph{in a 'openssl' context - decrypt message} : \begin{itemize}
      \item \lparam{smime\_crypted} : 'smime\_crypted' \emph{if it is in a 'openssl' context} 
      \item \lparam{orig\_msg} : ref(MIME::Entity) - crypted message
      \item \lparam{msg} : ref(MIME::Entity) - decrypted message (see tools::smime\_decrypt())
      \item \lparam{msg\_as\_string} : string - decrypted message (see tools::smime\_decrypt())
      \end{itemize}	
    \item \emph{in a 'openssl' context - check signature} : \begin{itemize}	
      \item \lparam{protected} : 1 \emph{if the message should not be altered} 
      \item \lparam{smime\_signed} : 1 \emph{if the message is signed} 
      \item \lparam{smime\_subject} : ref(HASH)\emph{if the message is signed} - information on the signer
	see tools::smime\_parse\_cert().
      \end{itemize}
   \end{itemize}

   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{pkg}(+):  Message
      \item \lparam{file}(+):  the message file
   \end{enumerate}

   \textbf{OUT} :   ref(Message) \(\mid\) undef

\subsubsection {\large{dump()}}
\label{message-dump}
\index{message::dump()}  

Dump the message object in the file descriptor \$output

   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{self}(+):  ref(Message)
      \item \lparam{output}(+): file descriptor  
   \end{enumerate}

   \textbf{OUT} :  '1'
 
\subsubsection {\large{add\_topic()}}
\label{message-add-topic}
\index{message::add\_topic()}  

Adds the message topic in the Message object (\lparam{topic'} and adds
the 'X-Sympa-Topic' field in the ref(MIME::Entity) \lparam{msg'}.

   \textbf{IN} : 
   \begin{enumerate}
      \item \lparam{self}(+):  ref(Message)
      \item \lparam{topic}(+): string splitted by ',' - list of topic 
   \end{enumerate}

   \textbf{OUT} :  '1'
 
\subsubsection {\large{get\_topic()}}
\label{message-get-topic}
\index{message::get\_topic()}  

Returns the topic(s) of the message

   \textbf{IN} : \lparam{self}(+):  ref(Message)

   \textbf{OUT} :  '' \emph{if no message topic} | string splitted by ',' \emph{if message topic}
 



N.B.:
\begin{itemize}
\item (+) : required parameter, value must not be empty 
\item \(\mid\) : ``or'' for parameters value 
\item \$ : reference to code parameters or variables
\item \emph{condition for parameter}
\end{itemize}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Appendices
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Index
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\cleardoublepage
\printindex

\end {document}