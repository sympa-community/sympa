# Change Log

## [6.2.22](https://github.com/sympa-community/sympa/tree/6.2.22) (2017-10-01)

[Full Changelog](https://github.com/sympa-community/sympa/compare/6.2.20...6.2.22)

**Fixed bugs:**

- "sympa.pl --change\_user\_email" was broken [\#65](https://github.com/sympa-community/sympa/pull/65) ([ikedas](https://github.com/ikedas))

- upgrade\_send\_spool.pl could leave some messages not upgraded \[[diff](https://github.com/sympa-community/sympa/compare/6.2.20...ce1f94d239062b845524de60a84a711af29d1ec6)\]

## [6.2.20](https://github.com/sympa-community/sympa/tree/6.2.20) (2017-09-22)

[Full Changelog](https://github.com/sympa-community/sympa/compare/6.2.19b.2...6.2.20)

**Changes:**

- [change] Translation guide was moved: https://translate.sympa.org/pages/help \[[067f611](https://github.com/sympa-community/sympa/commit/067f6117b402caca4df7a733d39c1134e288d1f5)\]

**Fixed bugs:**

- Button label confusing on form to send HTML page  [\#54](https://github.com/sympa-community/sympa/issues/54)
- Text change / typo fix in change\_email\_request template [\#52](https://github.com/sympa-community/sympa/issues/52)
- smtpc build warnings [\#50](https://github.com/sympa-community/sympa/issues/50)
- Sympa doesn't log DBI error on connect [\#34](https://github.com/sympa-community/sympa/issues/34)
- Internal server error in WebUI when email has removed from list [\#28](https://github.com/sympa-community/sympa/issues/28)
- Missing Function "action\_change\_email" on serveradmin.tt2 [\#25](https://github.com/sympa-community/sympa/issues/25)
- Bounced crash - missing Encode::HanExtra [\#8](https://github.com/sympa-community/sympa/issues/8)
- FCGI scripts will not always restart when they are updated [\#58](https://github.com/sympa-community/sympa/pull/58) ([ikedas](https://github.com/ikedas))

**Closed issues:**

- MHonArc depedency not detected [\#59](https://github.com/sympa-community/sympa/issues/59)

**Merged pull requests:**

- Issue \#25: move\_user function was broken [\#55](https://github.com/sympa-community/sympa/pull/55) ([ikedas](https://github.com/ikedas))
- Issue \#37: WWSympa/edit\_list: Removing owner may cause crash. [\#38](https://github.com/sympa-community/sympa/pull/38) ([ikedas](https://github.com/ikedas))

## [6.2.19b.2](https://github.com/sympa-community/sympa/tree/6.2.19b.2) (2017-09-10)

[Full Changelog](https://github.com/sympa-community/sympa/compare/6.2.19b.1...6.2.19b.2)

**Implemented enhancements:**

- Additional bug fixes and enhancements for PR \#45 [\#48](https://github.com/sympa-community/sympa/pull/48) ([ikedas](https://github.com/ikedas))
- Activating options in XSS Parser [\#45](https://github.com/sympa-community/sympa/pull/45) ([almarin](https://github.com/almarin))

**Fixed bugs:**

- smtpc build warnings [\#50](https://github.com/sympa-community/sympa/issues/50)
- Additional bug fixes and enhancements for PR \\#45 [\#48](https://github.com/sympa-community/sympa/pull/48) ([ikedas](https://github.com/ikedas))
- \[bug\] Upgrading from Sympa prior to 6.2b.5, digest spool could not be upgraded \[[8c2b5dd](https://github.com/sympa-community/sympa/commit/8c2b5ddd21b87096ef77fab64cbbe4e028a41eb2)\]

**Closed issues:**

- Language change won't affect, 6.2.18 [\#46](https://github.com/sympa-community/sympa/issues/46)
- SMIME digital signatures in HTML formatted emails show tampering [\#16](https://github.com/sympa-community/sympa/issues/16)

**Merged pull requests:**

- Issue \#25: move\_user function was broken [\#55](https://github.com/sympa-community/sympa/pull/55) ([ikedas](https://github.com/ikedas))

## [6.2.19b.1](https://github.com/sympa-community/sympa/tree/6.2.19b.1) (2017-08-21)

[Full Changelog](https://github.com/sympa-community/sympa/compare/6.2.18...6.2.19b.1)

**Changes**

- WWSympa: The "change_email" function deprecated by 6.2 was restored as "move_user".  Check Listmaster Admin Menu (serveradmin) and User preferences (pref) pages.

**Implemented enhancements:**

- Make "http\_host" parameter optional [\#36](https://github.com/sympa-community/sympa/pull/36) ([ikedas](https://github.com/ikedas))
- WWSympa: Improving "add", "del" etc. functions. Adding "import" function [\#30](https://github.com/sympa-community/sympa/pull/30) ([ikedas](https://github.com/ikedas))
- WWSympa: Improving subscribe, signoff and auth functions [\#26](https://github.com/sympa-community/sympa/pull/26) ([ikedas](https://github.com/ikedas))

**Fixed bugs:**

- sympa\_msg: uninitialized value [\#40](https://github.com/sympa-community/sympa/issues/40)
- Sympa 6.2.16 - Unsubscribe Does Not Work [\#29](https://github.com/sympa-community/sympa/issues/29)
- Update smtpc to 0.2: A bug fix and a change [\#42](https://github.com/sympa-community/sympa/pull/42) ([ikedas](https://github.com/ikedas))
- Several errors by "make install" [\#39](https://github.com/sympa-community/sympa/pull/39) ([ikedas](https://github.com/ikedas))
- WWSympa: Improving "add", "del" etc. functions. Adding "import" function [\#30](https://github.com/sympa-community/sympa/pull/30) ([ikedas](https://github.com/ikedas))
- WWSympa: Improving subscribe, signoff and auth functions [\#26](https://github.com/sympa-community/sympa/pull/26) ([ikedas](https://github.com/ikedas))

**Merged pull requests:**

- Issue \#40: Warning on uninitialized value during delivery to the list [\#41](https://github.com/sympa-community/sympa/pull/41) ([ikedas](https://github.com/ikedas))
- Add DBI error string to error message "Can't connect to Database" [\#35](https://github.com/sympa-community/sympa/pull/35) ([racke](https://github.com/racke))
- Issue \#25: Restoring the function to change an email over all lists [\#33](https://github.com/sympa-community/sympa/pull/33) ([ikedas](https://github.com/ikedas))

## [6.2.18](https://github.com/sympa-community/sympa/tree/6.2.18) (2017-06-25)

[Full Changelog](https://github.com/sympa-community/sympa/compare/6.2.17b.1...6.2.18)

**Changes:**

- Moving INSTALL to INSTALL.md and slightly updating content. [[506c435](https://github.com/sympa-community/sympa/commit/506c435)]
- Added euskara (Basque) and galego (Galician) to default of supported languages (supported_lang). [[ff700f7](https://github.com/sympa-community/sympa/commit/ff700f7)]

**Closed issues:**

- Version number for next stable release [\#21](https://github.com/sympa-community/sympa/issues/21)


## [6.2.17b.2](https://github.com/sympa-community/sympa/tree/6.2.17b.2) (2017-06-15)

[Full Changelog](https://github.com/sympa-community/sympa/compare/6.2.17b.1...6.2.17b.2)

**Changes:**

- Renaming Norwegian translation catalogs: Dropping region suffix "\_NO" to be "nb" and "nn". [[999ae07](https://github.com/sympa-community/sympa/commit/999ae07)]
- [change] Translation site and feedback contact have moved. [[c044e96](https://github.com/sympa-community/sympa/commit/c044e96)]

**Fixed bugs:**

- include\_ldap\_query parameter attrs not valid \(6.2.17b1\) [\#22](https://github.com/sympa-community/sympa/issues/22)
- Editing Moderators Requires Restart to Take Effect [\#7](https://github.com/sympa-community/sympa/issues/7)
- Editor should always be translated to Modérateur in fr [\#19](https://github.com/sympa-community/sympa/pull/19) ([jcdelepine](https://github.com/jcdelepine))
- Fixed bugs on Debian Project (see Full Changelog for details):
  - Make the build reproducible (Chris Lamb)
  - Fix log severity in some command line tools used in postinst (Emmanuel Bouthenot)
  - Fix various typos in documentation and manpages (Emmanuel Bouthenot)
  - Remove reference to a template which no longer exists (Emmanuel Bouthenot)

**Merged pull requests:**

- Issue \#22: Parameters for LDAP attribute description are too restrictive [\#23](https://github.com/sympa-community/sympa/pull/23) ([ikedas](https://github.com/ikedas))


## [6.2.17b.1](https://github.com/sympa-community/sympa/tree/6.2.17b.1) (2017-05-29)

[Full Changelog](https://github.com/sympa-community/sympa/compare/3a644d4...6.2.17b.1)

**Implemented enhancements:**

- Improved on-line help on list configuration edit form [\#15](https://github.com/sympa-community/sympa/pull/15) ([ikedas](https://github.com/ikedas))
- \[6.2\] Rewriting code on list configuration form [\#13](https://github.com/sympa-community/sympa/pull/13) ([ikedas](https://github.com/ikedas))
- Features in subversion repository (see Full Changelog for details):
  - \[12965\] Separate executable upgrade_shared_repository.pl.  Ordinarily, it will be invoked automatically during upgrading process.
  - \[12953\] WWSympa: Function to view messages (held messages, bounces and notifications) works, even if javascript is disabled.  As a result, almost all functions of web interface are available again in the environment without javascript.
  - \[12862\] Adding the template to visualize the lists of lists including the current list.

**Changes:**

- Changes in subversion repository (see Full Changelog for details):
  - \[12937\] MICRO-CAL by Amroune Selim has retired.  Instead, jQuery UI Datepicker Widget is introduced.
  - \[12934\] WWSympa: Action URLs no longer may contain e-mail addresses in their path components.  For example:
  `http://host.name/sympa/editsubscriber/list/email%40addr.ess`
  ...is no longer available;
  `http://host.name/sympa/editsubscriber/list?email=email%40addr.ess`
  ...may be used ("%40" is the encoded form of "@").
Because, e-mail addresses can contain slashes ("/") while web servers cannot handle slashes in URL path appropriately: Query parameter would be better to be used.
  - \[12893\] WWSympa: When a name of newly uploaded file in shared document repository is duplicate of exisiting file, uploading will no longer be confirmed.  Instead, a suffix (2), (3), ... will be added to name of the new file.

**Fixed bugs:**

- sympa\_msg.pl crashed with an include\_users\_ldap\_2level [\#12](https://github.com/sympa-community/sympa/issues/12)
- \[6.2\] Rewriting code on list configuration form [\#13](https://github.com/sympa-community/sympa/pull/13) ([ikedas](https://github.com/ikedas))
- \[6.2\] New code for list config semantics [\#9](https://github.com/sympa-community/sympa/pull/9) ([ikedas](https://github.com/ikedas))
- riseup fixes to templates [\#4](https://github.com/sympa-community/sympa/pull/4) ([taggart](https://github.com/taggart))
- Late changes on svn repo [\#2](https://github.com/sympa-community/sympa/pull/2)
  - \[bug\] wwsympa: Virtual robots in serveradmin/vhosts and rename_list_request pages were not shown correctly.
  - \[bug\] If originator address in message contains upper-case letters, "tag this mail for deletion" in archive won't be shown. Fixed by correcting mhonarc-ressouorces.tt2. Rebuilding is needed to correct past archives.
- \[bug\]\[\#11020\] List admins changes not synchronized with admin\_table [\#1](https://github.com/sympa-community/sympa/pull/1) ([salaun-urennes1](https://github.com/salaun-urennes1))
- Fixed bugs in subversion repository (see Full Changelog for details):
  - \[12972\] \[\#11014\] \[Comitted by M. Deranek\] SQLite: While upgrading Sympa by "sympa.pl --upgrade", upgrading proceduce may fail complaining about non-existent indexes.  Fixed by skipping non-existing indexes and tables to be removed.
  - \[12970\] \[\#11024\] \[Reported by S. Hornburg, LinuXia Systems\] An "obsoleted" list parameter header_list is saved in list config as garbage.  Fixed by removing useless default value.
  - \[12969\] \[\#10969\] \[Reported by M. Perini, Università degli Studi di Perugia\]  In "Listing messages to moderate" page, "Distribute" action fails with error "ERROR (distribute) - Missing argument id|idspam", if it is done in the dialog shown by clicking "View" button.  Fixed by not opening new dialog but transiting confirmation page to choose message topics.
  - \[12968\] \[\#10968\] \[Submitted by S. Hornburg\] Visibility settings in topics.conf were ignored.  Fixed by cheking topics_visibility scenario along with subtopics.
  - \[12966\] \[Reported by A. Meaden, Univ of Kent and submitted by F. Lachapelle, Developpement Strategique Sophos Inc.\] The database log does not record any messages that were successfully delivered to mailing lists.  Fixed by adding an appropriate call to db_log().
  - \[12959\] \[Reported by A. Gouaux\] Exclusion table can not be updated when a user is deleted.  Because family_exclusion column is a primary key in exclusion_table but may not have implicit default.  Fixed by assigning an empty value to such field explicitly.
  - \[12956\] \[Submitted by D. Stoye, Humboldt-Universitat zu Berlin\] A typo in sympa.wsdl broke SOAP interface.
  - \[12948\] WWSympa: viewbounce & viewmod: If the list name or the email address contains "+", incorrect web links to attachments are generated.
Fixed by encoding special characters in generated links.
  - \[12929\] \[\#10866\] \[Reported by A. Bernstein, Electric Embers\] At least on FreeBSD, init script cannot detect orphaned PID file: Such PIDs are treated as active.  Fixed by checking existence of process more strictly.
  - \[12927\] \[\#6988\] \[Reported by D. Pritts, Internet2\] Using cookie web_archive_spam_protection, user is not redirected to their originally requested page.  Fixed by preserving path info the user initially specified.
  - \[12911\] nginx with systemd: If SCRIPT_FILENAME CGI environment variable is set, wwsympa service will terminate when wwsympa.fcgi is updated.  Fixed by adding "Restart=always" option to unit file.
  - \[12907\] \[Reported by several listmasters\] WWSympa: Link prefetch feature by some browsers may fetch "Unsubscribe" link off the stage so that the users may unsubscribe themselves unconsciously.  "Subscribe" and "Delete" (file) links are alike.
Fixed by adding a step to demand confirmation: Blocked action is stored in session, user is brought to confirmation page and, if user confirms, the action will be processed.
  - \[12902\] File names generated by some applications on Mac OS X (uploaded files, files in ZIP archive, ...) may not be shown correctly on other platforms: Accentsare shown separately.  Fixed by applying Normalization Form C (NFC) to file names.
  - \[12867\] When reading the shared documents, file names were not converted from the URL form to the local storage form, leading to errors when downloading files containing spaces or special characters.
  - \[12858\] sympa.pl --purge_list didn't purge list in the family: It was marked family_closed.  Fixed by really purging such list.
  - \[12857\] \[\#5976\] \[Reported by I. Vindenes, Universitetet i Oslo\] Users can subscribe to a pending list even if allow_subscribe_if_pending parameter is set to off.
  - \[12855\] WWSympa: Color picker in skinsedit page did not support devices with touch panel.  Fixed by handling appropriate browser events.  Confirmed by recent version of Safari on iOS at least.
  - \[12853\] WWSympa: Color picker in skinsedit page did not work sane.  Fixed by calculating right metrics.  Confirmed by recent version of Mozilla Firefox, Google 
Chrome and Internet Explorer.
  - \[12848\] \[\#10808\] \[Reported by X. Bachelot\] Suppressing some warnings by C compiler at build time.

---
See the files [ONEWS](ONEWS) and [OChangeLog](OChangeLog) about earlier history.
