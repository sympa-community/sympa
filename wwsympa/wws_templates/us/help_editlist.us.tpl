<!-- RCS Identication ; $Revision$ ; $Date$ -->

[FOREACH p IN param]
  <A NAME="[p->NAME]"></a>
  <B>[p->title]</B> ([p->NAME]):
  <DL>
    <DD>
      [IF p->NAME=add]
        Privilege for adding (ADD command) a subscriber to the list
      [ELSIF p->NAME=anonymous_sender]
        To hide the sender's email address before distributing the message.
        It is replaced by the provided email address.
      [ELSIF p->NAME=archive]
        Privilege for reading mail archives and frequency of archiving
      [ELSIF p->NAME=available_user_options]
        The available_user_options parameter starts a paragraph to define available
        options for the subscribers of the list.<BR><BR>
        <UL>
          <LI>reception <i>modelist</i> (Default value: reception mail,notice,digest,summary,nomail)<BR><BR>
              <i>modelist</i> is a list of modes (mail, notice, digest, summary, nomail), separated
              by commas. Only these modes will be allowed for the subscribers of this list.
              If a subscriber has a reception mode not in the list, sympa uses the mode
              specified in the default_user_options paragraph.
          </LI>
        </UL>
      [ELSIF p->NAME=bounce]
        This paragraph defines bounce management parameters:<BR><BR>
        <UL>
          <LI>warn_rate (Default value: bounce_warn_rate robot parameter)<BR><BR>
              The list owner receives a warning whenever a message is distributed and the
              number (percentage) of bounces exceeds this value.<BR><BR>
          </LI>
          <LI>halt_rate (Default value: bounce_halt_rate robot parameter)<BR><BR>
              NOT USED YET. If bounce rate reaches the halt_rate, messages for the list
              will be halted, i.e. they are retained for subsequent moderation. Once the
              number of bounces exceeds this value, messages for the list are no longer
              distributed.<BR><BR>
           </LI>
           <LI>expire_bounce_task (Default value: daily)<BR><BR>
               Name of the task template use to remove old bounces. Usefull to remove bounces
               for a subscriber email if some message are distributed without receiving new
               bounce. In this case, the subscriber email seems to be OK again. Active if
               task_manager.pl is running.
           </LI>
         </UL>

      [ELSIF p->NAME=bouncers_level1]
        The Bouncers_level1 paragraphs defines the automatic behavior of bounce management.<BR>
	Level 1 is the lower level of bouncing users <BR><BR>

        <UL>
          <LI>rate (Default value: 45)<BR><BR>
	      Each bouncing user have a score (from 0 to 100).This parameter defines lower limit foreach
	      category of bouncing users.for example, level 1 begins from 45 to level_2_treshold.<BR><BR>
          </LI>
          <LI> action (Default value: notify_bouncers)<BR><BR>
	       This parameter defines which task is automaticaly applied on level 1
	       bouncers.<BR><BR>
          </LI>
           <LI>Notification  (Default value: owner)<BR><BR>
	       When automatic task is executed on level 1 bouncers, a notification
	       email can be send to listowner or listmaster.<BR><BR>
           </LI>
        </UL>    

      [ELSIF p->NAME=bouncers_level2]
        The Bouncers_levelX paragraphs defines the automatic behavior of bounce management.<BR>
	Level 2 is the highest level of bouncing users <BR><BR>

        <UL>
          <LI>rate (Default value: 80)<BR><BR>
	      Each bouncing user have a score (from 0 to 100).This parameter defines limit between each
	      category of bouncing users.For example, level 2 is for users with a score between 80 
	      and 100.<BR><BR>
          </LI>
          <LI>action (Default value: notify_bouncers)<BR><BR>
	       This parameter defines which task is automaticaly applied on level 2
	       bouncers.<BR><BR>
          </LI>
           <LI>Notification (Default value: owner)<BR><BR>
	       When automatic task is executed on level 2 bouncers, a notification
	       email can be send to listowner or listmaster.<BR><BR>
           </LI>
        </UL>    
      [ELSIF p->NAME=cookie]
        This parameter is a confidential item for generating authentication keys for
        administrative commands (ADD, DELETE, etc.). This parameter should remain
        concealed, even for owners. The cookie is applied to all list owners, and is
        only taken into account when the owner has the auth parameter. 
      [ELSIF p->NAME=custom_header]
        This parameter is optional. The headers specified will be added to the headers
        of messages distributed via the list. As of release 1.2.2 of Sympa, it is possible
        to put several custom header lines in the configuration file at the same time.
      [ELSIF p->NAME=custom_subject]
        This parameter is optional. It specifies a string which is added to the subject
        of distributed messages (intended to help users who do not use automatic tools to
        sort incoming messages). This string will be surrounded by [] characters.
      [ELSIF p->NAME=default_user_options]
        The default_user_options parameter starts a paragraph to define a default profile
        for the subscribers of the list.<BR><BR>
        <UL>
          <LI>reception notice | digest | summary | nomail | mail<BR><BR>Mail reception mode.<BR><BR></LI>
          <LI>visibility conceal | noconceal<BR><BR>Visibility of the subscriber with the REVIEW command.</LI>
        </UL>
      [ELSIF p->NAME=del]
        This parameter specifies who is authorized to use the DEL command.
      [ELSIF p->NAME=digest]
        Definition of digest mode. If this parameter is present, subscribers can select
        the option of receiving messages in multipart/digest MIME format. Messages are then
        grouped together, and compilations of messages are sent to subscribers in accordance
        with the rythm selected with this parameter. 
      [ELSIF p->NAME=editor]
        Editors are responsible for moderating messages. If the mailing list is
        moderated, messages posted to the list will first be passed to the editors, 
        who will decide whether to distribute or reject it. <BR>
        FYI: Defining editors will not make the list moderated ; you will have to
        set the "send" parameter.<BR>
        FYI: If the list is moderated, any editor can distribute or reject a message
        without the knowledge or consent of the other editors. Messages that have not
        been distributed or rejected will remain in the moderation spool until they
        are acted on.
      [ELSIF p->NAME=expire_task]
        This parameter states which model is used to create a remind task. A expire
        task regurlaly checks the inscription or reinscription date of subscribers and
        asks them to renew their subscription. If they don't they are deleted.
      [ELSIF p->NAME=footer_type]
        List owners may decide to add message headers or footers to messages sent via
        the list. This parameter defines the way a footer/header is added to a message.<BR><BR>
        <UL>
          <LI>footer_type mime<BR><BR>
              The default value. Sympa will add the footer/header as a new MIME part.
              If the message is in multipart/alternative format, no action is taken (since this
              would require another level of MIME encapsulation).<BR><BR>
          </LI>
          <LI>footer_type append<BR><BR>
              Sympa will not create new MIME parts, but will try to append the header/footer to the
              body of the message. Predefined message-footers will will be ignored. Headers/footers may be
              appended to text/plain messages only.
          </LI>
        </UL>
      [ELSIF p->NAME=host]
        Domain name of the list, default is the robot domain name set in the related
        robot.conf file or in file /etc/sympa.conf.
      [ELSIF p->NAME=include_file]
        This parameter will be interpreted only if the user_data_source value is set
        to include. The file should contain one e-mail address per line (lines beginning
        with a "#" are ignored). 
      [ELSIF p->NAME=include_ldap_2level_query]
        This paragraph defines parameters for a two-level query returning a list of
        subscribers. Usually the first-level query returns a list of DNs and the
        second-level queries convert the DNs into e-mail addresses. This paragraph is
        used only if user_data_source is set to include. This feature requires the
        Net::LDAP (perlldap) PERL module. 
      [ELSIF p->NAME=include_ldap_query]
        This paragraph defines parameters for a query returning a list of subscribers.
        This paragraph is used only if user_data_source is set to include. This feature
        requires the Net::LDAP (perlldap) PERL module.
      [ELSIF p->NAME=include_list]
        This parameter will be interpreted only if user_data_source is set to include.
        All subscribers of list listname become subscribers of the current list. You
        may include as many lists as required, using one include_list listname line
        for each included list. Any list at all may be included; the user_data_source
        definition of the included list is irrelevant, and you may therefore include
        lists which are also defined by the inclusion of other lists. Be careful, however,
        not to include list A in list B and then list B in list A, since this will give
        rise an infinite loop. 
      [ELSIF p->NAME=include_remote_sympa_list]
        Sympa can contact another Sympa service using https to fetch a remote list in
        order to include each member of a remote list as subscriber. You may include
        as many lists as required, using one include_remote_sympa_list paragraph for
        each included list. Be careful, however, not to give rise an infinite loop
        making cross includes.<BR><BR>
        For this operation, one Sympa site act as a server while the other one act as
        client. On the server side, the only setting needed is to give permition to the
        remote Sympa to review the list. This is controled by the review scenario. 
      [ELSIF p->NAME=include_sql_query]
        This parameter will be interpreted only if the user_data_source value is set to
        include, and is used to begin a paragraph defining the SQL query parameters. 
      [ELSIF p->NAME=lang]
        This parameter defines the language used for the list. It is used to initialize
        a user's language preference; Sympa command reports are extracted from the
        associated message catalog.
      [ELSIF p->NAME=max_size]
        Maximum size of a message in 8-bit bytes.
      [ELSIF p->NAME=owner]
        Owners are managing subscribers of the list. They may review subscribers and
        add or delete email addresses from the mailing list. If you are a privileged
        owner of the list, you can choose other owners for the mailing list. 
        Privileged owners may edit a few more options than other owners. There can
        only be one privileged owner per list; his/her email address may not
        be edited from the web.
      [ELSIF p->NAME=priority]
        The priority with which Sympa will process messages for this list. This level of
        priority is applied while the message is going through the spool.
      [ELSIF p->NAME=remind]
        This parameter specifies who is authorized to use the remind command.
      [ELSIF p->NAME=remind_return_path]
        Same as welcome_return_path, but applied to remind messages.
      [ELSIF p->NAME=remind_task]
        This parameter states which model is used to create a remind task. A remind task
        regurlaly sends to the subscribers a message which reminds them their subscription
        to list.
      [ELSIF p->NAME=reply_to_header]
        The reply_to_header parameter starts a paragraph defining what Sympa will place in
        the Reply-To: SMTP header field of the messages it distributes.<BR><BR>
        <UL>
          <LI>value sender | list | all | other_email (Default value: sender)<BR><BR>
              This parameter indicates whether the Reply-To: field should indicate the sender of
              the message (sender), the list itself (list), both list and sender (all) or an
              arbitrary e-mail address (defined by the other_email parameter).<BR><BR>
              Note: it is inadvisable to change this parameter, and particularly inadvisable to
              set it to list. Experience has shown it to be almost inevitable that users,
              mistakenly believing that they are replying only to the sender, will send private
              messages to a list. This can lead, at the very least, to embarrassment, and
              sometimes to more serious consequences.<BR><BR>
          </LI>
          <LI>other_email an_email_address<BR><BR>
              If value was set to other_email, this parameter defines the e-mail address used.<BR><BR>
          </LI>
          <LI>apply respect | forced (Default value: respect)<BR><BR>
               The default is to respect (preserve) the existing Reply-To: SMTP header field in
               incoming messages. If set to forced, Reply-To: SMTP header field will be overwritten.
          </LI>
        </UL>
      [ELSIF p->NAME=review]
        This parameter specifies who can use read addresses of subscribers. Since subscriber
        addresses can be abused by spammers, it is strongly recommended that you only
        authorize owners or subscribers to access the subscriber list. 
      [ELSIF p->NAME=send]
        This parameter specifies who can send messages to the list. Valid values for this
        parameter are pointers to scenarii.<BR><BR>
        <UL>
          <LI>send closed<BR>closed<BR><BR></LI>
          <LI>send editor<BR>Moderated, old style<BR><BR></LI>
          <LI>send editorkey<BR>Moderated<BR><BR></LI>
          <LI>send editorkeyonly<BR>Moderated, even for moderators<BR><BR></LI>
          <LI>send editorkeyonlyauth<BR>Moderated, with editor confirmation<BR><BR></LI>
          <LI>send intranet<BR>restricted to local domain<BR><BR></LI>
          <LI>send intranetorprivate<BR>restricted to local domain and subscribers<BR><BR></LI>
          <LI>send newsletter<BR>Newsletter, restricted to moderators<BR><BR></LI>
          <LI>send newsletterkeyonly<BR>Newsletter, restricted to moderators after confirmation<BR><BR></LI>
          <LI>send private<BR>restricted to subscribers<BR><BR></LI>
          <LI>send private_smime<BR>restricted to subscribers check smime signature<BR><BR></LI>
          <LI>send privateandeditorkey<BR>Moderated, restricted to subscribers<BR><BR></LI>
          <LI>send privateandnomultipartoreditorkey<BR>Moderated, for non subscribers sending multipart messages<BR><BR></LI>
          <LI>send privatekey<BR>restricted to subscribers with previous md5 authentication<BR><BR></LI>
          <LI>send privatekeyandeditorkeyonly<BR>Moderated, for subscribers and moderators<BR><BR></LI>
          <LI>send privateoreditorkey<BR>Private, moderated for non subscribers<BR><BR></LI>
          <LI>send privateorpublickey<BR>Private, confirmation for non subscribers<BR><BR></LI>
          <LI>send public<BR>public list<BR><BR></LI>
          <LI>send public_nobcc<BR>public list, Bcc rejected (anti-spam)<BR><BR></LI>
          <LI>send publickey<BR>anyone with previous md5 authentication<BR><BR></LI>
          <LI>send publicnoattachment<BR>public list multipart/mixed messages are forwarded to moderator<BR><BR></LI>
          <LI>send publicnomultipart<BR>public list multipart messages are rejected<BR><BR></LI>
        </UL>
      [ELSIF p->NAME=shared_doc]
        This paragraph defines read and edit access to the shared document repository.
      [ELSIF p->NAME=spam_protection]
        There is a need to protection Sympa web site against spambot which collect email address
        in public web site. Various method are availible into Sympa and you can choose it with
        spam_protection and web_archive_spam_protection parameters. Possible value are:<BR><BR>
        <UL>
          <LI>javascript: the adresse is hidden using a javascript. User who enable javascript can see a nice mailto adresses where others have nothing.</LI>
          <LI>at: the @ char is replaced by the string " AT ".</LI>
          <LI>none : no protection against spammer.</LI>
        </UL>
      [ELSIF p->NAME=subject]
        This parameter indicates the subject of the list, which is sent in response to
        the LISTS mail command. The subject is a free form text limited to one line.
      [ELSIF p->NAME=subscribe]
        The subscribe parameter defines the rules for subscribing to the list.
        Predefined scenarii are:<BR><BR>
        <UL>
          <LI>subscribe auth<BR>subscription request confirmed<BR><BR></LI>
          <LI>ubscribe auth_notify<BR>need authentication (notification is sent to owners)<BR><BR></LI>
          <LI>subscribe auth_owner<BR>requires authentication then owner approval<BR><BR></LI>
          <LI>subscribe closed<BR>subscribe is impossible<BR><BR></LI>
          <LI>subscribe intranet<BR>restricted to local domain users<BR><BR></LI>
          <LI>subscribe intranetorowner<BR>local domain users or owner approval<BR><BR></LI>
          <LI>subscribe open<BR>for anyone without authentication<BR><BR></LI>
          <LI>subscribe open_notify<BR>anyone, notification is sent to list owner<BR><BR></LI>
          <LI>subscribe open_quiet<BR>anyone, no welcome message<BR><BR></LI>
          <LI>subscribe owner<BR>owners approval<BR><BR></LI>
          <LI>subscribe smime<BR>requires S/MIME signed<BR><BR></LI>
          <LI>subscribe smimeorowner<BR>requires S/MIME signed or owner approval<BR><BR></LI>
        </UL>
      [ELSIF p->NAME=topics]
        This parameter allows the classification of lists. You may define multiple topics
        as well as hierarchical ones. WWSympa's list of public lists uses this parameter. 
      [ELSIF p->NAME=ttl]
        Sympa caches user data extracted using the include parameter. Their TTL (time-to-live)
        within Sympa can be controlled using this parameter. The default value is 3600
      [ELSIF p->NAME=unsubscribe]
        This parameter specifies the unsubscription method for the list. Use open_notify or
        auth_notify to allow owner notification of each unsubscribe command. Predefined
        scenarii are:<BR><BR>
        <UL>
          <LI>unsubscribe auth<BR>need authentication<BR><BR></LI>
          <LI>unsubscribe auth_notify<BR>authentication requested, notification sent to owner<BR><BR></LI>
          <LI>unsubscribe closed<BR>impossible<BR><BR></LI>
          <LI>unsubscribe open<BR>anyone without authentication<BR><BR></LI>
          <LI>unsubscribe open_notify<BR>without authentication, notification is sent to owners<BR><BR></LI>
          <LI>unsubscribe owner<BR>owner approval<BR><BR></LI>
        </UL>
      [ELSIF p->NAME=user_data_source]
        Sympa allows the mailing list manager to choose how Sympa loads subscriber data.
        Subscriber information can be stored in a text file or relational database, or
        included from various external sources (list, flat file, result of or query).
      [ELSIF p->NAME=visibility]
        This parameter indicates whether the list should feature in the output generated
        in response to a LISTS command or should be shown in the list overview of the
        web-interface.
      [ELSIF p->NAME=web_archive]
        Defines who can access the web archive for the list. Predefined scenarii are:<BR><BR>
        <UL>
          <LI>access closed<BR>closed<BR><BR></LI>
          <LI>access intranet<BR>restricted to local domain users<BR><BR></LI>
          <LI>access listmaster<BR>listmaster<BR><BR></LI>
          <LI>access owner<BR>by owner<BR><BR></LI>
          <LI>access private<BR>subscribers only<BR><BR></LI>
          <LI>access public<BR>public<BR><BR></LI>
        </UL>
      [ELSIF p->NAME=web_archive_spam_protection]
        Idem spam_protection but restricted to web archive. A additional value is available: cookie
        which mean that users must submit a small form in order to receive a cookie before browsing
        archives. This block all robot, even google and co.
      [ELSIF p->NAME=welcome_return_path]
        If set to unique, the welcome message is sent using a unique return path in order to remove
        the subscriber immediately in the case of a bounce.
      [ELSE]
        No Comment
      [ENDIF]
    </DD>
  </DL>
[END]
