%
% Copyright (C) 1999, 2000, 2001 Comité Réseau des Universités & Serge Aumont, Olivier Salaün
%
% Historique
%   1999/04/12 : pda@prism.uvsq.fr : conversion to latex2e
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
addresses from an \index {LDAP} directory or \index {SQL} server, and include them
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
\htmladdnormallink {sympa} {http://listes.cru.fr/sympa/}.

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

    \item \textbf {Multilingual} messages. The current version of
        \Sympa allows the administrator to choose the language
        catalog at run time. At the present time the \Sympa robot is available in
        Chinese, Czech, English, Finnish, French, German, Hungarian, Italian, Polish, 
	Portuguese, Spanish, Romanian. The web interface is available in English, Spanish,
	French, Chinese, Czech, Hungarian, Italian.

    \item \textbf {MIME support}. \Sympa naturally respects
        \textindex {MIME} in the distribution process, and in addition
        allows list owners to configure their lists with
        welcome, goodbye and other predefined messages using complex
        \textindex {MIME} structures. For example, a welcome message can be
        \textbf in {multipart/alternative} format, using \textbf {text/html},
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
        \lparam {send} parameter (\ref {par-send}, page~\pageref
        {par-send}). The sending process configuration (as well as most other list
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
        can also be defined for a particular virtual robot).
        Privileged operations include the usual \mailcmd {ADD}, \mailcmd
        {DELETE} or \mailcmd {REVIEW} commands, which can be
        authenticated via a one-time password or an S/MIME signature.
	 Any list owner using the \mailcmd {EXPIRE}
        command can require the renewal of subscriptions. This is made
        possible by the presence of a subscription date stored in the
        \Sympa database.

    \label {wwsympa} 
    \item textbf {Web interface} : {\WWSympa} is a global Web interface to all \Sympa functions
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

    \item \textbf {RDBMS} : the internal subscriber data structure can be stored in a
        database or, for compatibility with versions 1.x, in text
        files. The introduction of databases came out of the
        \WWSympa project.  The database ensures a secure access to
        shared data. The PERL database API \perlmodule {DBI}/\perlmodule {DBD} enables
        interoperability with various \index{RDBMS} (\index{MySQL}, \index{PostgreSQL},
        \index{Oracle}, \index{Sybase}).
	(See ref {sec-rdbms}, page~\pageref {sec-rdbms})

    \item \textbf {Virtual robots} : a single \Sympa installation
        can provide multiple virtual robots with both email and web interface
        customization (See \ref {virtual-robot}, page~\pageref {virtual-robot}).

    \item \textbf {\index {LDAP-based mailing lists}} : e-mail addresses can be retrieved dynamically from a database
    	accepting \index {SQL} queries, or from an \index {LDAP} directory. In the interest
	of reasonable response times, \Sympa retains the data source in an
	internal cache controlled by a TTL (Time To Live) parameter.
	(See ref {include-ldap-query}, page~\pageref {include-ldap-query})

    \item \textbf {\index {LDAP authentication}}:  via uid and emails stored 
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

\end {itemize}

\section {Project directions}

\Sympa is a very active project : check the release note 
\htmladdnormallinkfoot {release note} {http://listes.cru.fr/sympa/release.shtml}.
So it is no longer possible to
maintain multiple document about Sympa project direction.
Please refer to \htmladdnormallinkfoot {in-the-futur document} {http://www.sympa.org/sympa/direct/in-the-future.html}
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
   \item Mar 1999 Internal use of a database (Mysql), definition of list subscriber with external datasource (RDBMS or \index {LDAP}).
   \item Oct 1999 Stable version of WWsympa, introduction of authorization scenarios.
   \item Feb 2000 Web bounces management
   \item Apr 2000 Archives search engine and message removal
   \item May 2000 List creation feature from the web
   \item Jan 2001 Support for S/MIME (signing and encryption), list setup through the web interface, Shared document repository for each list. Full rewrite of HTML look and feel
   \item Jun 2001 Auto-install of aliases at list creation time, antivirus scanner plugging
   \item Jan 2002 Virtual robot, \index {LDAP authentication}
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

  \item Pierre David, who in addition to his help and suggestions
       in developing the code, participated more than actively in
       producing this manual.

  \item David Lewis who corrected this documentation

  \item Philippe Rivière for his persevering in tuning \Sympa for Postfix.

  \item Rapha\"el Hertzog (debian), Jerome Marant (debian) and St\'ephane Poirey (redhat) for
      Linux packages.

  \item Loic Dachary for guiding us through the \textit {GNU Coding Standards}

  \item Vincent Mathieu, Lynda Amadouche, John Dalbec for their integration
	of \index {LDAP} features in \Sympa.

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

There are also a few \htmladdnormallinkfoot {mailing-lists about \Sympa} {http://listes.cru.fr/wws/lists/informatique/sympa} :

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

You may also consult the \Sympa \htmladdnormallink {home page} {http://listes.cru.fr/sympa},
you will find the latest version, \htmladdnormallink {FAQ} {http://listes.cru.fr/sympa/fom-serve/cache/1.html} and so on.

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
a virtual robot or for the whole site.  
 
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
	files, recognized S/Mime certificates).

	\item \dir {[ETCDIR]}\\
	This is your site's configuration directory. Consult
	\dir {[ETCBINDIR]} when drawing up your own.

	\item \dir {[ETCDIR]/create\_list\_templates/}\\
	List templates (suggested at list creation time).

	\item \dir {[ETCDIR]/scenari/}\\
	This directory will contain your authorization scenarios.
	If you don't know what the hell an authorization scenario is, refer to \ref {scenarios}\ref {scenarios}, 
	page~\pageref {scenarios}. Those authorization scenarios are default scenarios but you may look at
        \dir {[ETCDIR]/\samplerobot/scenari/} for default scenarios of \samplerobot
        virtual robot and \dir {[EXPL_DIR]/\samplelist/scenari} for scenarios
        specific to a particular list 

	\item \dir {[ETCDIR]/list\_task\_models/}\\
	This directory will store your own list task models (see \ref {tasks}, page~\pageref {tasks}).	

	\item \dir {[ETCDIR]/global\_task\_models/}\\
	Contains global task models of yours (see \ref {tasks}, page~\pageref {tasks}).		
	
	\item \dir {[ETCDIR]/wws\_templates/}\\
	The web interface (\WWSympa) is composed of template HTML
	files parsed by the CGI program. Templates can also 
        be defined for a particular list in \dir {[EXPL_DIR]/\samplelist/wws\_templates/}
        or in \dir {[ETCDIR]/\samplerobot/wws\_templates/}

	\item \dir {[ETCDIR]/templates/}\\
	Some of the mail robot's replies are defined by templates
	(\file{welcome.tpl} for SUBSCRIBE). You can overload
	these template files in the individual list directories or
        for each virtual robot, but these are the defaults.


	\item \dir {[ETCDIR]/\samplerobot}\\
        The directory to define the virtual robot \samplerobot dedicated to
        managment of all lists of this domain (list description of \samplerobot are stored
        in \dir {[EXPL_DIR]/\samplerobot}).
        Those directories for virtual robots have the same structure as  \dir {[ETCDIR]} which is
        the configuration dir of the default robot. 

	\item \dir {[EXPL_DIR]}\\
	\Sympa's working directory.

	\item \dir {[EXPL_DIR]/\samplelist}\\
	The list directory (refer to \ref {list-directory}, 
	page~\pageref {list-directory}). Lists stored in this directory
        belong to the default robot as defined in sympa.conf file, but a list
        can be stored in \dir {[EXPL_DIR]/\samplerobot/\samplelist} directory and it
        is managed by \samplerobot virtual robot.

	\item \dir {[EXPL_DIR]/X509-user-certs}\\
	The directory where Sympa stores all user's certificates

	\item \dir {[NLSDIR]}\\
	Internationalization directory. It contains XPG4-compatible
	message catalogues. \Sympa has currently been translated
	into 14 different languages.

	\item \dir {[SPOOLDIR]}\\
	\Sympa uses 7 different spools (see \ref{spools}, page~\pageref{spools}).

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
	Maybe it is a good idea to run it at the beginning, but thoses
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
	Defines authentication backend organisation ( \index {LDAP-based authentication},  \index {CAS-based authentication} and sympa internal )

	\item \file {robot.conf}\\
	It is a subset of \file {sympa.conf} defining a Virtual robot 
	(one per Virtual robot).

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

	\item \dir {[SPOOLDIR]/expire/}\\
	Used by the expire process.

	\item \dir {[SPOOLDIR]/mod/}\\
	For storing unmoderated messages.

	\item \dir {[SPOOLDIR]/msg/}\\
	For storing incoming messages (including commands).

	\item \dir {[SPOOLDIR]/msg/bad/}\\
	\Sympa stores rejected messages in this directory
	
	\item \dir {[SPOOLDIR]/task/}\\
	For storing all created tasks.

	\item \dir {[SPOOLDIR]/outgoing/}\\
	\file {sympa.pl} dumps messages in this spool to await archiving
	by \file {archived.pl}.

\end {itemize}


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
\htmladdnormallink {\texttt {http://listes.cru.fr/sympa/}}
    {http://listes.cru.fr/sympa/}.
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

    \item installing a \index{RDBMS} (\index{Oracle}, \index{MySQL}, \index{Sybase} or \index{PostgreSQL}) and creating \Sympa's Database. This is required for using the web interface for \Sympa. Please refers to \"\Sympa and its database\" section (\ref {sec-rdbms}, page~\pageref {sec-rdbms}).

    \item installation of
	\index{CPAN}
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
%, as well as XPG4-standard \textindex {NLS}
%(Native Language Support, for languages other than English) extensions.

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

% If your UNIX system has a \unixcmd {gencat} command as well as
% \unixcmd {catgets(3)} and \unixcmd {catopen(3)} functions, it is
% likely that it has \textindex {NLS} extensions and that these extensions comply
% with the XPG4 specifications.

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
PERL distribution. We try to keep this list up to date ; if you have any doubts
run the \unixcmd {check\_perl\_modules.pl} script.

\begin {itemize}
   \item \perlmodule {DB\_File} (v. 1.50 or later)
   \item \perlmodule {Digest-MD5}
   \item \perlmodule {MailTools} (version 1.13 o later)
   \item \perlmodule {IO-stringy}
   \item \perlmodule {MIME-tools} (may require IO/Stringy)
   \item \perlmodule {MIME-Base64}
   \item \perlmodule {CGI}
   \item \perlmodule {File-Spec}
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

If you plan to interface \Sympa with an \index {LDAP} directory to build
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
using \index {FastCGI}. Therefore you need to install the following Perl module :

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
configuration files; an \dir {nls/} directory where multi-lingual
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

\item \option {- -prefix=PREFIX}, the \Sympa homedirectory (default /home/sympa/)

\item \option {--with-bindir=DIR}, user executables in DIR (default /home/sympa/bin/)\\
\file {queue} and \file {bouncequeue} programs will be installed in this directory.
If sendmail is configured to use smrsh (check the mailer prog definition in your sendmail.cf),
this should point to \dir {/etc/smrsh}.  This is probably the case if you are using Linux RedHat.

\item \option {--with-sbindir=DIR}, system admin executables in DIR (default /home/sympa/bin)

\item \option {--with-libexecdir=DIR}, program executables in DIR (default /home/sympa/bin)

\item \option {--with-cgidir=DIR}, CGI programs in DIR (default /home/sympa/bin)

\item \option {--with-iconsdir=DIR}, web interface icons in DIR (default /home/httpd/icons)

\item \option {--with-datadir=DIR}, default configuration data in DIR (default /home/sympa/bin/etc)

\item \option {--with-confdir=DIR}, Sympa main configuration files in DIR (default /etc)\\
\file {sympa.conf} and \file {wwsympa.conf} will be installed there.

\item \option {--with-exlpdir=DIR}, modifiable data in DIR (default /home/sympa/expl/)

\item \option {--with-libdir=DIR},  code libraries in DIR (default /home/sympa/bin/)

\item \option {--with-mandir=DIR}, man documentation in DIR (default /usr/local/man/)

\item \option {--with-docdir=DIR}, man files in DIR (default /home/sympa/doc/)

\item \option {--with-initdir=DIR}, install System V init script in DIR  (default /etc/rc.d/init.d)

\item \option {--with-piddir=DIR}, create .pid files in DIR  (default /home/sympa/)

\item \option {--with-etcdir=DIR}, Config directories populated by the user are in DIR (default /home/sympa/etc)

\item \option {--with-nlsdir=DIR}, create language files in DIR (default /home/sympa/nls)

\item \option {--with-scriptdir=DIR}, create script files in DIR (default /home/sympa/script)

\item \option {--with-sampledir=DIR}, create sample files in DIR (default /home/sympa/sample)

\item \option {--with-spooldir=DIR}, create directory in DIR (default /home/sympa/spool)

\item \option {--with-perl=FULLPATH}, set full path to Perl interpreter (default /usr/bin/perl)

\item \option {--with-openssl=FULLPATH}, set path to OpenSSL (default /usr/local/ssl/bin/openssl)

\item \option {--with-user=LOGIN}, set sympa user name (default sympa)\\
\Sympa daemons are running under this UID.

\item \option {--with-group=LOGIN}, set sympa group name (default sympa)\\
\Sympa daemons are running under this UID.

\item \option {--with-sendmail\_aliases=ALIASFILE}, set aliases file to be used by Sympa (default /etc/mail/sympa\_aliases)\\

\item \option {--with-virtual\_aliases=ALIASFILE}, set postfix virtual file to be used by Sympa (default /etc/mail/sympa\_virtual)\\

This is used by the \file {alias\_manager.pl} script :

\item \option {--with-newaliases=FULLPATH}, set path to sendmail newaliases command (default /usr/bin/newaliases)

\item \option {--with-newaliases\_arg=ARGS}, set arguments to newaliases command (default NONE)

This is used by the \file {postfix\_manager.pl} script :

\item \option {--with-postmap=FULLPATH}, set path to postfix postmap command (default /usr/sbin/postmap)

\item \option {--with-postmap\_arg=ARGS}, set arguments to postfix postmap command (default NONE)


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

\section {sympa.pl}
\label{sympa.pl}

Once the files are configured, all that remains is to start \Sympa.
At startup, \file {sympa.pl} will change its UID to sympa (as defined in \file {Makefile}).
To do this, add the following sequence or its equivalent in your
\file {/etc/rc.local}:

\begin {quote}
\begin{verbatim}

~sympa/bin/sympa.pl
~sympa/bin/archived.pl
~sympa/bin/bounced.pl
~sympa/bin/task_manager.pl

\end{verbatim}
\end {quote}

\file {sympa.pl} recognizes the following command line arguments:

\begin {itemize}

\item \option {--debug} | \option {-d} 
  
  Sets \Sympa in debug mode and keeps it attached to the terminal. 
  Debugging information is output to STDERR, along with standard log
  information. Each function call is traced. Useful while reporting
  a bug.
  
\item \option {--config \textit {config\_file}} | \option {-f \textit {config\_file}}
  
  Forces \Sympa to use an alternative configuration file. Default behavior is
  to use the configuration file as defined in the Makefile (\$CONFIG).
  
\item \option {--mail} | \option {-m} 
  
  \Sympa will log calls to sendmail, including recipients. Useful for
  keeping track of each mail sent (log files may grow faster though).
  
\item \option {--lang \textit {catalog}} | \option {-l \textit {catalog}}
  
  Set this option to use a language catalog for \Sympa. 
  The corresponding catalog file must be located in \tildedir {sympa/nls}
  directory. 
  
\item \option {--keepcopy \textit {recipient\_directory}} | \option {-k \textit {recipient\_directory}}

  This option tells Sympa to keep a copy of every incoming message,
  instead of deleting them. \textit {recipient\_directory} is the directory
  to store messages.

  
  \begin {quote}
\begin{verbatim}
/home/sympa/bin/sympa.pl
\end{verbatim}
  \end {quote}


\item \option {--close\_list \textit {listname@robot}}

Close the list (changing its status to closed), remove aliases and remove
subscribers from DB (a dump is created in the list directory to allow restoring
the list)

\item \option {--dump \textit {listname \texttt {|} ALL}}
  
  Dumps subscribers of a list or all lists. Subscribers are dumped
  in \file {subscribers.db.dump}.
 
\item \option {--import \textit {listname}}
  
Import subscribers in the \textit {listname} list. Data are read from STDIN.
  
\item \option {--lowercase}
  
Lowercases e-mail addresses in database.

\item \option {--help} | \option {-h}
  
  Print usage of sympa.pl.
   
\item \option {--make\_alias\_file}
  
Create an aliases file in /tmp/ with all list aliases. It uses the list\_aliases.tpl
template.

\item \option {--version} | \option {-v}
  
  Print current version of \Sympa.
 
  
\end {itemize}


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
sympa:             "| [MAILERPROGDIR]/queue sympa@\samplerobot"
listmaster: 	   "| [MAILERPROGDIR]/queue listmaster@\samplerobot"
bounce+*:          "| [MAILERPROGDIR]/bouncequeue sympa@\samplerobot"
sympa-request:     postmaster
sympa-owner:       postmaster
\end {quote}

Note: if you run \Sympa virtual robots, you will need one \mailaddr {sympa}
alias entry per virtual robot (see virtual robots section, \ref {virtual-robot},
page~\pageref {virtual-robot}).

\mailaddr {sympa-request} should be the address of the robot
\textindex {administrator}, i.e. a person who looks after
\Sympa (here \mailaddr {postmaster{\at}cru.fr}).

\mailaddr {sympa-owner} is the return address for \Sympa error
messages.

The alias bounce+* is dedicated to collect bounces. It is useful
only if at least one list uses \texttt { welcome\_return\_path unique } or
\texttt { remind\_return\_path unique}.
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
            "|[MAILERPROGDIR]/queue \samplelist-subscribe@\samplerobot@\samplerobot"
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
non-delivery reports. The \file {bouncequeue} program stores these messages 
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

\file {[BINDIR]/alias\_manager.pl} works on the alias file as defined
by the \index{SENDMAIL\_ALIASES} variable (default is \file {/etc/mail/sympa\_aliases}) in the main Makefile (see \ref {makefile},  page~\pageref {makefile}). You must refer to this aliases file in your \file {sendmail.cf} (if using sendmail) :
\begin {quote}
\begin{verbatim}
define(`ALIAS_FILE', `/etc/aliases,/etc/mail/sympa_aliases')dnl
\end{verbatim}
\end {quote}


\file {[BINDIR]/alias\_manager.pl} runs a \unixcmd{newaliases} command (via \file {aliaswrapper}), after any changes to aliases file.

If you manage virtual domains with your mail server, then you might want to change
the form of aliases used by the alias\_manager. You can customize the \file {list\_aliases}
template that is parsed to generate list aliases (see\ref {list-aliases-tpl},  
page~\pageref {list-aliases-tpl}).

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
/\verb+^+(.*)\samplerobot\$/	 \samplerobot-\${1}
\end {quote}
 Entries in the 'aliases' file will look like this :
\begin {quote}
    \samplerobot-sympa:   "|[MAILERPROGDIR]/sympa.pl sympa@\samplerobot"
    .....
    \samplerobot-listA:   "|[MAILERPROGDIR]/sympa.pl listA@\samplerobot"
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
        global  server commands). Listmasters can be defined for each virtual robot.

        \example {listmaster postmaster@cru.fr,root@cru.fr}

\subsection {\cfkeyword {wwsympa\_url}}  

	 \default {http://\texttt{<}host\texttt{>}/wws}

	This is the root URL of \WWSympa.

        \example {wwsympa\_url https://my.server/wws}

\subsection {\cfkeyword {spam\_protection}}  

    \index{spam\_protection}
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
        A additional value is availible : cookie which mean that users
        must submit a small form in order to receive a cookie before
        browsing archives. This block all robot, even google and co.


\subsection {\cfkeyword {dark\_color} \cfkeyword {light\_color} \cfkeyword {text\_color} \cfkeyword {bg\_color} \cfkeyword {error\_color} \cfkeyword {selected\_color} \cfkeyword {shaded\_color}}
\label {colors}

	They are the color definition for web interface. Default are set in the main Makefile. Thoses parameters can be overwritten in each virtual robot definition.

\subsection {\cfkeyword {cookie}} 

	This string is used to generate MD5 authentication keys.
	It allows generated authentication keys to differ from one
	site to another. It is also used for reversible encryption of
        user passwords stored in the database. The presence of this string
	is one reason why access to \file {sympa.conf} needs to be restricted
	to the Sympa user. 
       
        Note that changing this parameter will break all
        http cookies stored in users' browsers, as well as all user passwords
	and lists X509 private keys.

        \example {cookie gh869jku5}

\subsection {\cfkeyword {create\_list}}  

	\label{create-list}

	 \default {public\_listmaster}

	\scenarized {create\_list}

	Defines who can create lists (or request list creations).
	Sympa will use the corresponding authorization scenario.

        \example {create\_list intranet}

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
	\dir {scenari} for local authorization scenarios; \dir {templates}
	for the site's local templates and default list templates; \dir {wws\_templates}
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

\subsection {\cfkeyword {umask}} 

	\default {027}

        Default mask for file creation (see \unixcmd {umask}(2)).
	Note that it will be interpreted as an octual value.

        \example {umask 007}

\section {Sending related}

\subsection {\cfkeyword {maxsmtp}} 

	\default {20}

        Maximum number of SMTP delivery child processes spawned
        by  \Sympa. This is the main load control parameter.

        \example {maxsmtp           500}

\subsection {\cfkeyword {log\_smtp}} 

	\default {off}

	Set logging of each MTA call. Can be overwritten by -m sympa option.

        \example {log\_smtp           on}


\subsection {\cfkeyword {max\_size}} 

	\default {5 Mb}

	Maximum size allowed for messages distributed by \Sympa.
	This may be customized per virtual robot or per list by setting the \lparam {max\_size} 
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

        Maximum number of recipients per \unixcmd {sendmail} call.
        This grouping factor makes it possible for the (\unixcmd
        {sendmail}) MTA to optimize the number of SMTP sessions for
        message distribution.

\subsection {\cfkeyword {avg}} 

	\default {10}

        Maximum number of different internet domains within addresses per
        \unixcmd {sendmail} call.

\subsection {\cfkeyword {sendmail}} 

	\default {/usr/sbin/sendmail}

        Absolute call path to SMTP message transfer agent (\unixcmd
        {sendmail} for example).

        \example {sendmail        /usr/sbin/sendmail}

\subsection {\cfkeyword {sendmail\_args}} 

	\default {-oi -odi -oem}

        Arguments passed to SMTP message transfer agent

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
	server for every virtual robot you are running. This is needed if you are
	running \Sympa on somehost.foo.org, but you handle all your mail on a
	separate mail relay.

\subsection {\cfkeyword {list\_check\_suffixes}} 

        \default {request,owner,unsubscribe}

	This paramater is a comma-separated list of admin suffixes you're using
	for \Sympa aliases, i.e. \samplelist-request, \samplelist-owner etc...
	This parameter is used with \cfkeyword {list\_check\_smtp} parameter.
	It is also used to check list names at list creation time.


\section {Quotas}
\label {quotas}

\subsection {\cfkeyword {default\_shared\_quota}}

	The default disk quota for lists' document repository.
 
\subsection {\cfkeyword {default\_archive\_quota}}

	The default disk quota for lists' web archives.


\section {Spool related}
\label {spool-related}
\subsection {\cfkeyword {spool}}

        \default {\dir {[SPOOLDIR]}}

	The parent directory which contains all the other spools.  
        

\subsection {\cfkeyword {queue}} 

        The absolute path of the directory which contains the queue, used both by the
        \file {queue} program and the \file {sympa.pl} daemon. This
        parameter is mandatory.

        \example {queue          /home/sympa/queue}


\subsection {\cfkeyword {queuemod}}  
        \label {cf:queuemod}
        \index{moderation}

	\default {\dir {[SPOOLDIR]/moderation}}

        This parameter is optional and retained solely for backward compatibility.


\subsection {\cfkeyword {queuedigest}}  
        \index{digest}
        \index{spool}

        This parameter is optional and retained solely for backward compatibility.

\subsection {\cfkeyword {queueexpire}}  

	\default {\dir {[SPOOLDIR]/expire}}

        This parameter is optional and retained solely for backward compatibility.

\subsection {\cfkeyword {queueauth}} 

	\default {\dir {[SPOOLDIR]/auth}}

        This parameter is optional and retained solely for backward compatibility.

\subsection {\cfkeyword {queueoutgoing}} 

	\default {\dir {[SPOOLDIR]/outgoing}}

	This parameter is optional and retained solely for backward compatibility.

\subsection {\cfkeyword {queuebounce}} 
    \index{bounce}

	\default {\dir {[SPOOLDIR]/bounce}}

        Spool to store bounces (non-delivery reports) received by the \file {bouncequeue}
	program via the \samplelist-owner or bounce+* addresses . This parameter is mandatory
        and must be an absolute path.

\subsection {\cfkeyword {queuetask}} 
    \index{bounce}

	\default {\dir {[SPOOLDIR]/task}}

        Spool to store task files created by the task manager. This parameter is mandatory
        and must be an absolute path.

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

\section {Internationalization related}    

\subsection {\cfkeyword {msgcat}}   

	\default{\dir {[NLSDIR]}}

        The location of multilingual (nls) catalog files. Must correspond to
	\tildefile {src/nls/Makefile}.

\subsection {\cfkeyword {lang}}   

	\default {us}

        This is the default language for \Sympa. The message
	catalog (.msg) located in the corresponding \cfkeyword {nls} directory
	will be used.

\section {Bounce related}

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

\subsection {\cfkeyword {welcome\_return\_path}}
        \label {kw-welcome-return-path}
         
        \default {owner}

	If set to string \texttt {unique}, sympa will use a unique e-mail address in the
        return path, prefixed by \texttt {bounce+}, in order to remove the corresponding
	subscriber. Requires the \texttt {bounced} daemon to run and bounce+* alias to
	be installed (plussed aliases as in sendmail 8.7 and later).

\subsection {\cfkeyword {remind\_return\_path}}
        \label {kw-remind-return-path}
         
        \default {owner}

        Like \cfkeyword {welcome\_return\_path}, but relates to the remind message.
	Also requires the bounce+* alias to be installed.

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

	
\section {Priority related}

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

The following parameters are needed when using an RDBMS, but are otherwise not
required:

\subsection {\cfkeyword {db\_type}}

	\texttt {Format: db\_type mysql | Pg | Oracle | Sybase}

        Database management system used (e.g. MySQL, Pg, Oracle)
	
	This corresponds to the PERL DataBase Driver (DBD) name and
	is therefore case-sensitive.

\subsection {\cfkeyword {db\_name}} 

	\default {sympa}

        Name of the database containing user information. See
        detailed notes on database structure, \ref{rdbms-struct},
        page~\pageref{rdbms-struct}.

\subsection {\cfkeyword {db\_host}}

        Database host name.

\subsection {\cfkeyword {db\_port}}

        Database port.

\subsection {\cfkeyword {db\_user}}

        User with read access to the database.

\subsection {\cfkeyword {db\_passwd}}

        Password for \cfkeyword {db\_user}.

\subsection {\cfkeyword {db\_options}}

	If these options are defined, they will be appended to the
	database connect string.

Example for MySQL:
\begin {quote}
\begin{verbatim}
db_options	mysql_read_default_file=/home/joe/my.cnf
\end{verbatim}
\end {quote}
   
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
	table), you can make \Sympa load these fields. You will then be able to
	use them from within mail/web templates and authorization scenarios (as [subscriber-\texttt{>}field]).
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
	table), you can make \Sympa load these fields. You will then be able to
	use them from within mail/web templates (as [user-\texttt{>}field]).
[STARTPARSE]

	This parameter is a comma-separated list.

Example :
\begin {quote}
\begin{verbatim}
db_additional_user_fields 	address,gender
\end{verbatim}
\end {quote}


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

States the model version used to create the task which regurlaly checks the certificate
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

Most basic feature of \Sympa will work without a RDBMS, but
WWSympa and bounced require a relational database. 
Currently you can use one of the following
RDBMS : MySQL, PostgreSQL, Oracle, Sybase. Interfacing with other RDBMS
requires only a few changes in the code, since the API used, 
\htmladdnormallinkfoot {DBI} {http://www.symbolstone.org/technology/perl/DBI/} 
(DataBase Interface), has DBD (DataBase Drivers) for many RDBMS.

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

\subsection {Database creation}

The \file {create\_db} script below will create the sympa database for 
you. You can find it in the \dir {script/} directory of the 
distribution (currently scripts are available for MySQL, PostgreSQL, Oracle and Sybase).

\begin{itemize}

  \item MySQL database creation script\\
	\begin {quote}
	\begin{verbatim}
	[INCLUDE '../src/etc/script/create_db.mysql']
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

With \index{MySQL} :
\begin {quote}
\begin{verbatim}
grant all on sympa.* to sympa@localhost identified by 'your_password';
flush privileges;
\end{verbatim}
\end {quote}

\section {Importing subscribers data}

\subsection {Importing data from a text file}

You can import subscribers data into the database from a text file having
one entry per line : the first field is an e-mail address, the second (optional) 
field is the free form name.  Fields are spaces-separated.

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


\section {Extending database table format}

You can easily add other fields to \textbf {subscriber\_table} and
\textbf {user\_table}, they will not disturb \Sympa because it lists
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

\section {HTTPD setup}

\subsection {wwsympa.fcgi access permissions}
 
      
     Because Sympa and WWSympa share a lot of files, \file {wwsympa.fcgi},
     must run with the same 
     uid/gid as \file {archived.pl}, \file {bounced.pl} and \file {sympa.pl}.
     There are different ways to organize this :
\begin{itemize}
\item With some operating systems no special setup is required because
      wwsympa.fcgi is installed with suid and sgid bits, but this will not work
      if suid scripts are refused by your system.

\item Run a dedicated Apache server with sympa.sympa as uid.gid (The Apache default
      is nobody.nobody)

\item Use a Apache virtual host with sympa.sympa as uid.gid ; Apache
      needs to be compiled with suexec. Be aware that the Apache suexec usually define a lowest
      UID/GID allowed to be a target user for suEXEC. For most systems including binaries
      distribution of Apache, the default value 100 is common.
      So Sympa UID (and Sympa GID) must be higher then 100 or suexec must be tuned in order to allow
      lower UID/GID. Check http://httpd.apache.org/docs/suexec.html\#install for details

      The User and Group directive have to be set before the FastCgiServer directive
      is encountered.

\item Otherwise, you can overcome restrictions on the execution of suid scripts
      by using a short C program, owned by sympa and with the suid bit set, to start
      \file {wwsympa.fcgi}. Here is an example (with no guarantee attached) :
\begin {quote}
\begin{verbatim}

#include <unistd.h>

#define WWSYMPA "[WWSBINDIR]/wwsympa.fcgi"
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
     If you chose to run \file {wwsympa.fcgi} as a simple CGI, you simply need to
     script alias it. 

\begin {quote}
\begin{verbatim}
     Example :
       	ScriptAlias /wws [WWSBINDIR]/wwsympa.fcgi
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
	FastCgiServer [WWSBINDIR]/wwsympa.fcgi -processes 2
	<Location /wws>
   	  SetHandler fastcgi-script
	</Location>

	ScriptAlias /wws [WWSBINDIR]/wwsympa.fcgi

 \end{verbatim}
\end {quote}
 
If you run Virtual robots, then the FastCgiServer(s) can serve multiple robots. 
Therefore you need to define it in the common section of your Apache configuration
file.

\subsection {Using FastCGI}

\htmladdnormallink {FastCGI} {http://www.fastcgi.com/} is an extention to CGI that provides persistency for CGI programs. It is extemely useful
with \WWSympa since source code interpretation and all initialisation tasks are performed only once, at server startup ; then
file {wwsympa.fcgi} instances are waiting for clients requests. 

\WWSympa can also work without FastCGI, depending on the \textbf {use\_fast\_cgi} parameter 
(see \ref {use-fastcgi}, page~\pageref {use-fastcgi}).

To run \WWSympa with FastCGI, you need to install :
\begin{itemize}

\item \index {mod\_fastcgi} : the Apache module that provides \index {FastCGI} features

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

	\subsection {password\_case sensitive | insensitive}
	\default {insensitive} \\
	If set to \textbf {insensitive}, WWSympa's password check will be insensitive.
	This only concerns passwords stored in Sympa database, not the ones in \index {LDAP}.
	
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
\end{verbatim}
\end {quote}

     If web\_archive is defined for a list, every message distributed by this list is copied
     to \dir {[SPOOLDIR]/outgoing/}. (No need to create nonexistent subscribers to receive
     copies of messages)

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
currently interfaces with \htmladdnormallink {MySQL}
{http://www.mysql.net/}, \htmladdnormallink {PostgreSQL}
{http://www.postgresql.pyrenet.fr/}, \htmladdnormallink {Oracle}
{http://www.oracle.com/database/} and \htmladdnormallink {Sybase}
{http://www.sybase.com/index_sybase.html}.

A database is needed to store user passwords and preferences.
The database structure is documented in the \Sympa documentation ;
scripts for creating it are also provided with the \Sympa distribution
(in \dir {script}). 

User information (password and preferences) are stored in the «User» table.
User passwords stored in the database are encrypted using reversible
RC4 encryption controlled with the \cfkeyword {cookie} parameter,
since \WWSympa might need to remind users of their passwords. 
The security of \WWSympa rests on the security of your database. 


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
<Location /wws>
   SSLOptions +StdEnvVars
   SetHandler fastcgi-script
</Location>

 \end{verbatim}
\end {quote}


\section {Authentication with email address, uid or alternate email address}
\label {ldap-auth}

\Sympa stores the data relative to the subscribers in a DataBase. Among these data: password, email exploited during the Web authentication. The  module of \index {LDAP authentication} allows to use \Sympa in an intranet without duplicating user passwords. 

This way users can indifferently authenticate with their ldap\_uid, their alternate\_email or their canonic email stored in the \index {LDAP} directory.

\Sympa gets the canonic email in the \index {LDAP} directory with the ldap\_uid or the alternate\_email.  
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
  

\section {Generis SSO authentication}
\label {generic-sso}

The authentication method has first been introduced to allow interraction with \htmladdnormallink {Shibboleth} {http://shibboleth.internet2.edu/}, Internet2's inter-institutional authentication system. But it should be usable with any SSO system that provides an Apache authentication module being able to protect a specified URL on the site (not the whole site). Here is a sample httpd.conf that shib-protects the associated Sympa URL :
\begin {quote}
\begin{verbatim}
...
<Location /wws/sso_login/inqueue>
  AuthType shibboleth
  require affiliation ~ ^member@.+$
</Location>
...
\end{verbatim}
\end {quote}


The SSO is also expected to provide user attributes including the user email address as environment variables. To make the SSO appear in the login menu, a textbf {generic\_sso} paragraph describing the SSO service should be added to  \file {auth.conf}. The format of this paragraph is described in the following section.

Apart from the user email address, the SSO can provide other user attributes that \Sympa will store in the user\_table DB table (for persistancy) and make them available in the [user\_attributes] structure that you can use within authorization scenarios (see~\ref {rules}, page~\pageref {rules}).

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
	host				sso-cas.cru.fr:443
	login_uri			/login
	non_blocking_redirection        on
	check_uri			/validate
	logout_uri			/logout
	auth_service_name		cas-cru
	ldap_host			ldap.cru.fr:389
        ldap_get_email_by_uid_filter          (uid=[uid])
	ldap_timeout			7
	ldap_suffix			dc=cru,dc=fr
	ldap_scope			sub
	ldap_email_attribute		mail

## The URL corresponding to the service_id should be protected by the SSO (Shibboleth in the exampl)
## The URL would look like http://yourhost.yourdomain/wws/sso_login/inqueue in the following example
generic_sso
        service_name       InQueue Federation
        service_id         inqueue
        http_header_prefix HTTP_SHIB
        email_http_header  HTTP_SHIB_EP_AFFILIATION

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
are \cfkeyword {regexp} and \cfkeyword {negative\_regexp} which are perl regexp use to select or block this authentication method for
a class of email. 


\subsection {ldap paragraph}


\begin{itemize}
\item {\cfkeyword {regexp} and \cfkeyword {negative\_regexp}}
	Same as in user\_table paragraph.

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

		 
\item{alternate\_email\_attribute}\\

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

        This defines the version of the SSL/TLS protocol to use. Defaults of \index {Net::LDAPS} to \texttt {sslv2/3}, 
	other possible values are \texttt {sslv2}, \texttt {sslv3}, and \texttt {tlsv1}.

\item{ssl\_ciphers}
  
        Specify which subset of cipher suites are permissible for this connection, using the standard 
	OpenSSL string format. The default value of \index {Net::LDAPS} for ciphers is \texttt {ALL}, 
	which permits all ciphers, even those that don't encrypt!


\end{itemize}


\subsection {generic\_sso paragraph}

 \begin{itemize}

 \item{service\_name} \\
This is the SSO service name that will be proposed to the user in the login banner menu.

\item{service\_id} \\
This service ID is used as a parameter by sympa to refer to the SSO service (instead of the service name). 

A corresponding URL on the local web server should be protected by the SSO system ; this URL would look like textbf {http://yourhost.yourdomain/wws/sso\_login/inqueue} if the service\_id is \textbf {inqueue}.

\item{http\_header\_prefix} \\
Sympa gets user attributes from environment variables comming from the web server. These variables are then stored in the user\_table DB table for later use in authorization scenarios (in [user_attributes] structure). Only environment variables starting with the defined prefix will kept.

\item{email\_http\_header} \\
This parameter defines the environment variable that will contain the authenticated user's email address.

\end{itemize}

\subsection {cas paragraph}


\begin{itemize}

\item{auth\_service\_name}\\
	The friendly user service name as shown by \Sympa in the login page.

\item{host}\\
	The host name of the CAS server including the port number.


\item{non\_blocking\_redirection}\\  

This parameter concern only the first access to Sympa services by a user, it activate or not the non blocking
redirection to the related cas server to check automatically if the user as been previously authenticated with  this CAS server.
Possible values are \textbf {on}  \textbf {off}, default is  \textbf {on}. The redirection to CAS is use with
the cgi parameter \textbf {gateway=1} that specify to CAS server to always redirect the user to the origine
URL but just check if the user is logged. If active, the SSO service is effective and transparent, but in case
the CAS server is out of order the access to Sympa services is impossible.


\item{login\_uri}\\
	The login service URI, usually  \textbf {/cas/login}

\item{check\_uri}\\
	The ticket validation service URI, usually  \textbf {/cas/validate}

\item{logout\_uri}\\
	The logout service URI, usually  \textbf {/cas/logout}

\item{ldap\_host}\\
	The LDAP host Sympa will connect to fetch user email when user uid is return by CAS service. The ldap\_host include the
        port number and it may be a comma separated list of redondant host.   

\item{ldap\_bind\_dn}\\
	The DN used to bind to this server. Anonymous bind is used if this parameter is not defined.
				    
\item{ldap\_bind\_password}\\
	The password used unless anonymous bind is used.

\item{ldap\_suffix}\\
	The LDAP suffix use when seraching user email

\item{ldap\_scope}\\
	The scope use when seraching user email, possible values are \texttt {sub}, \texttt {base}, and \texttt {one}.

\item{ldap\_get\_email\_by\_uid\_filter}\\
	The filter to perform the email search.

\item{ldap\_email\_attribute}\\
	The attribut name to be use as user canonical email. In the current version of sympa only the first value returned by the LDAP server is used.

\item{ldap\_timeout}\\
	The time out for the search.


\item{ldap\_use\_ssl}
   
        If set to \texttt {1}, connection to the LDAP server will use SSL (LDAPS).

\item{ldap\_ssl\_version}

        This defines the version of the SSL/TLS protocol to use. Defaults of \index {Net::LDAPS} to \texttt {sslv2/3}, 
	other possible values are \texttt {sslv2}, \texttt {sslv3}, and \texttt {tlsv1}.

\item{ldap\_ssl\_ciphers}
  
        Specify which subset of cipher suites are permissible for this connection, using the  
	OpenSSL string format. The default value of \index {Net::LDAPS} for ciphers is \texttt {ALL}, 
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
\texttt{<}checksum\texttt{>} are the 8 first bytes of the a MD5 checksum of the \texttt{<}user\_email\texttt{>}+\Sympa \cfkeyword {cookie}
configuration parameter.
Your application needs to know what the \cfkeyword {cookie} parameter
is, so it can check the HTTP cookie validity ; this is a secret shared
between \WWSympa and your application.
\WWSympa's \textit {loginrequest} page can be called to return to the
referer URL when an action is performed. Here is a sample HTML anchor :

\begin{verbatim}
<A HREF="/wws/loginrequest/referer">Login page</A>
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
title.es eliminación reservada sólo para el propietario, necesita autentificación


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
                | is_subscriber (<listname>, <var>)
                | is_owner (<listname>, <var>)
                | is_editor (<listname>, <var>)
                | is_listmaster (<var>)
                | older (<date>, <date>)    # true if first date is anterior to the second date
                | newer (<date>, <date>)    # true if first date is posterior to the second date
<var> ::= [email] | [sender] | [user-><user_key_word>] | [previous_email]
                  | [remote_host] | [remote_addr] | [user_attributes-><user_attributes_keyword>]
	 	  | [subscriber-><subscriber_key_word>] | [list-><list_key_word>] 
		  | [conf-><conf_key_word>] | [msg_header-><smtp_key_word>] | [msg_body] 
	 	  | [msg_part->type] | [msg_part->body] | [msg_encrypted] | [is_bcc] | [current_date] | <string>

[is_bcc] ::= set to 1 if the list is neither in To: nor Cc:

[sender] ::= email address of the current user (used on web or mail interface). Default value is 'nobody'

[previous_email] ::= old email when changing subscribtion email in preference page. 

[msg_encrypted] ::= set to 'smime' if the message was S/MIME encrypted

<date> ::= '<date_element> [ +|- <date_element>]'

<date_element> ::= <epoch_date> | <var> | <date_expr>

<epoch_date> ::= <integer>

<date_expr> ::= <integer>y<integer>m<integer>d<integer>h<integer>min<integer>sec

<listname> ::= [listname] | <listname_string>

<auth_list> ::= <auth>,<auth_list> | <auth>

<auth> ::= smtp|md5|smime

<action> ::=   do_it [,notify]
             | do_it [,quiet]
             | reject(<tpl_name>)
             | request_auth
             | owner
	     | editor
	     | editorkey

<tpl_name> ::= corresponding template (<tpl_name>.tpl) is send to the sender

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
	 	      
\end{verbatim}
\end {quote}

(Refer to  \ref {tasks}, page~\pageref {tasks} for date format definition)

perl\_regexp can contain the string [host] (interpreted at run time as the list or robot domain).
The variable notation [msg\_header-\texttt{>}\texttt{<}smtp\_key\_word\texttt{>}] is interpreted as the 
SMTP header value only when evaluating the authorization scenario for sending messages. 
It can be used, for example, to require editor validation for multipart messages.
[msg\_part-\texttt{>}type] and [msg\_part-\texttt{>}body] are the MIME parts content-types and bodies ; the body is available
for MIME parts in text/xxx format only.


A bunch of authorization scenarios is provided with the \Sympa distribution ; they provide
a large set of configuration that allow to create lists for most usage. But you will
probably create authorization scenarios for your own need. In this case, don't forget to restart \Sympa
and wwsympa because authorization scenarios are not reloaded dynamicaly.

[STARTPARSE]
These standard authorization scenarios are located in the \dir {[ETCBINDIR]/scenari/}
directory. Default scenarios are named \texttt{<}command\texttt{>}.default.

You may also define and name your own authorization scenarios. Store them in the
\dir {[ETCDIR]/scenari} directory. They will not be overwritten by Sympa release.
Scenarios can also be defined for a particular virtual robot (using directory \dir {[ETCDIR]/\texttt{<}robot\texttt{>}/scenari}) or for a list ( \dir {[EXPL_DIR]/\texttt{<}robot\texttt{>}/\texttt{<}list\texttt{>}/scenari} ).
[STOPPARSE]

Example:

Copy the previous scenario to \file {scenari/subscribe.rennes1} :

\begin {quote}
\begin{verbatim}
equal([sender], 'userxxx@univ-rennes1.fr') smtp,smime -> reject
match([sender], /univ-rennes1\.fr\$/) smtp,smime -> do_it
true()                               smtp,smime -> owner
\end{verbatim}
\end {quote}

You may now refer to this authorization scenario in any list configuration file, for example :

\begin {quote}
\begin{verbatim}
subscribe rennes1
\end{verbatim}
\end {quote}

\section {LDAP Named Filters}
\label {named-filters}

At the moment Named Filters are only used in authorization scenarios. They enable to select a category of people who will be authorized or not to realise some actions.
	
As a consequence, you can grant privileges in a list to people belonging to an \index {LDAP} directory thanks to an authorization scenario.
	
\subsection {Definition}

[STARTPARSE]
	People are selected through an \index {LDAP filter} defined in a configuration file. This file must have the extension '.ldap'.It is stored in \dir {[ETCDIR]/search\_filters/}.
	
	You must give several informations in order to create a Named Filter:
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


\subsection {Search Condition}
	
The search condition is used in authorization scenarios which are defined and described in (see~\ref {scenarios}) 

The syntax of this rule is:
\begin {quote}
\begin{verbatim}
	search(example.ldap,[sender])      smtp,smime,md5    -> do_it
\end{verbatim}
\end {quote}

The variables used by 'search' are :
\begin{itemize}
	\item{the name of the LDAP Configuration file}\\
	\item{the [sender]}\\
	That is to say the sender email address. 
\end{itemize}
 
Note that \Sympa processes maintain a cache of processed search conditions to limit access to the LDAP directory ; each entry has a lifetime of 1 hour in the cache.

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


\section {Sample scenario rules}

\begin {quote}
\begin{verbatim}
newer([current_date], '[subscriber->date]+2m')   smtp,md5,smime -> do_it
\end{verbatim}
\end {quote}
Subscription date is less than 2 month old.

\begin {quote}
\begin{verbatim}
older([current_date], '[subscriber->expiration_date]')   smtp,md5,smime -> do_it
\end{verbatim}
\end {quote}
Subscriber's expiration date is over.
The subscriber's expiration date is an additional, site defined, data field ; it needs
to be defined by the listmaster in the database an declared in sympa.conf 
(see~\ref {db-additional-subscriber-fields}, page~\pageref {db-additional-subscriber-fields}).
Note that expiration\_date database field should be an integer (epoch date format) not
a complex date format.
[STARTPARSE]


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Virtual robot how to
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\chapter {Virtual robot}
    \label {virtual-robot}

Sympa is designed to manage multiple distinct mailing list servers on
a single host with a single Sympa installation. Sympa virtual robots
are like Apache virtual hosting. Sympa virtual robot definition includes
a specific email address for the robot itself and its lists and also a virtual
http server. Each robot provides access to a set of lists, each list is
related to only one robot.

Most configuration parameters can be define for each robot except 
general Sympa installation parameters (binary and spool location, smtp engine,
antivirus plugging,...).

The Virtual robot name as defined in \Sympa documentation and configuration file refers
to the Internet domaine of the Virtual robot.

\section {How to create a virtual robot}

You don't need to install several Sympa servers. A single \file {sympa.pl} daemon
and one or more fastcgi servers can serve all virtual robot. Just configure the 
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
\end{verbatim}
\end {quote}

\item Define a \textbf {virtual host in your HTTPD server}. The fastcgi servers defined 
in the common section of you httpd server can be used by each virtual host. You don't 
need to run dedicated fascgi server for each virtual robot.

\textit {Examples:} 
\begin {quote}
\begin{verbatim}
FastCgiServer [WWSBINDIR]/wwsympa.fcgi -processes 3 -idle-timeout 120
.....
<VirtualHost 195.215.92.16>
  ServerAdmin webmaster@your.virtual.domain
  DocumentRoot /var/www/your.virtual.domain
  ServerName your.virtual.domain

  <Location /wws>
     SetHandler fastcgi-script
  </Location>

  ScriptAlias /wws [WWSBINDIR]/wwsympa.fcgi

</VirtualHost>
\end{verbatim}
\end {quote}

\item Create a \file {robot.conf} for the virtual robot (current web interface does
not provide Virtual robot creation yet).

\end {itemize}

\section {robot.conf}
A robot is named by its domain, let's say \samplerobot and defined by a directory 
\dir {[ETCDIR]/\samplerobot}. This directory must contain at least a 
\file {robot.conf} file. This files has the same format as  \file {[CONFIG]}
(have a look at robot.conf in the sample dir).
Only the following parameters can be redefined for a particular robot :

\begin {itemize}

	\item \cfkeyword {http\_host} \\
	This hostname will be compared with 'SERVER\_NAME' environment variable in wwsympa.fcgi
	to determine the current Virtual Robot. You can a path at the end of this parameter if
	you are running multiple Virtual robots on the same host. 
	\begin {quote}
	\begin{verbatim}Examples: \\
	http_host  myhost.mydom
	http_host  myhost.mydom/sympa
	\end{verbatim}
	\end {quote}

	\item \cfkeyword {wwsympa\_url} \\
	The base URL of WWSympa

	\item \cfkeyword {cookie\_domain}

	\item \cfkeyword {email}

	\item \cfkeyword {title}

	\item \cfkeyword {default\_home}
	
	\item \cfkeyword {create\_list}

	\item \cfkeyword {lang}

	\item \cfkeyword {log\_smtp}

	\item \cfkeyword {listmaster}

	\item \cfkeyword {max\_size}

	\item \cfkeyword {dark\_color}, \cfkeyword {light\_color}, \cfkeyword {text\_color}, \cfkeyword {bg\_color}, \cfkeyword {error\_color}, \cfkeyword {selected\_color}, \cfkeyword {shaded\_color} 
\end {itemize}

These settings overwrite the equivalent global parameter defined in \file {[CONFIG]}
for \samplerobot robot ; the main \cfkeyword {listmaster} still has privileges on Virtual
Robots though. The http\_host parameter is compared by wwsympa with the SERVER\_NAME
environment variable to recognize which robot is in used. 

\subsection {Robot customization}

If needed, you can customize each virtual robot using its set of templates and authorization scenarios.

\dir {[ETCDIR]/\samplerobot/wws\_templates/},
\dir {[ETCDIR]/\samplerobot/templates/}, 
\dir {[ETCDIR]/\samplerobot/scenari/} directories are searched when
loading templates or scenari before searching into \dir {[ETCDIR]} and  \dir {[ETCBINDIR]}. This allows to define different privileges and a different GUI for a Virtual Robot.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Customization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\cleardoublepage
\chapter {Customizing \Sympa/\WWSympa}
    \label {customization}

\section {Template file format}
\label{tpl-format}
\index{templates format}

Template files within \Sympa and \WWSympa are text files containing 
programming elements (variables, conditions, loops, file inclusions)
that will be parsed in order to adapt to the runtime context. These 
templates are an extension of programs and therefore give access to 
a limited list of variables (those defined in the '\textit {hash}' 
parameter given to the parser). 

Review the Site template files (\ref {site-tpl}, page~\pageref {site-tpl}) 
and List template files (\ref {list-tpl}, page~\pageref {list-tpl}).

The following describes the syntactical elements of templates.

\subsection {Variables}
[STOPPARSE]

Variables are enclosed between brackets '\textit {[]}'. The variable name
is composed of alphanumerics (0-1a-zA-Z) or underscores (\_).
The syntax for accessing an element in a '\textit{hash}' is [hash-\texttt{>}elt].

\textit {Examples:} 
\begin {quote}
\begin{verbatim}
[url]
[is_owner]
[list->name]
[user->lang]
\end{verbatim}
\end {quote}

For each template you wish to customize, check the available variables in the
documentation.

\subsection {Conditions}

Conditions include variable comparisons (= and \texttt{<}\texttt{>}), or existence.
Syntactical elements for conditions are [IF xxx], [ELSE], [ELSIF xxx] and
[ENDIF].

\textit {Examples:} 
\begin {quote}
\begin{verbatim}
[IF  user->lang=fr]
Bienvenue dans la liste [list->name]
[ELSIF user->lang=es]
Bienvenida en la lista [list->name]
[ELSE]
Welcome in list [list->name]
[ENDIF]

[IF is_owner]
The following commands are available only 
for lists owners or moderators:
....
[ENDIF]
\end{verbatim}
\end {quote}

\subsection {Loops}

Loops make it possible to traverse a list of elements (internally represented by a 
'\textit{hash}' or an '\textit{array}'). 

\texttt{Example :}
\begin {quote}
\begin{verbatim}
A review of public lists

[FOREACH l IN lists]
   [l->NAME] 
   [l->subject]
[END]
\end{verbatim}
\end {quote}

\texttt {[elt-\texttt{>}NAME]} is a special element of the current entry providing 
the key in the '\textit{hash}' (in this example the name of the list). When traversing
an '\textit{array}', \texttt{[elt-\texttt{>}INDEX]} is the index of the current
entry.

\subsection {File inclusions}

You can include another file within a template . The specified file can be 
included as is, or itself parsed (there is no loop detection). The file 
path is either specified in the directive or accessed in a variable.

Inclusion of a text file :

\begin {quote}
\begin{verbatim}
[INCLUDE 'archives/last_message']
[INCLUDE file_path]
\end{verbatim}
\end {quote}

The first example includes a file whose relative path is \file {archives/last\_message}.
The second example includes a file whose path is in file\_path variable.

Inclusion and parsing of a template file :

\begin {quote}
\begin{verbatim}
[PARSE 'welcome.tpl']
[PARSE file_path]
\end{verbatim}
\end {quote}

The first example includes the template file \file {welcome.tpl}.
The second example includes a template file whose path is in file\_path variable.

\subsection {Stop parsing}

You may need to exclude certain lines in a template from the parsing
process. You can perform this by stopping and restarting the
parsing.

Escaping sensitive JavaScript functions :

\begin {quote}
\begin{verbatim}
<HEAD>
<SCRIPT LANGUAGE="JavaScript">
<!-- for other browsers
  function toggle_selection(myfield) {
    for (i = 0; i < myfield.length; i++) {
    [escaped_stop]
       if (myfield[i].checked) {
            myfield[i].checked = false;
       }else {
	    myfield[i].checked = true;
       }
    [escaped_start]
    }
  }
// end browsers -->
</SCRIPT>
</HEAD>
\end{verbatim}
\end {quote}


\subsection {Parsing options}

You can change the parser's behvior by setting unsetting options. Available options are :
\begin {itemize}

  \item \textbf {ignore\_undef} : undefined variables won't be parsed. Default behavior is
    to process undef variables like empty variables.


\begin {quote}
\begin{verbatim}
[SETOPTION ignore_undef]
Here is an unparsed undef variable : [unknown_var]
[UNSETOPTION ignore_undef]
\end{verbatim}
\end {quote}


  \item \textbf {escape\_html} : escape some HTML tag characters while including files

\end {itemize}

\begin {quote}
\begin{verbatim}
[SETOPTION escape_html]
[INCLUDE '/var/www/html/sample.html]
[UNSETOPTION escape_html]
\end{verbatim}
\end {quote}
[STARTPARSE]

\section {Site template files}
\label{site-tpl}
\index{templates, site}

These files are used by Sympa as service messages for the \mailcmd {HELP}, 
\mailcmd {LISTS} and \mailcmd {REMIND *} commands. These files are interpreted 
(parsed) by \Sympa and respect the template format ; every file has a .tpl extension. 
See \ref {tpl-format}, 
page~\pageref {tpl-format}. 

Sympa looks for these files in the following order (where \texttt{<}list\texttt{>} is the
listname if defined, \texttt{<}action\texttt{>} is the name of the command, and \texttt{<}lang\texttt{>} is
the preferred language of the user) :
\begin {enumerate}
	\item \dir {[EXPL_DIR]/\texttt{<}list\texttt{>}/\texttt{<}action\texttt{>}.\texttt{<}lang\texttt{>}.tpl}. 
	\item \dir {[EXPL_DIR]/\texttt{<}list\texttt{>}/\texttt{<}action\texttt{>}.tpl}. 
	\item \dir {[ETCDIR]/templates/\texttt{<}action\texttt{>}.\texttt{<}lang\texttt{>}.tpl}. 
	\item \dir {[ETCDIR]/templates/\texttt{<}action\texttt{>}.tpl}. 
	\item \dir {[ETCBINDIR]/templates/\texttt{<}action\texttt{>}.\texttt{<}lang\texttt{>}.tpl}.
	\item \dir {[ETCBINDIR]/templates/\texttt{<}action\texttt{>}.tpl}.
\end {enumerate}

If the file starts with a From: line, it is considered as
a full message and will be sent (after parsing) without adding SMTP
headers. Otherwise the file is treated as a text/plain message body.

The following variables may be used in these template files :

\begin {itemize}
[STOPPARSE]
	\item[-] [conf-\texttt{>}email] : sympa e-mail address local part

	\item[-] [conf-\texttt{>}domain] : sympa robot domain name

	\item[-] [conf-\texttt{>}sympa] : sympa's complete e-mail address

	\item[-] [conf-\texttt{>}wwsympa\_url] : \WWSympa root URL

	\item[-] [conf-\texttt{>}listmaster] : listmaster e-mail addresses

	\item[-] [user-\texttt{>}email] : user e-mail address

	\item[-] [user-\texttt{>}gecos] : user gecos field (usually his/her name)

	\item[-] [user-\texttt{>}password] : user password

	\item[-] [user-\texttt{>}lang] : user language	
\end {itemize}

\subsection {helpfile.tpl} 


	This file is sent in response to a \mailcmd {HELP} command. 
	You may use additional variables
\begin {itemize}

	\item[-] [is\_owner] : TRUE if the user is list owner

	\item[-] [is\_editor] : TRUE if the user is list editor

\end {itemize}

\subsection {lists.tpl} 

	File returned by \mailcmd {LISTS} command. 
	An additional variable is available :
\begin {itemize}

	\item[-] [lists] : this is a hash table indexed by list names and
			containing lists' subjects. Only lists visible
			to this user (according to the \lparam {visibility} 
			list parameter) are listed.
\end {itemize}

\textit {Example:} 

\begin {quote}
\begin{verbatim}
These are the public lists for [conf->email]@[conf->domain]

[FOREACH l IN lists]
	
 [l->NAME]: [l->subject]

[END]

\end{verbatim}
\end {quote}

\subsection {global\_remind.tpl} 

	This file is sent in response to a \mailcmd {REMIND *} command. 
	(see~\ref {cmd-remind}, page~\pageref {cmd-remind})
	You may use additional variables
\begin {itemize}

	\item[-] [lists] : this is an array containing the list names the user
			is subscribed to.
\end {itemize}

\textit {Example:} 

\begin {quote}
\begin{verbatim}

This is a subscription reminder.

You are subscribed to the following lists :
[FOREACH l IN lists
	
 [l] : [conf->wwsympa\_url]/info/[l]

[END]

Your subscriber e-mail : [user->email]
Your password : [user->password]

\end{verbatim}
\end {quote}

\subsection {your\_infected\_msg.tpl} 

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

Your list web template files should be placed in the \dir {[EXPL_DIR]/\samplelist/wws\_templates} 
directory ; your site web templates in \tildedir {[EXPL_DIR]/wws\_templates} directory.

[STOPPARSE]
There are actually 2 ways a template can include another template :

\begin {enumerate}
  \item directy, as in  subrequest.us.tpl : 
\begin {quote}
\begin{verbatim}
[PARSE '/home/sympa/bin/etc/wws_templates/loginbanner.us.tpl'].
\end{verbatim}
\end {quote}
    If you customize the loginbanner.us.tpl, you also have to customize templates that refer to it.

   \item indirectly, via a variable, as in main.tpl : 
\begin {quote}
\begin{verbatim}
[PARSE action_template]
\end{verbatim}
\end {quote}
\end {enumerate}

 Then  \file {wwsympa.fcgi} sets action\_template variable to the appropriate template file path (ie : in the best place according to Sympa default rules, and in the current language).

We use (2) for some high level templates (action\_template, error\_template, notice\_template, title\_template, menu\_template, list\_menu\_template, admin\_menu\_template) but then we use (1) for lower-level template inclusions.
[STARTPARSE]

Note that web colors are defined in \Sympa's main Makefile (see \ref {makefile},
page~\pageref {makefile}).


\section {Sharing data with other applications}

You may extract subscribers for a list from any of :
\begin{itemize}

\item a text file

\item a Relational database

\item a LDAP directory

\end{itemize}

See lparam {user\_data\_source} liste parameter \ref {user-data-source}, page~\pageref {user-data-source}.

The \textbf {subscriber\_table} and \textbf {user\_table} can have more fields than
the one used by \Sympa. by defining these additional fields, they will be available
from within \Sympa's authorization scenarios and templates (see \ref {db-additional-subscriber-fields}, 
page~\pageref {db-additional-subscriber-fields} and \ref {db-additional-user-fields}, page~\pageref {db-additional-user-fields}).


\section {Sharing \WWSympa authentication with other applications}

See \ref {sharing-auth}, page~\pageref {sharing-auth}.


\section {Internationalization}
\label {internationalization}
\index{internationalization}
\index{localization}

\Sympa was originally designed as a multilingual Mailing List
Manager. Even in its earliest versions, \Sympa separated messages from
the code itself, messages being stored in NLS catalogues (according 
to the XPG4 standard). Later a \lparam{lang} list parameter was introduced.
Nowadays \Sympa is able to keep track of individual users' language preferences.


\subsection {\Sympa internationalization}

Every message sent by \Sympa to users, owners and editors is outside
the code, in a message catalog. These catalogs are located in the
\dir {[NLSDIR]} directory. Messages have currently been
translated into 14 different languages : 

\begin{itemize}

\item cn-big5: BIG5 Chinese (Hong Kong, Taiwan)

\item cn-gb: GB Chinese (Mainland China)

\item cz: Czech

\item de: German

\item es: Spanish

\item fi: Finnish

\item fr: French

\item hu: Hungarian

\item it: Italian

\item pl: Polish

\item us: US English

\end{itemize}

To tell \Sympa to use a particular message catalog, you can either set 
the \cfkeyword{lang} parameter in \file{sympa.conf}, or
set the \file{sympa.pl} \texttt{-l} option on the command line.

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
in multiple categories.

The list of topics is defined in the \file {topics.conf} configuration
file, located in the \dir {[ETCDIR]} directory. The format of this file is 
as follows :
\begin {quote}
\begin{verbatim}
<topic1_name>
title	<topic1 title>
visibility <topic1 visibility>
....
<topicn_name/subtopic_name>
title	<topicn title>
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
    \label {ml-creation}

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
(or \file {[EXPL_DIR]/\samplelist/config} if no virtual robot is defined). 
\Sympa reads it into memory the first time the list is refered to. This file is not rewritten by 
\Sympa, so you may put comment lines in it. 
It is possible to change this file when the program is running. 
Changes are taken into account the next time the list is
accessed. Be careful to provide read access for \Sympa user to this file !

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
not be use anymore except for testing purpose. \Sympa require , will not use this file if the list is configured
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
        for a subscriber is not displayed.  See the \mailcmd
        {SET~LISTNAME~SUMMARY} (\ref {cmd-setsummary}, 
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

\section {List template files}
\label{list-tpl}
\index{templates, list}

These files are used by Sympa as service messages for commands such as
\mailcmd {SUB}, \mailcmd {ADD}, \mailcmd {SIG}, \mailcmd {DEL}, \mailcmd {REJECT}. 
These files are interpreted (parsed) by \Sympa and respect the template 
format ; every file has the .tpl extension. See \ref {tpl-format}, 
page~\pageref {tpl-format}. 

Sympa looks for these files in the following order :
\begin {enumerate}
 	\item \dir {[EXPL_DIR]/\samplelist/\texttt{<}file\texttt{>}.tpl} 
	\item \dir {[ETCDIR]/templates/\texttt{<}file\texttt{>}.tpl}. 
	\item \dir {[ETCBINDIR]/templates/\texttt{<}file\texttt{>}.tpl}.
\end {enumerate}

If the file starts with a From: line, it is taken to be
a full message and will be sent (after parsing) without the addition of SMTP
headers. Otherwise the file is treated as a text/plain message body.

The following variables may be used in list template files :

\begin {itemize}
[STOPPARSE]
	\item[-] [conf-\texttt{>}email] : sympa e-mail address local part

	\item[-] [conf-\texttt{>}domain] : sympa robot domain name

	\item[-] [conf-\texttt{>}sympa] : sympa's complete e-mail address

	\item[-] [conf-\texttt{>}wwsympa\_url] : \WWSympa root URL

	\item[-] [conf-\texttt{>}listmaster] : listmaster e-mail addresses

	\item[-] [list-\texttt{>}name] : list name

	\item[-] [list-\texttt{>}host] : list hostname (default is sympa robot domain name)

	\item[-] [list-\texttt{>}lang] : list language

	\item[-] [list-\texttt{>}subject] : list subject

	\item[-] [list-\texttt{>}owner] : list owners table hash

	\item[-] [user-\texttt{>}email] : user e-mail address

	\item[-] [user-\texttt{>}gecos] : user gecos field (usually his/her name)

	\item[-] [user-\texttt{>}password] : user password

	\item[-] [user-\texttt{>}lang] : user language

	\item[-] [execution\_date] : the date when the scenario is executed	
\end {itemize}

You may also dynamically include a file from a template using the
[INCLUDE] directive.


\textit {Example:} 

\begin {quote}
\begin{verbatim}
Dear [user->email],

Welcome to list [list->name]@[list->host].

Presentation of the list :
[INCLUDE 'info']

The owners of [list->name] are :
[FOREACH ow IN list->owner]
   [ow->gecos] <[ow->email]>
[END]


\end{verbatim}
\end {quote}

\subsection {welcome.tpl} 

\Sympa will send a welcome message for every subscription. The welcome 
message can be customized for each list.

\subsection {bye.tpl} 

Sympa will send a farewell message for each SIGNOFF 
mail command received.

\subsection {removed.tpl} 

This message is sent to users who have been deleted (using the \mailcmd {DELETE} 
command) from the list by the list owner.


\subsection {reject.tpl} 

\Sympa will send a reject message to the senders of messages rejected
by the list editor. If the editor prefixes her \mailcmd {REJECT} with the
keyword QUIET, the reject message will not be sent.


\subsection {invite.tpl} 

This message is sent to users who have been invited (using the \mailcmd {INVITE} 
command) to subscribe to a list. 

You may use additional variables
\begin {itemize}

	\item[-] [requested\_by] : e-mail of the person who sent the 
		\mailcmd{INVITE} command

	\item[-] [url] : the mailto: URL to subscribe to the list

\end {itemize}

\subsection {remind.tpl}

This file contains a message sent to each subscriber
when one of the list owners sends the \mailcmd {REMIND} command
 (see~\ref {cmd-remind}, page~\pageref {cmd-remind}).

\subsection {summary.tpl}

Template for summaries (reception mode close to digest), 
see~\ref {cmd-setsummary}, page~\pageref {cmd-setsummary}.

\subsection {list\_aliases.tpl}
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

\end {itemize}

\section {List model files}
\label {Listmodelfiles}

These files are used by \Sympa to create task files. They are interpreted (parsed) 
by the task manager and respect the task format. See \ref {tasks}, page~\pageref {tasks}.

\subsection {remind.annual.task}

Every year \Sympa will send a message (the template \file {remind.tpl}) 
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
% List configuration parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\cleardoublepage
\chapter {Creating and editing mailing using the web}
    \label {web-ml-creation}

The management of mailing lists by list owners will usually be
done via the web interface. This is based on a strict definition
of privileges which pertain respectively to the
listmaster, to the main list owner, and to basic list owners. The goal is to
allow each listmaster to define who can create lists, and which
parameters may be set by owners. Therefore, a complete
installation requires some careful planning, although default
values should be acceptable for most sites.

Some features are already available, others will be so shortly, as specified
in the documentation.

\section {List creation}


Listmasters have all privileges. Currently the listmaster
is defined in \file {sympa.conf} but in the future, it might be possible to
define one listmaster per virtual robot. By default, newly created
lists must be activated by the listmaster. List creation is possible for all intranet users 
(i.e. : users with an e-mail address within the same domain as Sympa).
This is controlled by the \cfkeyword {create\_list} authorization scenario.

List creation request message and list creation notification message are both
templates that you can customize (\file {create\_list\_request.tpl} and
\file {list\_created.tpl}).

\subsection {Who can create lists}

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

\subsection {typical list profile}

Mailing lists can have many different uses. \Sympa offers a
wide choice of parameters to adapt a list's behavior
to different situations. Users might have difficulty selecting all the
correct parameters, so instead the create list form asks
the list creator simply to choose a profile for the list, and to fill in
the owner's e-mail and the list subject together with a short description.

List profiles can be stored in \dir {[ETCDIR]/create\_list\_templates} or
\dir {[ETCBINDIR]/create\_list\_templates}, which are part of the Sympa
distribution and should not be modified.  
\dir {[ETCDIR]/create\_list\_templates}, which will not be
overwritten by make install, is intended to contain site customizations.


A list profile is an almost complete list configuration, but with a number of missing fields
(such as owner e-mail)
to be replaced by WWSympa at installation time. It is easy to create new list 
templates by modifying existing ones. Contributions to the distribution are welcome.

You might want to hide or modify profiles (not useful, or dangerous 
for your site). If a profile exists both in the local site directory
\dir {[ETCDIR]/create\_list\_templates} and
\dir {[ETCBINDIR]/create\_list\_templates} directory, then the local profile 
will be used by WWSympa. 

Another way to control publicly available profiles is to
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


When a list is created, whatever its status (\cfkeyword {pending} or
\cfkeyword {open}), the owner can use WWSympa admin features to modify list
parameters, or to edit the welcome message, and so on.

WWSympa logs the creation and all modifications to a list as part of the list's
\file {config} file (and old configuration files are saved).


\section {List edition}
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




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% List configuration parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\cleardoublepage
\chapter {List configuration parameters}
    \label {list-configuration-param}


The configuration file is composed of paragraphs separated by blank
lines and introduced by a keyword.

Even though there are a very large number of possible parameters, the minimal list
definition is very short. The only required parameters are  \lparam {owner} and \lparam {subject}.
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
lang cn-big5
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
uses this parameter.

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
	  (\htmladdnormallink {view} {http://listes.cru.fr/sympa/distribution/current/src/etc/scenari/visibility.[s->name]})
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
   \texttt {include}

Sympa allows the mailing list manager to choose how \Sympa loads
subscriber data. Subscriber information can be stored in a text 
file or relational database, or included from various external
sources (list, flat file, result of \index {LDAP} or \index {SQL} query).

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
       by extracting e-mail addresses using an \index {SQL} or \index {LDAP} query, or 
       by including other mailing lists. At least one include 
       paragraph, defining a data source, is needed. Valid include paragraphs (see
       below) are \lparam {include\_file}, \lparam {include\_list}, \lparam {include\_remote\_sympa\_list}, 
	\lparam {include\_sql\_query} and \lparam {include\_ldap\_query}. 
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
\lparam {user\_data\_source} is set to \texttt {include}.
All subscribers of list \texttt {listname} become subscribers 
of the current list. You may include as many lists as required, using one
\lparam {include\_list} \texttt {listname} line for each included
list. Any list at all may be included ; the \lparam {user\_data\_source} definition
of the included list is irrelevant, and you may therefore
include lists which are also defined by the inclusion of other lists. 
Be careful, however, not to include list \texttt {A} in list \texttt {B} and
then list \texttt {B} in list \texttt {A}, since this will give rise an 
infinite loop.

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
\lparam {path} \textit {absolute path} (In most cases, for a list name foo /wws/dump/foo ) 

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
sympa@my.domain and files are located in virtual robot etc dir if virtual robot
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

The database type (mysql, Pg, Oracle, Sybase, CSV ...). This value identifies the PERL
DataBase Driver (DBD) to be used, and is therefore case-sensitive.

\item
\label {host}
\lparam {host} \textit {hostname}

The Database Server \Sympa will try to connect to.

\item
\label {db-name}
\lparam {db\_name} \textit {sympa\_db\_name}

The hostname of the database system.

\item
\label {connect-options}
\lparam {connect\_options} \textit {option1=x;option2=y}

These options are appended to the connect string.
This parameter is optional.

Example :

\begin {quote}
\begin{verbatim}

user_data_source include

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

Sets a list of environment variables to set before database connexion.
This is a ';' separated list of variable assignment.

Example for Oracle:
\begin {quote}
\begin{verbatim}
db_env	ORACLE_TERM=vt100;ORACLE_HOME=/var/hote/oracle/7.3.4
\end{verbatim}
\end {quote}


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


\end{itemize}

Example :

\begin {quote}
\begin{verbatim}

user_data_source include

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

This paragraph defines parameters for a \index {LDAP} query returning a
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

This paragraph defines parameters for a two-level \index {LDAP} query returning a
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
    host ldap.cru.fr
    suffix1 cn=testgroup, dc=cru, dc=fr
    timeout1 10
    filter1 (objectClass=*)
    attrs1 uniqueMember
    select1 all
    scope1 base
    suffix2 dc=cru, dc=fr
    timeout2 10
    filter2 (&(dn=[attrs1]) (c=fr))
    attrs2 mail
    select2 regex
    regex2 ^*@cru.fr$
    scope2 one

\end{verbatim}
\end {quote}
[STARTPARSE]

\subsection {include\_file}
    \label {include-file}

\lparam {include\_file} \texttt {path to file} 

This parameter will be interpreted only if the
\lparam {user\_data\_source} value is set to  \texttt {include}.
The file should contain one e-mail address per line
(lines beginning with a "\#" are ignored).

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
	  (\htmladdnormallink {view} {http://listes.cru.fr/sympa/distribution/current/src/etc/scenari/subscribe.[s->name]})
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
	  (\htmladdnormallink {view} {http://listes.cru.fr/sympa/distribution/current/src/etc/scenari/unsubscribe.[s->name]})
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
	  (\htmladdnormallink {view} {http://listes.cru.fr/sympa/distribution/current/src/etc/scenari/add.[s->name]})
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
	  (\htmladdnormallink {view} {http://listes.cru.fr/sympa/distribution/current/src/etc/scenari/del.[s->name]})
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
	  (\htmladdnormallink {view} {http://listes.cru.fr/sympa/distribution/current/src/etc/scenari/remind.[s->name]})
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
	  (\htmladdnormallink {view} {http://listes.cru.fr/sympa/distribution/current/src/etc/scenari/send.[s->name]})
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
	  (\htmladdnormallink {view} {http://listes.cru.fr/sympa/distribution/current/src/etc/scenari/review.[s->name]})
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
	  (\htmladdnormallink {view} {http://listes.cru.fr/sympa/distribution/current/src/etc/scenari/d_read.[s->name]})
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
	  (\htmladdnormallink {view} {http://listes.cru.fr/sympa/distribution/current/src/etc/scenari/d_edit.[s->name]})
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

This parameter specifies the disk quota for the document repository, in kilobytes.
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

\textbf {WARNING}: if the sending time is too late, \Sympa may not
be able to process it. It is essential that \Sympa could scan the digest
queue at least once between the time laid down for sending the
digest and 12:00~AM (midnight). As a rule of thumb, do not use a digest time
later than 11:00~PM.

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
quota 1000
\end{verbatim}
\end {quote}

\subsubsection {access}

    \scenarized {access\_web\_archive}

Predefined authorization scenarios are :

\begin {itemize}
[FOREACH s IN scenari->access_web_archive]
     \item \lparam {access} \texttt {[s->name]} 
	\begin {htmlonly}
	  (\htmladdnormallink {view} {http://listes.cru.fr/sympa/distribution/current/src/etc/scenari/access_web_archive.[s->name]})
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
        email adresse in public web site. Various method are availible into Sympa
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
	Creates a new subdirectory in a directory that can be edited. 
	The creator is the owner of the directory. The access rights are
	those of the parent directory.
	\item action D\_DESCRIBE\\
	Describes a document that can be edited.
	\item action D\_DELETE\\
	Deletes a document after edit access control. If applied to a folder, it has to be empty.
	\item action D\_UPLOAD\\
	Uploads a file into a directory that can be edited.  
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

\subsection {d\_read.tpl} 
The default page for reading a document. If for a file, displays it (if 
viewable) or downloads it. If for a directory, displays all readable
subdocuments, each of which will feature buttons corresponding
to the different actions this subdocument allows. If the directory is
editable, displays buttons to describe it, upload a file to it
or create a new subdirectory. If access to the document is editable,
displays a button to edit the access to it. 

\subsection {d\_editfile.tpl} 
The page used to edit a file. If for a text file, allows it to be edited on-line.
This page also enables the description of the file to be edited, or another file
to be substituted in its place.

\subsection {d\_control.tpl}
The page to edit the access rights and the owner of a document. 

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

Bounces are received at \samplelist-owner address, which should
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
  

\item
  You can define the limit between each level via the \textbf {List configuration pannel}, 
  in subsection \textbf {Bounce settings}. (see \ref {rate}) The principle consists in
  associating a score interval with a level.

\item 
  You can also define wich action must be applied on each category of user.(see \ref {action})
  Each time an action will be done, a notification email will be send to the person of your choice.
  (see \ref {notification})


%It's possible to add your own actions, by editing the task \cfkeyword {process\_bouncers}
%in the \file {task\_manager.pl}: 
%- First, just add in the Hash \cfkeyword {\%actions} 
%the location of your action subroutine (by default in \file {List.pm}), 
%- Then add the name of your action in the Hash \cfkeyword {\%::pinfo} 
%(file:\file {List.pm}), in the field \cfkeyword {bouncers\_levelX->bounce\_level1\_action->format}

\end{itemize}

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
\file {your\_infected\_msg.tpl} warning to the sender of the mail.
The mail is saved as 'bad' and the working directory is deleted (except if \Sympa is running in debug mode).
  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Using Sympa with LDAP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\cleardoublepage
\chapter {Using \Sympa with LDAP}
\label {ldap}

\index {LDAP} is a client-server protocol for accessing a directory service. Sympa
provide various features based on access to one or more LDAP directories :

\begin{itemize}

	\item{authentication using LDAP directory instead of sympa internal storage of password}\\
	  see ~\ref {auth-conf}, page~\pageref {auth-conf}

	\item{named filters used in authorization scenario condition}\\ 
	  see ~\ref {named-filters}, page~\pageref {named-filters}
	
 	\item{LDAP extraction of list subscribers (see ~\ref {par-user-data-source})}\\         
	
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

is_subscriber([listname],[sender])             smime  -> do_it
is_editor([listname],[sender])                 smime  -> do_it
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

The S/Sympa encryption feature in the distribution process supposes that sympa
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

\subsubsection {Use of Netscape navigator to obtain X509 list certificates}

In many cases e-mail X509 certificates are distributed via a web server and
loaded into the browser using your mouse :) Netscape allows
certificates to be exported to a file. So one way to get a list certificate is to obtain an e-mail
certificate for the canonical list address in your browser, and then to export and install it for Sympa :
\begin {enumerate}
\item browse the net and load a certificate for the list address on some
PKI provider (your own OpenCa pki server , thawte, verisign, ...). Be
careful :  the e-mail certificate must be correspond exactly to the canonical address of
your  list, otherwise, the signature will be incorrect (sender e-mail will
not match signer e-mail).
\item in the security menu, select the intended certificate and export
it. Netscape will prompt you for a password and a filename to encrypt
the output file. The format used by Netscape is  ``pkcs\#12''. 
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
\end {enumerate} 


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
        result is the content of the \file {helpfile.tpl} template
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
	The \texttt {lists.tpl} template defines the message return
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
        message is made by parsing the remind.tpl file.

    \item \mailcmd {REMIND} \textit {*}

        \mailcmd {REMIND} is used by the listmaster to send to each subscriber of any list a single
        message with a summary of his/her subscriptions. In this case the 
        message sent is constructed by parsing the global\_remind.tpl file.
        For each list, \Sympa tests whether the list is configured as hidden 
	to each subscriber (parameter lparam {visibility}). By default the use 
	of this command is restricted to listmasters. 
	Processing may take a lot of time !
	
    \item  \mailcmd {EXPIRE}
        \label {cmd-expire}

        \textit {listname}
        \textit {age (in days)}
        \textit {deadline (in days)}
        (listname) (age (in days)) (deadline (in days))
        \textit {explanatory text to be sent to the subscribers concerned}

        This command activates an \textindex {expiration} process
        for former subscribers of the designated list. Subscribers
        for which no procedures have been enabled for more than
        \textit {age} days receive the explanatory text appended
        to the \mailcmd {EXPIRE} command. This text, which must be
        adapted by the list owner for each subscriber population,
        should explain to the people receiving this message that
        they can update their subscription date so as to not be
        deleted from the subscriber list, within a deadline of
        \textit {deadline} days.

        Past this deadline, the initiator of the \mailcmd {EXPIRE}
        command receives the list of persons who have not confirmed
        their subscription.  It is up to the initiator to send
        \Sympa the corresponding \mailcmd {DELETE} commands.

        Any operation updating the subscription date of an address
        serves as confirmation of subscription. This is also the
        case for \mailcmd {SET} option selecting commands and for
        the \mailcmd {SUBSCRIBE} subscription command itself. The fact
        of sending a message to the list also updates the subscription
        date.

        The explanatory message should contain at least 20 words;
        it is possible to delimit it by the word \mailcmd {QUIT},
        in particular in order not to include a signature, which
        would systematically end the command message.

        A single expiration process can be activated at any given
        time for a given list. The \mailcmd {EXPIRE} command
        systematically gives rise to \textindex {authentication}
        by return mail.  The \mailcmd {EXPIRE} command has \textbf
        {no effect on the subscriber list}.

    \item  \mailcmd {EXPIREINDEX} \textit {listname}
       \label {cmd-expireindex}

       Makes it possible, at any time, for an expiration process
       activated using an \mailcmd {EXPIRE} command to receive the
       list of addresses for which no enabling has been received.

    \item  \mailcmd {EXPIREDEL} \textit {listname}
       \label {cmd-expiredel}

       Deletion of a process activated using the \mailcmd {EXPIRE}
       command.  The \mailcmd {EXPIREDEL} command has no effect on
       subscribers, but it possible to activate a new expiration
       process with new deadlines.

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

See also the
\htmladdnormallinkfoot {recommendations for moderators} {http://listes.cru.fr/admin/moderation.html}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Appendices
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Index
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\cleardoublepage
\printindex

\end {document}

