# Change Log

## [6.2.60](https://github.com/sympa-community/sympa/tree/6.2.60) (2020-12-XX)

[Full Changelog](https://github.com/sympa-community/sympa/compare/6.2.59b.1...6.2.60)

**Changes (since 6.2.58)**:**

- This release includes a security fix for \[CVE-2020-29668\] (Unauthorised full access via SOAP API due to illegal cookie).  If you are running SOAP/HTTP interface (`sympa_soap_sever.fcgi`), upgrading is strongly recommended. See also [Security Advisory](https://sympa-community.github.io/security/2020-003.html) for details.
- Personalization (also known as “merge feature”) is restricted by default, and the restrictions can be configured.  See [Upgrading notes](https://sympa-community.github.io/manual/upgrade/notes.html#from-version-prior-to-6260) for details.
- Several options at installation and run time to get rid of setuid wrappers were introduced.  See [Upgrading notes](https://sympa-community.github.io/manual/upgrade/notes.html#from-version-prior-to-6260) for details.

**Implemented enhancements:**

**Fixed bugs:**

- Missing language on edit subscriber view [\#1048](https://github.com/sympa-community/sympa/issues/1048)
- \[CVE-2020-29668\] Unauthorised full access via SOAP API due to illegal cookie [\#1041](https://github.com/sympa-community/sympa/issues/1041)
- Personalization \(merge\_feature\) should be limited [\#1037](https://github.com/sympa-community/sympa/issues/1037)
- ldap ssl connexion no error message [\#596](https://github.com/sympa-community/sympa/issues/596)
- Add proper exit code on errors to SOAP client script. [\#1043](https://github.com/sympa-community/sympa/pull/1043) ([racke](https://github.com/racke))
- DKIM signing not working if `dkim_feature` in domain context was not enabled [\#1036](https://github.com/sympa-community/sympa/issues/1036)

## [6.2.59b.2](https://github.com/sympa-community/sympa/tree/6.2.59b.2) (2020-12-07)

[Full Changelog](https://github.com/sympa-community/sympa/compare/6.2.59b.1...6.2.59b.2)

**Changes:**

- Personalization (formerly sometimes called "merge feature") is now restricted by default: It is enabled only when the message is posted via web interface, and is applied only on footer and header (if any).  This behavior may be changed using `personalization` list parameter, however, listmasters are recommended to review whether wide range of conversion as previous versions is required.  See also [\#1037](https://github.com/sympa-community/sympa/issues/1037).
- Now the setuid wrappers may be disabled, if installation process allows. Packagers are encouraged to provide configuration not using setuid wrappers as possible.  See also [\#943](https://github.com/sympa-community/sympa/issues/943) and related issues/PRs.

**Implemented enhancements:**

- Additional fix to \#946 \(\#1015\) [\#1040](https://github.com/sympa-community/sympa/pull/1040) ([ikedas](https://github.com/ikedas))

**Fixed bugs:**

- Unauthorised full access via SOAP API due to illegal cookie [\#1041](https://github.com/sympa-community/sympa/issues/1041)
- Missing language on edit subscriber view [\#1048](https://github.com/sympa-community/sympa/issues/1048)
- Personalization (`merge_feature`) should be limited [\#1037](https://github.com/sympa-community/sympa/issues/1037)
- ldap ssl connexion no error message [\#596](https://github.com/sympa-community/sympa/issues/596)
- Add proper exit code on errors to SOAP client script. [\#1043](https://github.com/sympa-community/sympa/pull/1043) ([racke](https://github.com/racke))

**Merged pull requests:**

- DKIM signing not working if dkim\_feature in domain context was not enabled \(\#1036\) [\#1050](https://github.com/sympa-community/sympa/pull/1050) ([ikedas](https://github.com/ikedas))

## [6.2.59b.1](https://github.com/sympa-community/sympa/tree/6.2.59b.1) (2020-11-25)

[Full Changelog](https://github.com/sympa-community/sympa/compare/6.2.58...6.2.59b.1)

**Implemented enhancements:**

- Show subjects of archived mails before deletion’s confirmation [\#1025](https://github.com/sympa-community/sympa/pull/1025) ([ldidry](https://github.com/ldidry))

**Fixed bugs:**

- Follow up to SA 2020-002 (CVE-2020-10936) [\#943](https://github.com/sympa-community/sympa/issues/943):
    - Use alias wrapper only if it is really needed [\#946](https://github.com/sympa-community/sympa/issues/946)
    - Add option to ./configure which prevents installation of `sympa_newaliases-wrapper` [\#1031](https://github.com/sympa-community/sympa/issues/1031)
- MySQL: Upgrading fails due to stricter SQL mode [\#1028](https://github.com/sympa-community/sympa/issues/1028)
- 🐛 — Fix confirmation for reporting as spam while deleting an archived mail [\#1022](https://github.com/sympa-community/sympa/pull/1022) ([ldidry](https://github.com/ldidry))
- Update a dependency MHonArc [\#1004](https://github.com/sympa-community/sympa/pull/1004) ([ikedas](https://github.com/ikedas))

**Closed issues:**

- Regression in the FCGI wrapper for WWSympa  [\#1020](https://github.com/sympa-community/sympa/issues/1020)

## [6.2.58](https://github.com/sympa-community/sympa/tree/6.2.58) (2020-10-20)

[Full Changelog](https://github.com/sympa-community/sympa/compare/6.2.57b.2...6.2.58)

**Changes** (since 6.2.56) **:**

- No owner defined in a list is no longer treated as `error_config`.  Instead, if no owner defined and something has to be sent to owners:
    - If possible, discard incoming message and send back DSN to original sender;
    - or, notifications to owners will be redirected to listmaster(s).
  See also [\#955](https://github.com/sympa-community/sympa/pull/955).

**Fixed bugs:**

- Upgrade to 6.2.57b.2 fails : dies in `_load_include_admin_user_file()` [\#1016](https://github.com/sympa-community/sympa/issues/1016)
- Oracle: 'ORA-00904: "EMAIL": invalid identifier' [\#1013](https://github.com/sympa-community/sympa/issues/1013)
- WWSympa: `get_inactive_lists` was not listing the current list owners/editors [\#1005](https://github.com/sympa-community/sympa/pull/1005) ([salaun-urennes1](https://github.com/salaun-urennes1))
- Cannot include privileged owner from list even if it has to [\#969](https://github.com/sympa-community/sympa/issues/969) [Additional fix]

**Merged pull requests:**

- sympa_newaliases.pl: Removing ineffective command line options [\#1008](https://github.com/sympa-community/sympa/issues/1008)

**Closed issues:**

- Mail loop for sympa-request address [\#1018](https://github.com/sympa-community/sympa/pull/1018)

## [6.2.57b.2](https://github.com/sympa-community/sympa/tree/6.2.57b.2) (2020-09-23)

[Full Changelog](https://github.com/sympa-community/sympa/compare/6.2.57b.1...6.2.57b.2)

**Implemented enhancements:**

- sympa.pl: Add an option "--rebuildarc=list@domain" to rebuild archives [\#994](https://github.com/sympa-community/sympa/pull/994) ([ldidry](https://github.com/ldidry))

**Fixed bugs:**

- Typo of `default/mail_tt2/helpfile.tt2` [\#990](https://github.com/sympa-community/sympa/issues/990)
- ARC::Signer died because of a malformed "Authentication-Results:" header field [\#988](https://github.com/sympa-community/sympa/issues/988)
- CAS: `logout_path` does not work [\#986](https://github.com/sympa-community/sympa/issues/986)
- Cannot include privileged owner from list even if it has to [\#969](https://github.com/sympa-community/sympa/issues/969)
- Mail loop with sympa-request address because of misconfiguration [\#957](https://github.com/sympa-community/sympa/issues/957)
- Update fr.po [\#979](https://github.com/sympa-community/sympa/pull/979) ([bikepunk](https://github.com/bikepunk))
- Updating Sympa::List's POD [\#1001](https://github.com/sympa-community/sympa/pull/1001) ([racke](https://github.com/racke) & [ikedas](https://github.com/ikedas))

**Closed issues:**

- About the automatic start of Sympa [\#981](https://github.com/sympa-community/sympa/issues/981)

## [6.2.57b.1](https://github.com/sympa-community/sympa/tree/6.2.57b.1) (2020-07-25)

[Full Changelog](https://github.com/sympa-community/sympa/compare/6.2.56...6.2.57b.1)

**Changes:**

- No owner defined in a list is no longer treated as `error_config`.  Instead, if no owner defined and something has to be sent to owners:
    - If possible, discard incoming message and send back DSN to original sender;
    - or, notifications to owners will be redirected to listmaster(s).
  See also [\#955](https://github.com/sympa-community/sympa/pull/955).

**Implemented enhancements:**

- Deprecate implicit `sync_include` in Sympa::List constructor [\#955](https://github.com/sympa-community/sympa/pull/955) ([ikedas](https://github.com/ikedas))

**Fixed bugs:**

- Cannot include privileged owner from list even if it has to [\#969](https://github.com/sympa-community/sympa/issues/969)
- Uunexpected error log "Unable to verify S/MIME signature" [\#963](https://github.com/sympa-community/sympa/issues/963)
- "false" values in XML file prevent list creation [\#953](https://github.com/sympa-community/sympa/issues/953)
- \(Re\)allow lists to only have owners from data sources [\#92](https://github.com/sympa-community/sympa/issues/92)
- Every time users were loaded via `include_sql_query` Sympa would raise warnings [\#941](https://github.com/sympa-community/sympa/pull/941) ([salaun-urennes1](https://github.com/salaun-urennes1))

**Merged pull requests:**

- Refactor internals of config \(1\) [\#924](https://github.com/sympa-community/sympa/pull/924) [\#970](https://github.com/sympa-community/sympa/pull/970) ([ikedas](https://github.com/ikedas))

**Closed issues:**

- Please wait.... infinite spinner [\#279](https://github.com/sympa-community/sympa/issues/279)

## [6.2.56](https://github.com/sympa-community/sympa/tree/6.2.56) (2020-05-24)

[Full Changelog](https://github.com/sympa-community/sympa/compare/6.2.54...6.2.56)

**Changes** (since 6.2.54) **:**

- `http_host` parameter has been deprecated by the new `wwsympa_url_local` parameter [\#916](https://github.com/sympa-community/sympa/pull/916) ([ikedas](https://github.com/ikedas)). If you used `http_host` parameter, you possiblly need removing it (See [note](https://sympa-community.github.io/manual/upgrade/notes.html#from-version-prior-to-6256)).

**Implemented enhancements:**

- configure: New options --disable-setuid_fcgi & --disable-setuid_queue not to install setuid wrappers [\#943](https://github.com/sympa-community/sympa/issues/943)
- Sync\_Include: Add a button to synchronize owners / moderators in Web interface [\#857](https://github.com/sympa-community/sympa/issues/857)
- list index performance update for wwsympa.fcgi `do_lists` subroutine [\#925](https://github.com/sympa-community/sympa/pull/925) ([olivov](https://github.com/olivov)) & ([ikedas](https://github.com/ikedas))
- Improve logging of archive errors due to possible permission problems  [\#908](https://github.com/sympa-community/sympa/pull/908) ([racke](https://github.com/racke))
- Data sources: remote file/remote list: Log description of certificate of the peer [\#897](https://github.com/sympa-community/sympa/pull/897) ([ikedas](https://github.com/ikedas))

**Fixed bugs:**

- [SA 2020-002] Security flaws in setuid wrappers [\#943](https://github.com/sympa-community/sympa/issues/943)
- Sync include from commandline oblivious of errors [\#907](https://github.com/sympa-community/sympa/issues/907)
- `ldap_2level_query` "`select2 all`" is returning only one result [\#893](https://github.com/sympa-community/sympa/issues/893)
- `t/Tools_Text.t` test failing in Sympa 6.2.54 [\#892](https://github.com/sympa-community/sympa/issues/892)
- File names in URLized parts are incorrect [\#889](https://github.com/sympa-community/sympa/issues/889)
- Multiple component `wwsympa_url` with `mod_proxy_fcgi` is broken [\#879](https://github.com/sympa-community/sympa/issues/879). Fixed as the request URI will be split into `SCRIPT_NAME` and `PATH_INFO` by Sympa itself.
- Scenario: Prevent crashing by fatal error in syntax of regexp [\#860](https://github.com/sympa-community/sympa/issues/860)
- Cannot remove owners/editors when their external data source as removed [\#858](https://github.com/sympa-community/sympa/issues/858)
- After login, the last content \(image\), not always the last page, is shown [\#580](https://github.com/sympa-community/sympa/issues/580)
- Typos in `set_index()` of some DatabaseDriver classes. [\#936](https://github.com/sympa-community/sympa/pull/936) ([ikedas](https://github.com/ikedas))
- Two fixes related to list families [\#933](https://github.com/sympa-community/sympa/pull/933) ([salaun-urennes1](https://github.com/salaun-urennes1))
- Fix missing content for listmaster admin template edits in the web interface [\#921](https://github.com/sympa-community/sympa/pull/921) ([racke](https://github.com/racke))
- `spam_protection` list paramter did not derive its default from robot/site config [\#915](https://github.com/sympa-community/sympa/pull/915) ([ikedas](https://github.com/ikedas))
- Fix logging of open file error in constructor of `Sympa::Config_XML`. [\#906](https://github.com/sympa-community/sympa/pull/906) ([racke](https://github.com/racke))
- Some bugs related to urlize mode [\#900](https://github.com/sympa-community/sympa/pull/900) ([ikedas](https://github.com/ikedas))
- URLize: Use filesystem-independent escaping for names of files stored [\#891](https://github.com/sympa-community/sympa/pull/891) ([ikedas](https://github.com/ikedas))
- Update bug tracker url in serveradmin section. [\#884](https://github.com/sympa-community/sympa/pull/884) ([racke](https://github.com/racke))

**Closed issues:**

- The translation server is down \(nginx problem\) [\#855](https://github.com/sympa-community/sympa/issues/855)

## [6.2.54](https://github.com/sympa-community/sympa/tree/6.2.54) (2020-02-24)

[Full Changelog](https://github.com/sympa-community/sympa/compare/6.2.52...6.2.54)

**Changes** (since 6.2.52) **:**

- Format of `family_signoff` link has been changed [\#854](https://github.com/sympa-community/sympa/pull/854).  See [the documentation](https://sympa-community.github.io/manual/customize/basics-families.html#family-unsubscription) for details.

**Implemented enhancements:**

- Prevent welcome emails on import with `--quiet`. [\#851](https://github.com/sympa-community/sympa/pull/851) ([racke](https://github.com/racke))

**Fixed bugs:**

- \[SA 2020-001\] Security flaws in CSRF prevension [\#886](https://github.com/sympa-community/sympa/issues/886)
- Death of the wwsympa process bug [\#876](https://github.com/sympa-community/sympa/issues/876)
- Spurious errors for PGP/MIME multipart/signed messages [\#867](https://github.com/sympa-community/sympa/issues/867)
- WWSympa: review: Unable to sort by "Sources" column in subscriber list [\#866](https://github.com/sympa-community/sympa/issues/866)
- Bugs in scenario processing [\#849](https://github.com/sympa-community/sympa/issues/849) [\#846](https://github.com/sympa-community/sympa/issues/846) [\#845](https://github.com/sympa-community/sympa/issues/845) [\#844](https://github.com/sympa-community/sympa/issues/844) [\#841](https://github.com/sympa-community/sympa/issues/841)
- Data source: File: gecos was ignored [\#873](https://github.com/sympa-community/sympa/pull/873) ([ikedas](https://github.com/ikedas))
- Urlize mode bug fixes [\#840](https://github.com/sympa-community/sympa/pull/840) ([dverdin](https://github.com/dverdin)) [\#871](https://github.com/sympa-community/sympa/pull/871) ([ikedas](https://github.com/ikedas))

**Merged pull requests:**

- Update test suite [\#874](https://github.com/sympa-community/sympa/pull/874) ([ikedas](https://github.com/ikedas))
- Deprecate one-time ticket (work in progress) [\#853](https://github.com/sympa-community/sympa/pull/853) [\#854](https://github.com/sympa-community/sympa/pull/854) ([ikedas](https://github.com/ikedas))
- Deprecate `filesystem_encoding` parameter [\#829](https://github.com/sympa-community/sympa/pull/829) [\#838](https://github.com/sympa-community/sympa/pull/838) ([ikedas](https://github.com/ikedas))

## [6.2.52](https://github.com/sympa-community/sympa/tree/6.2.52) (2019-12-27)

[Full Changelog](https://github.com/sympa-community/sympa/compare/6.2.50...6.2.52)

**Fixed bugs:**

- Scenario : error-performing-condition [\#831](https://github.com/sympa-community/sympa/issues/831)

## [6.2.50](https://github.com/sympa-community/sympa/tree/6.2.50) (2019-12-22)

[Full Changelog](https://github.com/sympa-community/sympa/compare/6.2.49b.3...6.2.50)

**Changes** (since 6.2.48) **:**

- Some scenarios and list creation templates for "intranet" use cases were made optional: They have been moved into `samples/` [\#119](https://github.com/sympa-community/sympa/issues/119).  See also "[upgrading notes](https://sympa-community.github.io/manual/upgrade/notes.html#from-version-prior-to-6250)" for details.

**Merged pull requests:**

- Rearrange .travis.yml [\#828](https://github.com/sympa-community/sympa/pull/828) ([ikedas](https://github.com/ikedas))

## [6.2.49b.3](https://github.com/sympa-community/sympa/tree/6.2.49b.3) (2019-12-15)

[Full Changelog](https://github.com/sympa-community/sympa/compare/6.2.49b.2...6.2.49b.3)

**Fixed bugs:**

- `sympa.conf-dist` comments format is not supported by `Conf::_load_config_file_to_hash()` [\#822](https://github.com/sympa-community/sympa/issues/822)
- `sympa_msg.pl`: Rejection reports are suppressed [\#820](https://github.com/sympa-community/sympa/issues/820)

## [6.2.49b.2](https://github.com/sympa-community/sympa/tree/6.2.49b.2) (2019-12-03)

[Full Changelog](https://github.com/sympa-community/sympa/compare/6.2.49b.1...6.2.49b.2)

**Fixed bugs:**

- Bugs injected by previous release [\#815](https://github.com/sympa-community/sympa/issues/815), [\#813](https://github.com/sympa-community/sympa/issues/813)

**Merged pull requests:**

- Updating dependency Test::Pod [\#811](https://github.com/sympa-community/sympa/pull/811) ([ikedas](https://github.com/ikedas))
- Demote Sympa::List debug messages when invoking constructor and load method [\#810](https://github.com/sympa-community/sympa/pull/810) ([racke](https://github.com/racke))

## [6.2.49b.1](https://github.com/sympa-community/sympa/tree/6.2.49b.1) (2019-11-23)

[Full Changelog](https://github.com/sympa-community/sympa/compare/6.2.48...6.2.49b.1)

**Changes:**

- Some scenarios and list creation templates for "intranet" use cases were made optional: They have been moved into `samples/` [\#119](https://github.com/sympa-community/sympa/issues/119).

**Implemented enhancements:**

- Message distribution: Unexpected number of sessions regarding nrcpt and avg values [\#604](https://github.com/sympa-community/sympa/issues/604)
- Message plugin: Prevent Sympa daemon crash due to a broken plugin module. [\#807](https://github.com/sympa-community/sympa/pull/807) ([racke](https://github.com/racke))
- `sympa.pl`: Add option to notify lists’ owners when opening lists from command line [\#790](https://github.com/sympa-community/sympa/pull/790) ([ldidry](https://github.com/ldidry))
- Scenario: Enhancements on scenarios [\#782](https://github.com/sympa-community/sympa/pull/782) ([ikedas](https://github.com/ikedas))

**Fixed bugs:**

- Missing `dkim` authentication method in several scenario files [\#775](https://github.com/sympa-community/sympa/pull/775), [\#803](https://github.com/sympa-community/sympa/issues/803)
- No "Date:" header field in messages posted directly from the sympa web site [\#791](https://github.com/sympa-community/sympa/issues/791)
- Data source: LDAP / LDAP 2 level datasource not returning results [\#785](https://github.com/sympa-community/sympa/issues/785)
- LDAP auth crash / task\_manager.pl crash due to lack of IPv6 support [\#784](https://github.com/sympa-community/sympa/issues/784)
- DMARC settings seemingly not working as described in documentation [\#783](https://github.com/sympa-community/sympa/issues/783)
- Archive directories of any lists may be created even if archive is unavailable, or Sympa may crash [\#736](https://github.com/sympa-community/sympa/issues/736)
- Prevent warning caused by empty description in XML list definition file. [\#802](https://github.com/sympa-community/sympa/pull/802) ([racke](https://github.com/racke))

**Merged pull requests:**

- Various improvements to --sync-include output [\#787](https://github.com/sympa-community/sympa/pull/787) ([racke](https://github.com/racke))
- Test: Supports recent version of Test::Compile [\#772](https://github.com/sympa-community/sympa/pull/772) ([ikedas](https://github.com/ikedas))
- Refactor family [\#771](https://github.com/sympa-community/sympa/pull/771) ([ikedas](https://github.com/ikedas))
- Update gettext support bundled in the source distribution [\#757](https://github.com/sympa-community/sympa/pull/757) ([ikedas](https://github.com/ikedas))

## [6.2.48](https://github.com/sympa-community/sympa/tree/6.2.48) (2019-09-29)

[Full Changelog](https://github.com/sympa-community/sympa/compare/6.2.45b.3...6.2.48)

**Changes** (since 6.2.44) **:**

- Perl: From now on, Perl earlier than 5.10.1 will never be supported [\#620](https://github.com/sympa-community/sympa/issues/620).
- Data sources: Codebase has entirely been rewritten. Some behavior will be changed [\#693](https://github.com/sympa-community/sympa/issues/693).

**Implemented enhancements:**

- Drop support for Perl 5.8.x [\#620](https://github.com/sympa-community/sympa/issues/620).
- Improving data sources [\#693](https://github.com/sympa-community/sympa/issues/693).
- Rename some modules for spool-like objects [\#608](https://github.com/sympa-community/sympa/issues/608)

**Fixed bugs:**

- Error message "Use of uninitialized value $2" while instancing family lists [\#749](https://github.com/sympa-community/sympa/issues/749)
- Robot verification for `--make_alias_file` command line option [\#746](https://github.com/sympa-community/sympa/issues/746)
- Pending lists not clearly shown as "pending" in the web GUI [\#738](https://github.com/sympa-community/sympa/issues/738)
- WWSympa: viewlogs: selected type of action is not preserved [\#742](https://github.com/sympa-community/sympa/pull/742) ([ikedas](https://github.com/ikedas))
- Fix errors "Can't use an undefined value as an ARRAY reference" while running `sympa.pl --modify_list` [\#741](https://github.com/sympa-community/sympa/pull/741) ([salaun-urennes1](https://github.com/salaun-urennes1))
- Improving data sources [\#693](https://github.com/sympa-community/sympa/issues/693).

**Closed issues:**

- Translation server certificate is expired [\#734](https://github.com/sympa-community/sympa/issues/734)

**Merged pull requests:**

- Remove last traces of VOOT support. [\#747](https://github.com/sympa-community/sympa/pull/747) ([racke](https://github.com/racke))

## [6.2.46](https://github.com/sympa-community/sympa/tree/6.2.46) (2019-09-23)

Withdrawn.

## [6.2.45b.3](https://github.com/sympa-community/sympa/tree/6.2.45b.3) (2019-08-23)

[Full Changelog](https://github.com/sympa-community/sympa/compare/6.2.45b.2...6.2.45b.3)

**Implemented enhancements:**

- Handle pending lists with sympa.pl [\#637](https://github.com/sympa-community/sympa/issues/637)

**Fixed bugs:**

- Request date for renamed lists [\#720](https://github.com/sympa-community/sympa/issues/720)
- `mail_tt2/moderate.tt2` : mailto: links intermittantly line wrapped [\#709](https://github.com/sympa-community/sympa/issues/709)
- Attachment with long filename can break list archives [\#699](https://github.com/sympa-community/sympa/issues/699)
- 6.2.44 Cannot delete a moderator/owner [\#698](https://github.com/sympa-community/sympa/issues/698)
- Text wrapping consumes large amount of memory. [\#722](https://github.com/sympa-community/sympa/pull/722) ([ikedas](https://github.com/ikedas))
- WWSympa: `send_mail`: Restrict MIME content type of uploaded HTML text \(\#716\) [\#721](https://github.com/sympa-community/sympa/pull/721) ([ikedas](https://github.com/ikedas))

**Closed issues:**

- Autodetect MIME type of uploaded message files? [\#716](https://github.com/sympa-community/sympa/issues/716)

**Merged pull requests:**

- pod2md: Some fixes [\#730](https://github.com/sympa-community/sympa/pull/730) ([ikedas](https://github.com/ikedas))
- Trim fonts flavors to TTF/OTF and WOFF only [\#714](https://github.com/sympa-community/sympa/pull/714) ([xavierba](https://github.com/xavierba) & [ikedas](https://github.com/ikedas))
- Rename some modules for spool-like objects \#608 [\#717](https://github.com/sympa-community/sympa/pull/717) ([ikedas](https://github.com/ikedas))

## [6.2.45b.2](https://github.com/sympa-community/sympa/tree/6.2.45b.2) (2019-07-27)
[Full Changelog](https://github.com/sympa-community/sympa/compare/6.2.45b.1...6.2.45b.2)

**Fixed bugs:**

- Fix crash of RC4 encrypted password notice. [\#706](https://github.com/sympa-community/sympa/pull/706) ([racke](https://github.com/racke))

**Merged pull requests:**

- More fix to \#516 [\#710](https://github.com/sympa-community/sympa/pull/710) ([ikedas](https://github.com/ikedas))

## [6.2.45b.1](https://github.com/sympa-community/sympa/tree/6.2.45b.1) (2019-07-20)
[Full Changelog](https://github.com/sympa-community/sympa/compare/6.2.44...6.2.45b.1)

**Changes:**

- Perl: From now on, Perl earlier than 5.10.1 will never be supported [\#620](https://github.com/sympa-community/sympa/issues/620).
- Data sources: Codebase has entirely been rewritten. Some behavior will be changed [\#693](https://github.com/sympa-community/sympa/issues/693).

**Implemented enhancements:**

- Make it clear that a list is being moderated [\#636](https://github.com/sympa-community/sympa/issues/636)
- Add « report as spam » button in archives [\#634](https://github.com/sympa-community/sympa/issues/634)
- Make it clear on web interface that a list is being moderated [\#638](https://github.com/sympa-community/sympa/pull/638) ([ldidry](https://github.com/ldidry))

**Fixed bugs:**

- `stats` page generates entries in Apache error log [\#700](https://github.com/sympa-community/sympa/issues/700)
- `web_tt2/info.tt2` generates some noise in Apache error log [\#688](https://github.com/sympa-community/sympa/issues/688)
- Death of the `task_manager` process [\#681](https://github.com/sympa-community/sympa/issues/681)
- Error in `web_tt2/subindex.tt2` [\#673](https://github.com/sympa-community/sympa/issues/673)
- DMARC protection: "`p`" tag was not applied to subdomains [\#654](https://github.com/sympa-community/sympa/issues/654)
- Missing path after installation [\#274](https://github.com/sympa-community/sympa/issues/274)
- mtime of files like `.last_change.admin` were not updated [\#671](https://github.com/sympa-community/sympa/pull/671) ([ikedas](https://github.com/ikedas))

**Merged pull requests:**

- Drop support for Perl 5.8.x \(\#620\) [\#683](https://github.com/sympa-community/sympa/pull/683) ([ikedas](https://github.com/ikedas))
- Fix tidying of `src/lib/Sympa/List.pm` [\#677](https://github.com/sympa-community/sympa/pull/677) ([ldidry](https://github.com/ldidry))
- Improving data sources [\#516](https://github.com/sympa-community/sympa/pull/516) [\#680](https://github.com/sympa-community/sympa/pull/680) ([ikedas](https://github.com/ikedas))

## [6.2.44](https://github.com/sympa-community/sympa/tree/6.2.44)

[Full Changelog](https://github.com/sympa-community/sympa/compare/6.2.43b.2...6.2.44)

**Changes** (since 6.2.42) **:**

- Indentation of web templates are corrected [\#582](https://github.com/sympa-community/sympa/pull/582), [\#592](https://github.com/sympa-community/sympa/pull/592). Though this change will not affect functionality, administrators might have to apply their customization to the new templates again.
- WWSympa: TLS client authentication: Now it gets rfc822Name in X.509v3 subjectAltName, otherwise emailAddress attribute in subject DN [\#571](https://github.com/sympa-community/sympa/pull/571). Note that earlier efforts getting attribute such as MAIL, Email in subject DN are no longer supported.
- ARC: Now Mail-DKIM 0.55 or better is required for ARC support.
- WWSympa: Admin function to bulk unsubscribe which has been provided by 6.1.x was restored [\#27](https://github.com/sympa-community/sympa/issues/27).

**Fixed bugs:**

- "Use of uninitialized value $salt" on `--import` [\#656](https://github.com/sympa-community/sympa/issues/656)
- Improve handling of missing `sympa/web_tt2` during upgrade [\#652](https://github.com/sympa-community/sympa/issues/652)

**Merged pull requests:**

- Support Test::Compile 2.0.0 [\#664](https://github.com/sympa-community/sympa/pull/664) ([ikedas](https://github.com/ikedas))
- Remove all unneeded files from foundation-icons directory [\#649](https://github.com/sympa-community/sympa/pull/649) ([xavierba](https://github.com/xavierba))

## [6.2.43b.2](https://github.com/sympa-community/sympa/tree/6.2.43b.2)

[Full Changelog](https://github.com/sympa-community/sympa/compare/6.2.43b.1...6.2.43b.2)

**Implemented enhancements:**

- Hide full email addresses in archives [\#621](https://github.com/sympa-community/sympa/issues/621)
- Add a button for full export of subscribers [\#616](https://github.com/sympa-community/sympa/pull/616) ([ldidry](https://github.com/ldidry))
- Prevent unnecessary DB access in `add_list_member` [\#615](https://github.com/sympa-community/sympa/pull/615) ([seblgr](https://github.com/seblgr))
- Regression from 6.1: Missing admin function to bulk unsubscribe [\#27](https://github.com/sympa-community/sympa/issues/27)

**Fixed bugs:**

- Exception when attempting to add myself to list after Shibboleth authentication [\#641](https://github.com/sympa-community/sympa/issues/641)
- Archive not found when list renamed with capital letter [\#624](https://github.com/sympa-community/sympa/issues/624)
- Edit message header/footer template links lost in 6.2.42? [\#622](https://github.com/sympa-community/sympa/issues/622)
- Improving handling of boilerplate configuration  [\#609](https://github.com/sympa-community/sympa/issues/609)
- Extra space at the end of line in topics.conf [\#581](https://github.com/sympa-community/sympa/issues/581)
- Spurious MHonArc Search warnings for undefined search parameters [\#613](https://github.com/sympa-community/sympa/issues/613)
- Regression from 6.1: Missing admin function to bulk unsubscribe [\#27](https://github.com/sympa-community/sympa/issues/27)

## [6.2.43b.1](https://github.com/sympa-community/sympa/tree/6.2.43b.1)

[Full Changelog](https://github.com/sympa-community/sympa/compare/6.2.42...6.2.43b.1)

**Changes:**

- Indentation of web templates are corrected [\#582](https://github.com/sympa-community/sympa/pull/582), [\#592](https://github.com/sympa-community/sympa/pull/592). Though this change will not affect functionality, administrators might have to apply their customization to the new templates again.
- WWSympa: TLS client authentication: Now it gets rfc822Name in X.509v3 subjectAltName, otherwise emailAddress attribute in subject DN [\#571](https://github.com/sympa-community/sympa/pull/571). Note that earlier efforts getting attribute such as MAIL, Email in subject DN are no longer supported.
- ARC: Now Mail-DKIM 0.55 or better is required for ARC support.

**Implemented enhancements:**

- Indentation of web templates are corrected [\#582](https://github.com/sympa-community/sympa/pull/582) ([ldidry](https://github.com/ldidry)), [\#592](https://github.com/sympa-community/sympa/pull/592) ([ikedas](https://github.com/ikedas))
- Successive config files inconsistency [\#31](https://github.com/sympa-community/sympa/issues/31)
- Add sympa.conf-dist [\#595](https://github.com/sympa-community/sympa/pull/595) ([ldidry](https://github.com/ldidry))
- WWSympa: TLS client authentication: Get email from certificate according to S/MIME [\#571](https://github.com/sympa-community/sympa/pull/571) ([ikedas](https://github.com/ikedas))

**Fixed bugs:**

- Upgrading from 6.2.40 to 6.2.42 may break `sympa.conf`/`robot.conf` [\#578](https://github.com/sympa-community/sympa/issues/578)
- No log entry when message is rejected via email [\#548](https://github.com/sympa-community/sympa/issues/548)
- `Sympa::Aliases::Template` creates exclusive lock on local storage [\#593](https://github.com/sympa-community/sympa/pull/593), [\#602](https://github.com/sympa-community/sympa/pull/602) ([ikedas](https://github.com/ikedas))
- `Sympa::Scenario::new()` was unable to load scenario filename including dots [\#589](https://github.com/sympa-community/sympa/pull/589) ([salaun-urennes1](https://github.com/salaun-urennes1))
- `dkim_sign`: Normalize CRLF-\>LF for `DKIM-Signature` [\#588](https://github.com/sympa-community/sympa/pull/588) ([zmousm](https://github.com/zmousm))
- Slight change in list admins cache expiry. [\#583](https://github.com/sympa-community/sympa/pull/583) ([dverdin](https://github.com/dverdin))
- ARC: Comment in `Authentication-Results` field prevents check on srvid \(See \#575\) [\#585](https://github.com/sympa-community/sympa/pull/585) ([ikedas](https://github.com/ikedas))

**Closed issues:**

- `failed_to_create_web_session` [\#612](https://github.com/sympa-community/sympa/issues/612)

## [6.2.42](https://github.com/sympa-community/sympa/tree/6.2.42) (2019-03-20)

[Full Changelog](https://github.com/sympa-community/sympa/compare/6.2.41b.2...6.2.42)

**Changes** (since 6.2.40) **:**

- Built-in authantication: RC4 reversible encryption of password storage in database was dropped [\#87](https://github.com/sympa-community/sympa/issues/87). To rehash encrypted passwords, see "[Upgrading notes](https://sympa-community.github.io/manual/upgrade/notes.html#upgrading-from-sympa-62x-or-earlier)"
- Format of session cookie was changed [\#87](https://github.com/sympa-community/sympa/issues/87). Session cookies generated with earlier releases will be invalidated.
- Authorization schearios: The "default" scenario files named `*.default` (regular file or symbolic link) are no longer available [\#528](https://github.com/sympa-community/sympa/pull/528) [\#540](https://github.com/sympa-community/sympa/pull/540).  See also "[Upgrading notes](https://sympa-community.github.io/manual/upgrade/notes.html#upgrading-from-sympa-62x-or-earlier)".
- Files for message footer and header were renamed to `message_footer` and `message_header` [\#507](https://github.com/sympa-community/sympa/issues/507).
- WWSympa: LDAP authentication will no longer perform search operation twice [\#453](https://github.com/sympa-community/sympa/issues/453). Now it retrieves entry for the user by a search operation at once, then checks if account is available by a bind operation.
- WWSympa: Feature of `sympa_altemails` cookie was removed [\#487](https://github.com/sympa-community/sympa/issues/487). `alternative_email_attribute` parameter in `auth.conf` was deprecated.
- Primary `auth.conf`, `crawlers_detection.conf` and `trusted_applications.conf` will be used by non-primary domains by default [\#432](https://github.com/sympa-community/sympa/issues/432). Previously primary ones were omitted.

**Implemented enhancements:**

- Refactoring on mail templates [\#567](https://github.com/sympa-community/sympa/pull/567) ([ikedas](https://github.com/ikedas))

**Fixed bugs:**

- SSO session refresh won't reset WWSympa's session [\#560](https://github.com/sympa-community/sympa/issues/560)

## [6.2.41b.2](https://github.com/sympa-community/sympa/tree/6.2.41b.2) (2019-03-09)

[Full Changelog](https://github.com/sympa-community/sympa/compare/6.2.41b.1...6.2.41b.2)

**Changes:**

- Built-in authantication: RC4 reversible encryption of password storage in database was dropped [\#87](https://github.com/sympa-community/sympa/issues/87).
- Format of session cookie was changed [\#87](https://github.com/sympa-community/sympa/issues/87). Session cookies generated with earlier releases will be invalidated.

**Implemented enhancements:**

- Password encryption: Dropping Crypt::CipherSaber [\#87](https://github.com/sympa-community/sympa/issues/87)
- WWSympa: Features of archives and shared repository should be able to be disabled [\#555](https://github.com/sympa-community/sympa/pull/555) ([ikedas](https://github.com/ikedas))

**Fixed bugs:**

- S/MIME: 'setPublicKey' dies on broken cert, causes spindle to resend mails indefinitely [\#565](https://github.com/sympa-community/sympa/issues/565)
- import.tt2: non-working line break in tooltip [\#562](https://github.com/sympa-community/sympa/issues/562)
- Upgrade: Exclusion robot could not be guessed for user [\#546](https://github.com/sympa-community/sympa/issues/546)
- Scenario: Confusion between parameter name and function name [\#520](https://github.com/sympa-community/sympa/issues/520)
- Password has to be reset after logging out [\#167](https://github.com/sympa-community/sympa/issues/167)
- `sympa_test_ldap.pl` misses bind password [\#558](https://github.com/sympa-community/sympa/pull/558) ([ikedas](https://github.com/ikedas))
- `bounce_email_prefix` parameter was not considered to prevent reserved addrresses for list name \(PR\#455\) [\#552](https://github.com/sympa-community/sympa/pull/552) ([ikedas](https://github.com/ikedas))

**Merged pull requests:**

- Additional removal of code to kill VOOT support. [\#553](https://github.com/sympa-community/sympa/pull/553) ([ikedas](https://github.com/ikedas))
- Kill VOOT support [\#550](https://github.com/sympa-community/sympa/pull/550) ([xavierba](https://github.com/xavierba))
- Prepare minimal `sympa.conf` at install time \(cf. \#508\) [\#547](https://github.com/sympa-community/sympa/pull/547) ([ikedas](https://github.com/ikedas))
- Maintenance support scripts \(2\) [\#544](https://github.com/sympa-community/sympa/pull/544) ([ikedas](https://github.com/ikedas))

## [6.2.41b.1](https://github.com/sympa-community/sympa/tree/6.2.41b.1) (2019-02-02)

[Full Changelog](https://github.com/sympa-community/sympa/compare/6.2.40...6.2.41b.1)

**Changes:**

- Authorization schearios: The "default" scenario files named `*.default` (regular file or symbolic link) are no longer available [\#528](https://github.com/sympa-community/sympa/pull/528) [\#540](https://github.com/sympa-community/sympa/pull/540).  See also "[Upgrading notes](https://sympa-community.github.io/manual/upgrade/notes.html#upgrading-from-sympa-62x-or-earlier)".
- Files for message footer and header were renamed to `message_footer` and `message_header` [\#507](https://github.com/sympa-community/sympa/issues/507).
- WWSympa: LDAP authentication will no longer perform search operation twice [\#453](https://github.com/sympa-community/sympa/issues/453). Now it retrieves entry for the user by a search operation at once, then checks if account is available by a bind operation.
- WWSympa: Feature of `sympa_altemails` cookie was removed [\#487](https://github.com/sympa-community/sympa/issues/487). `alternative_email_attribute` parameter in `auth.conf` was deprecated.
- Primary `auth.conf`, `crawlers_detection.conf` and `trusted_applications.conf` will be used by non-primary domains by default [\#432](https://github.com/sympa-community/sympa/issues/432). Previously primary ones were omitted.

**Implemented enhancements:**

- Feature request: a "delete my account" button [\#300](https://github.com/sympa-community/sympa/issues/300)
- Add a global 'quiet_subscription' setting which enforce the "quiet add" policy [\#503](https://github.com/sympa-community/sympa/issues/503)
- WWSympa: Deprecate 'sympa_altemails' cookie [\#487](https://github.com/sympa-community/sympa/issues/487)
- LDAP authentication no longer requires the second search operation with user DN [\#453](https://github.com/sympa-community/sympa/issues/453)
- Feature request: domains blacklist [\#295](https://github.com/sympa-community/sympa/issues/295) [\#537](https://github.com/sympa-community/sympa/pull/537) ([ldidry](https://github.com/ldidry))
- Weaken sympa and wwsympa/sympa soap link [\#525](https://github.com/sympa-community/sympa/pull/525) ([xavierba](https://github.com/xavierba))

**Fixed bugs:**

- Inconsistent location of messge footer/header files [\#507](https://github.com/sympa-community/sympa/issues/507)
- Issue with the message sent to owners to allow unsubscribing [\#469](https://github.com/sympa-community/sympa/issues/469)
- deleting subscribers with empty user selection [\#408](https://github.com/sympa-community/sympa/issues/408)
- WWSympa: Owners/moderators in list panel aren't updated [\#543](https://github.com/sympa-community/sympa/pull/543) ([ikedas](https://github.com/ikedas))
- Owner page is empty [\#541](https://github.com/sympa-community/sympa/pull/541) ([ikedas](https://github.com/ikedas))
- Mail command unavailable in confirmation requests [\#534](https://github.com/sympa-community/sympa/pull/534) ([ikedas](https://github.com/ikedas))
- Invalid default scenarios [\#528](https://github.com/sympa-community/sympa/pull/528) [\#540](https://github.com/sympa-community/sympa/pull/540) ([ikedas](https://github.com/ikedas))
- WWSympa: Deprecate `sympa_altemails` cookie [\#487](https://github.com/sympa-community/sympa/issues/487)
- Primary `auth.conf` won't be used by robots [\#432](https://github.com/sympa-community/sympa/issues/432)
- `sympa.pl --upgrade_config_location` doesn't respect configured user/group [\#519](https://github.com/sympa-community/sympa/pull/519) ([ikedas](https://github.com/ikedas))
- A scalar parameter in list config without value is warned [\#515](https://github.com/sympa-community/sympa/pull/515) ([ikedas](https://github.com/ikedas))
- `make distcheck` fails [\#510](https://github.com/sympa-community/sympa/pull/510) ([ikedas](https://github.com/ikedas))

**Closed issues:**

- parameter owner in sympa config file not considered by sympa 6.2.38 [\#530](https://github.com/sympa-community/sympa/issues/530)
- Domain blacklist [\#523](https://github.com/sympa-community/sympa/issues/523)

**Merged pull requests:**

- Maintenance support scripts [\#539](https://github.com/sympa-community/sympa/pull/539) ([ikedas](https://github.com/ikedas))

## [6.2.40](https://github.com/sympa-community/sympa/tree/6.2.40) (2019-01-19)

[Full Changelog](https://github.com/sympa-community/sympa/compare/6.2.38...6.2.40)

**Fixed bugs:**

- Public archives not available with sympa-6.2.38 [\#527](https://github.com/sympa-community/sympa/issues/527)

## [6.2.38](https://github.com/sympa-community/sympa/tree/6.2.38) (2018-12-21)

[Full Changelog](https://github.com/sympa-community/sympa/compare/6.2.37b.3...6.2.38)

**Changes** (since 6.2.36)**:**

- Tasks: Task files will be put in `tasks` subdirectory. Previously they were put in `global_task_models` or `list_task_models` subdirectory [\#394](https://github.com/sympa-community/sympa/pull/394). Older task files will be automatically copied to new places during upgrading process.
- Oracle Database: There is a change on usage of `db_host` parameter [\#431](https://github.com/sympa-community/sympa/pull/431). See "[Upgrading notes](https://sympa-community.github.io/manual/upgrade/notes.html#from-versions-prior-to-6238)" and [instruction](https://sympa-community.github.io/manual/install/setup-database-oracle.html#general-instruction) for details.
- WWSympa: Login form was refactored [\#424](https://github.com/sympa-community/sympa/pull/424). Some templates including `web_tt2/login.tt2` and `web_tt2/login_menu.tt2` were changed.
- Now the lists with bounce addresses can not be created [\#455](https://github.com/sympa-community/sympa/pull/455). Addresses with local part "`bounce`" or prefix "`bounce+`" are used for bounce management and should not be used as list addresses.

**Implemented enhancements:**

- Feature request: add a "global" mail signature [\#301](https://github.com/sympa-community/sympa/issues/301)
- Adding ARC support [\#153](https://github.com/sympa-community/sympa/issues/153)

**Fixed bugs:**

- Long email addresses in system messages might be folded [\#502](https://github.com/sympa-community/sympa/issues/502)
- Moderation process on the lists with obsoleted parameter `host` fails [\#277](https://github.com/sympa-community/sympa/issues/277)
- File extension may contain spaces by using `gettext_strftime()` [\#506](https://github.com/sympa-community/sympa/pull/506) ([ikedas](https://github.com/ikedas))
- WWSympa: Loading home page takes long time [\#504](https://github.com/sympa-community/sympa/pull/504) ([ikedas](https://github.com/ikedas))
- WWSympa: Older CSS files would be cleared [\#498](https://github.com/sympa-community/sympa/pull/498) ([ikedas](https://github.com/ikedas))

**Closed issues:**

- Bug in logic. Password is in md5 format, not rehashing [\#489](https://github.com/sympa-community/sympa/issues/489)

**Merged pull requests:**

- Allow to use Gitlab CI [\#495](https://github.com/sympa-community/sympa/pull/495) ([ldidry](https://github.com/ldidry))

## [6.2.37b.3](https://github.com/sympa-community/sympa/tree/6.2.37b.3) (2018-12-08)

[Full Changelog](https://github.com/sympa-community/sympa/compare/6.2.37b.2...6.2.37b.3)

**Implemented enhancements:**

- Add token to prevent CSRF [\#492](https://github.com/sympa-community/sympa/pull/492) ([racke](https://github.com/racke)) [\#493](https://github.com/sympa-community/sympa/pull/493) ([ikedas](https://github.com/ikedas))
- Added a `--copy_list` parameter in the sympa.pl command [\#470](https://github.com/sympa-community/sympa/issues/470)
- Feature: add a "report abuse" button on lists info page [\#323](https://github.com/sympa-community/sympa/issues/323)

**Fixed bugs:**

- Crash in `create_list_request` when list name is missing [\#490](https://github.com/sympa-community/sympa/issues/490)
- member dn fetched from first `ldap_2level` request are not exactly the same of the second ldap request [\#474](https://github.com/sympa-community/sympa/issues/474)
- Template parsing problems in parameterizable data sources [\#461](https://github.com/sympa-community/sympa/issues/461)
- Owners et editors dont get imported from config files while upgrading to 6.2.36 [\#459](https://github.com/sympa-community/sympa/issues/459)
- Family updates don't propagates owners/editors changes in the database [\#309](https://github.com/sympa-community/sympa/issues/309)
- Prevent warning on undefined salt variable. [\#488](https://github.com/sympa-community/sympa/pull/488) ([racke](https://github.com/racke))
- Fix shared docs zip upload to send multiple files at once [\#482](https://github.com/sympa-community/sympa/pull/482) ([ldidry](https://github.com/ldidry))
- Broken `custom_attribute` field in `member.dump` [\#480](https://github.com/sympa-community/sympa/pull/480) ([ikedas](https://github.com/ikedas))
- Fix missing quotes in init script [\#479](https://github.com/sympa-community/sympa/pull/479) ([rseichter](https://github.com/rseichter))
- WWSympa: Suppress verbose log on cookie [\#464](https://github.com/sympa-community/sympa/pull/464) ([ikedas](https://github.com/ikedas))

**Merged pull requests:**

- Fix code tidying [\#486](https://github.com/sympa-community/sympa/pull/486) ([ldidry](https://github.com/ldidry))
- Add files produced by patch to Git exclusion list. [\#485](https://github.com/sympa-community/sympa/pull/485) ([racke](https://github.com/racke))

## [6.2.37b.2](https://github.com/sympa-community/sympa/tree/6.2.37b.2) (2018-11-03)

[Full Changelog](https://github.com/sympa-community/sympa/compare/6.2.37b.1...6.2.37b.2)

**Changes:**

- Tasks: Task files will be put in `tasks` subdirectory. Previously they were put in `global_task_models` or `list_task_models` subdirectory [\#394](https://github.com/sympa-community/sympa/pull/394). Older task files will be automatically copied to new places during upgrading process.
- Oracle Database: There is a change on usage of `db_host` parameter [\#431](https://github.com/sympa-community/sympa/pull/431). See "[Upgrading notes](https://sympa-community.github.io/manual/upgrade/notes.html#from-versions-prior-to-6238)" for details.
- WWSympa: Login form was refactored [\#424](https://github.com/sympa-community/sympa/pull/424). Some templates including `web_tt2/login.tt2` and `web_tt2/login_menu.tt2` were changed.

**Implemented enhancements:**

- Optimization of web GUI / adding an index on prev\_id\_session DB field [\#451](https://github.com/sympa-community/sympa/issues/451)
- Exim's bounce text changed - need to update ProcessBounce.pm [\#448](https://github.com/sympa-community/sympa/issues/448)
- Make third person singular pronouns gender neutral [\#443](https://github.com/sympa-community/sympa/pull/443) ([ecawthon](https://github.com/ecawthon))
-  Use tidyall to ease tidying files [\#440](https://github.com/sympa-community/sympa/pull/440) ([ldidry](https://github.com/ldidry))
- Add support for TLSv1.3 [\#439](https://github.com/sympa-community/sympa/pull/439) ([ikedas](https://github.com/ikedas))
- Oracle: Make `db_name` parameter allow net service name or connection identifier along with SID [\#431](https://github.com/sympa-community/sympa/pull/431) ([ikedas](https://github.com/ikedas))
- Refactoring `task_manager.pl` [\#394](https://github.com/sympa-community/sympa/pull/394) ([ikedas](https://github.com/ikedas))

**Fixed bugs:**

- Sympa 6.2.36: Crash of web interface when editing list moderators [\#456](https://github.com/sympa-community/sympa/issues/456)
- Database: `family_exclusion` field can break `not_null` constraint during upgrade [\#442](https://github.com/sympa-community/sympa/issues/442)
- pod2man: unable to format `list_config.pod` [\#435](https://github.com/sympa-community/sympa/issues/435)
- Base class package "Class::Singleton" is empty [\#434](https://github.com/sympa-community/sympa/issues/434)
- The lists with "bounce" addresses should not be created [\#455](https://github.com/sympa-community/sympa/pull/455) ([ikedas](https://github.com/ikedas))
- Moving/copying a list, existing list may be overwritten [\#454](https://github.com/sympa-community/sympa/pull/454) ([ikedas](https://github.com/ikedas))
- Add support for TLSv1.3 [\#439](https://github.com/sympa-community/sympa/pull/439) ([ikedas](https://github.com/ikedas))
- CSS cannot be updated if css.tt2 was older than previously generated CSS. [\#427](https://github.com/sympa-community/sympa/pull/427) ([ikedas](https://github.com/ikedas))
- Refactoring and repairing login form [\#424](https://github.com/sympa-community/sympa/pull/424) ([ikedas](https://github.com/ikedas))

**Closed issues:**

- The translation server is completely unreliable [\#449](https://github.com/sympa-community/sympa/issues/449)
- Change of case in original strings in the translation site does not result in warnings for translated languages [\#374](https://github.com/sympa-community/sympa/issues/374)

**Merged pull requests:**

- Candidate fix for issue \#459 [\#463](https://github.com/sympa-community/sympa/pull/463) ([ikedas](https://github.com/ikedas))

## [6.2.37b.1](https://github.com/sympa-community/sympa/tree/6.2.37b.1) (2018-10-06)

[Full Changelog](https://github.com/sympa-community/sympa/compare/6.2.36...6.2.37b.1)

**Implemented enhancements:**

- Adding ARC support [\#153](https://github.com/sympa-community/sympa/issues/153) --- Under beta testing

**Fixed bugs:**

- Error escaping apostrophe on stats page [\#428](https://github.com/sympa-community/sympa/issues/428)
- Create `${expldir}/${robot}` directory if it does not exists [\#421](https://github.com/sympa-community/sympa/pull/421) ([k0lter](https://github.com/k0lter))

**Closed issues:**

- DMARC and Reply-to munging [\#224](https://github.com/sympa-community/sympa/issues/224)

**Merged pull requests:**

- Refactoring help pages [\#375](https://github.com/sympa-community/sympa/pull/375) ([ikedas](https://github.com/ikedas))

## [6.2.36](https://github.com/sympa-community/sympa/tree/6.2.36) (2018-09-23)

[Full Changelog](https://github.com/sympa-community/sympa/compare/6.2.35b.1...6.2.36)

**Changes** (since 6.2.34)**:**

- Scenarios: `subscribe.*` and `unsubscribe.*` were modified. Now authentication by target user is required when an anonymous/other user requested these actions [\#390](https://github.com/sympa-community/sympa/pull/390). Previously, if "open" scenario was used, an anonymous user on web interface could add subscriber without confirmation.
- WWSympa: Home-made color picker in CSS configuration page was replaced with external plugin [jQuery MiniColors](https://labs.abeautifulsite.net/jquery-minicolors/) [\#369](https://github.com/sympa-community/sympa/pull/369).
- WWSympa: `referer` and `failure_referer` parameters fed to login form (see [documentation](https://sympa-community.github.io/manual/customize/authentication-web.html#sharing-wwsympas-authentication-with-other-applications) for details) are limited within scope of `cookie_domain` parameter value to prevent XSS / open redirect [\#268](https://github.com/sympa-community/sympa/issues/268).
- WWSympa: HTMLArea is no longer supported [\#416](https://github.com/sympa-community/sympa/pull/416).
- Configure script: Default value of `--with-lockdir` option became `/var/lock/subsys` not according to `localstatedir` [\#403](https://github.com/sympa-community/sympa/pull/403).
- Systemd support: Some unit files generated by source package were renamed: `wwsympa.service` and `sympasoap.service` [\#406](https://github.com/sympa-community/sympa/pull/406).
- Database: Sybase (Adaptive Server Enterprise) is no longer supported [\#147](https://github.com/sympa-community/sympa/issues/147). It is reported that none uses it.

**Implemented enhancements:**

- Update startup scripts [\#406](https://github.com/sympa-community/sympa/pull/406) ([ikedas](https://github.com/ikedas))
- Domain without available `wwsympa_url` parameter should deny web access [\#405](https://github.com/sympa-community/sympa/pull/405) ([ikedas](https://github.com/ikedas))
- Let the default of `--with-lockdir` be `/var/lock/subsys` always [\#403](https://github.com/sympa-community/sympa/pull/403) ([ikedas](https://github.com/ikedas))

**Fixed bugs:**

- DKIM per-list options not saved [\#412](https://github.com/sympa-community/sympa/issues/412)
- Merge\_feature active and attached file with special characters [\#409](https://github.com/sympa-community/sympa/issues/409)
- Error in the name of a function in wwsympa.fcgi [\#404](https://github.com/sympa-community/sympa/issues/404)
- Internal Server Error: Can't locate object method "\_marshal\_format" in Spool.pm \(71\) [\#401](https://github.com/sympa-community/sympa/issues/401)
- Rename a list takes incredible time [\#368](https://github.com/sympa-community/sympa/issues/368)
- Avoid "subscribe spam" [\#302](https://github.com/sympa-community/sympa/issues/302)
- XSS and open redirect on login form, CVE-2018-1000671 [\#268](https://github.com/sympa-community/sympa/issues/268)
- Update startup scripts [\#406](https://github.com/sympa-community/sympa/pull/406) ([ikedas](https://github.com/ikedas))

**Closed issues:**

- create_db.Sybase still useful ? [\#147](https://github.com/sympa-community/sympa/issues/147)
- Issues with sending mails using special French characters [\#178](https://github.com/sympa-community/sympa/issues/178)

**Merged pull requests:**

- Drop support for htmlArea [\#416](https://github.com/sympa-community/sympa/pull/416) ([ikedas](https://github.com/ikedas))

## [6.2.35b.1](https://github.com/sympa-community/sympa/tree/6.2.35b.1) (2018-08-26)

[Full Changelog](https://github.com/sympa-community/sympa/compare/6.2.34...6.2.35b.1)

**Changes:**

- Scenarios `subscribe.*` and `unsubscribe.*`: Now authentication by target user is required when anonymous/other user requested these actions [\#390](https://github.com/sympa-community/sympa/pull/390). Previously, if "open" scenario was used, an anonymous user on web interface could add subscriber without confirmation.
- WWSympa: Home-made color picker in CSS configuration page was replaced with external plugin [jQuery MiniColors](https://labs.abeautifulsite.net/jquery-minicolors/) [\#369](https://github.com/sympa-community/sympa/pull/369).

**Implemented enhancements:**

- Accept multiple attributes in `include_ldap_ca.attrs` [\#400](https://github.com/sympa-community/sympa/pull/400) ([almarin](https://github.com/almarin))
- Notify user that they already subscribed to a list [\#386](https://github.com/sympa-community/sympa/issues/386)
- Don't show Autocrypt headers in web archive [\#316](https://github.com/sympa-community/sympa/issues/316)
- `--open_list` command line option [\#62](https://github.com/sympa-community/sympa/issues/62)
- Improve performance of purge operation [\#377](https://github.com/sympa-community/sympa/pull/377) ([cgx](https://github.com/cgx))
- Introducing external js color picker plugin [\#369](https://github.com/sympa-community/sympa/pull/369) ([ikedas](https://github.com/ikedas))

**Fixed bugs:**

- Accept multiple attributes in `include_ldap_ca.attrs` [\#400](https://github.com/sympa-community/sympa/pull/400) ([almarin](https://github.com/almarin))
- sympa.pl `--change_user_email` no longer working with 6.2.34 [\#389](https://github.com/sympa-community/sympa/issues/389)
- Lost owners on list copy [\#384](https://github.com/sympa-community/sympa/issues/384)
- Sympa sysv init script not LSB compiliant [\#376](https://github.com/sympa-community/sympa/issues/376)
- Error on closing a list that was already closed from command line  [\#372](https://github.com/sympa-community/sympa/issues/372)
- Unable to close a list via SOAP client [\#339](https://github.com/sympa-community/sympa/issues/339)
- Prevent the use of the list address as owner or moderator [\#297](https://github.com/sympa-community/sympa/issues/297)
- 6.2.34 `owner_domain` fixes  [\#393](https://github.com/sympa-community/sympa/pull/393) ([mpkut](https://github.com/mpkut))
- List.pm: ensure uniqueness when adding to source id list [\#392](https://github.com/sympa-community/sympa/pull/392) ([mpkut](https://github.com/mpkut))
- WWSympa: Rendering bug with IE [\#380](https://github.com/sympa-community/sympa/pull/380) ([ikedas](https://github.com/ikedas))
- Styles for help contents are broken. [\#379](https://github.com/sympa-community/sympa/pull/379) ([ikedas](https://github.com/ikedas))
- Fix SQL query to fetch all lists of a family [\#367](https://github.com/sympa-community/sympa/pull/367) ([cgx](https://github.com/cgx))
- Fix `do_search_list` sub to trim leading/trailig whitespace [\#387](https://github.com/sympa-community/sympa/pull/387) ([olivov](https://github.com/olivov))

**Closed issues:**

- `sympa.js` bundles part of MochiKit [\#334](https://github.com/sympa-community/sympa/issues/334)
- Unable to import a large file of e-mails to a maillist using wwsympa [\#177](https://github.com/sympa-community/sympa/issues/177)

**Merged pull requests:**

- Avoid rehashing user password hashes in {add,update}_global_user() [\#398](https://github.com/sympa-community/sympa/pull/398) ([mpkut](https://github.com/mpkut))
- Add copyright notice to sympa.js \#320 [\#396](https://github.com/sympa-community/sympa/pull/396) ([xavierba](https://github.com/xavierba))
- Rename a list takes incredible time \#368 [\#388](https://github.com/sympa-community/sympa/pull/388) ([ikedas](https://github.com/ikedas))

## [6.2.34](https://github.com/sympa-community/sympa/tree/6.2.34) (2018-07-05)

[Full Changelog](https://github.com/sympa-community/sympa/compare/6.2.33b.2...6.2.34)

**Changes:**

- `cpanfile` to manage depencency modules was introduced [\#355](https://github.com/sympa-community/sympa/issues/355). `ModDef.pm` was deprecated.
- Directory organization under `static_content` directory was changed [\#220](https://github.com/sympa-community/sympa/issues/220).
- WWSympa: UI framework was switched to Foundation Sites 6 [\#170](https://github.com/sympa-community/sympa/issues/170). Appearances of web interface were slightly changed, and several web templates were changed much.
- WWSympa: `wwsympa_url` parameter became optional [\#330](https://github.com/sympa-community/sympa/pull/330). Conversely, if this parameter was not specified in `robot.conf`, web interface will be disabled for that domain. Existing configuration will be automatically fixed during upgrading process.
- `sympa.conf.bin` and `robot.conf.bin` will no longer be created/updated [\#284](https://github.com/sympa-community/sympa/pull/284). They were not used anyway. `config.bin` for list config will still be available.
- List parameter `host` was deprecated [\#43](https://github.com/sympa-community/sympa/issues/43). If you were using it, you should check alias files: See "[Upgrading notes](https://sympa-community.github.io/manual/upgrade/notes.html)" for details.
- Owners and moderators are no longer stored in list config file: They are stored only in database [\#49](https://github.com/sympa-community/sympa/issues/49).
    - New pages to configure them were added to web interface [\#275](https://github.com/sympa-community/sympa/pull/275).
    - New functions `--dump_users` and `--restore_users` to dump and restore users in database were added to `sympa.pl` command line utility [\#232](https://github.com/sympa-community/sympa/issues/232) [\#267](https://github.com/sympa-community/sympa/pull/267).
    - List creation templates will not need modification. However, if you were creating lists not using those templates, i.e. creating list directories and necessary files manually, you may also have to create dump files (See "[Dump files](https://sympa-community.github.io/manual/customize/basics-list-config.html#dump-files)" for details).

**Implemented enhancements:**

- Introducing cpanfile [\#355](https://github.com/sympa-community/sympa/issues/355)
- Use rsa-sha256 for DKIM signatures [\#357](https://github.com/sympa-community/sympa/pull/357) ([FabianHenneke](https://github.com/FabianHenneke))

**Fixed bugs:**

- Use rsa-sha256 for DKIM signatures [\#357](https://github.com/sympa-community/sympa/pull/357) ([FabianHenneke](https://github.com/FabianHenneke))

**Merged pull requests:**

- Refactor config pages \(not a bug\) [\#354](https://github.com/sympa-community/sympa/pull/354) ([ikedas](https://github.com/ikedas))
- Tidy up all files [\#353](https://github.com/sympa-community/sympa/pull/353) ([ldidry](https://github.com/ldidry))
- Remove tabs in default tt2 templates + some indentation changes [\#352](https://github.com/sympa-community/sympa/pull/352) ([ldidry](https://github.com/ldidry))
- SympaSOAP: closeList crashes. [\#349](https://github.com/sympa-community/sympa/pull/349) ([ikedas](https://github.com/ikedas))

## [6.2.33b.2](https://github.com/sympa-community/sympa/tree/6.2.33b.2) (2018-06-21)

[Full Changelog](https://github.com/sympa-community/sympa/compare/6.2.33b.1...6.2.33b.2)

**Changes:**

- WWSympa: UI framework was switched to Foundation Sites 6 [\#170](https://github.com/sympa-community/sympa/issues/170). Appearances of web interface were slightly changed, and several web templates were changed much.
- `sympa.conf.bin` and `robot.conf.bin` will no longer be created/updated [\#284](https://github.com/sympa-community/sympa/pull/284) ([ikedas](https://github.com/ikedas)). They were not used anyway. `config.bin` for list config will still be available.

**Implemented enhancements:**

- Update help: GDPR [\#276](https://github.com/sympa-community/sympa/issues/276)
- static\_content directory structure [\#220](https://github.com/sympa-community/sympa/issues/220)
- WWSympa: Switch to Foundation 6 [\#170](https://github.com/sympa-community/sympa/issues/170)
- WWSympa: wwsympa\_url would be optional [\#330](https://github.com/sympa-community/sympa/pull/330) ([ikedas](https://github.com/ikedas))

**Fixed bugs:**

- ERROR \(search\) - Missing argument filter [\#341](https://github.com/sympa-community/sympa/issues/341)
- Family updates don't propagates owners/editors changes in the database [\#309](https://github.com/sympa-community/sympa/issues/309)
- PostgreSQL: Issues related to utf8 flag [\#305](https://github.com/sympa-community/sympa/issues/305)
- Both send.confidential and send.private scenari files use the same gettext text [\#175](https://github.com/sympa-community/sympa/issues/175)
- fix misspellings [\#338](https://github.com/sympa-community/sympa/pull/338) ([taggart](https://github.com/taggart))
- Support for spam reporting in bulk. Moved the bulk moderation controls. [\#332](https://github.com/sympa-community/sympa/pull/332) ([sivertkh](https://github.com/sivertkh))
- Remove superfluous sort from dup\_var function. [\#324](https://github.com/sympa-community/sympa/pull/324) ([racke](https://github.com/racke))
- Binary cache files for sympa.conf/rebot.conf are useless [\#284](https://github.com/sympa-community/sympa/pull/284) ([ikedas](https://github.com/ikedas))

**Closed issues:**

- Request: notify translators when new strings are available [\#333](https://github.com/sympa-community/sympa/issues/333)
- HTML signature with Unicode characters generates 'rejected\_authorization' error [\#181](https://github.com/sympa-community/sympa/issues/181)

**Merged pull requests:**

- Starting a test framework [\#336](https://github.com/sympa-community/sympa/pull/336) ([dverdin](https://github.com/dverdin))
- Deprecate ModDef.pm [\#326](https://github.com/sympa-community/sympa/pull/326) ([ikedas](https://github.com/ikedas))
- Add Perltidy test in xt \(related to \#319\) [\#322](https://github.com/sympa-community/sympa/pull/322) ([ldidry](https://github.com/ldidry))

## [6.2.33b.1](https://github.com/sympa-community/sympa/tree/6.2.33b.1) (2018-05-03)

[Full Changelog](https://github.com/sympa-community/sympa/compare/6.2.32...6.2.33b.1)

**Changes:**

- List parameter "host" was deprecated [\#43](https://github.com/sympa-community/sympa/issues/43).
- Owners and moderators are no longer stored in list config file: They are stored only in database [\#49](https://github.com/sympa-community/sympa/issues/49).  New pages to configure them are added to web interface [\#275](https://github.com/sympa-community/sympa/pull/275) ([ikedas](https://github.com/ikedas)).

**Implemented enhancements:**

- Add support for the subscribers.db.dump format in sympa.pl [\#232](https://github.com/sympa-community/sympa/issues/232)

**Fixed bugs:**

- Error message is missing one parameter [\#263](https://github.com/sympa-community/sympa/issues/263)
- Erroneous typing in templates [\#266](https://github.com/sympa-community/sympa/issues/266)
- cookie parameter protection [\#243](https://github.com/sympa-community/sympa/issues/243)
- Spurious error on duplicate keys with admin sync [\#11](https://github.com/sympa-community/sympa/issues/11)

**Merged pull requests:**

- \#170: Least fixup [\#187](https://github.com/sympa-community/sympa/pull/187) ([ikedas](https://github.com/ikedas))

## [6.2.32](https://github.com/sympa-community/sympa/tree/6.2.32) (2018-04-19)

[Full Changelog](https://github.com/sympa-community/sympa/compare/6.2.30...6.2.32)

**Implemented enhancements:**

- Updates for bcrypt support [\#238](https://github.com/sympa-community/sympa/pull/238) ([mpkut](https://github.com/mpkut))
- Duplicate precedence header tripping up Amazon SES [\#110](https://github.com/sympa-community/sympa/issues/110)

**Fixed bugs:**

- [2018-001](https://sympa-community.github.io/security/2018-001.html) Security breaches in template editing \[[c791843](https://github.com/sympa-community/sympa/commit/c7918437ef4b8ea04c7b92cc356601fc43beb901)\]
- sympa\_soap\_client: bug in logic [\#244](https://github.com/sympa-community/sympa/issues/244)
- Sympa ldap search escapes chars incorrect [\#234](https://github.com/sympa-community/sympa/issues/234)
- Anyone can unsubscribe a member of a list with open scenario [\#233](https://github.com/sympa-community/sympa/issues/233)

## [6.2.30](https://github.com/sympa-community/sympa/tree/6.2.30) (2018-03-26)

[Full Changelog](https://github.com/sympa-community/sympa/compare/6.2.28...6.2.30)

**Fixed bugs:**

- PostgreSQL: Unable to edit owners/subscribers with 6.2.26 and 6.2.28 [\#240](https://github.com/sympa-community/sympa/issues/240)

## [6.2.28](https://github.com/sympa-community/sympa/tree/6.2.28) (2018-03-22)

[Full Changelog](https://github.com/sympa-community/sympa/compare/6.2.25b.3...6.2.28)

**Fixed bugs:**

- Date in 'subscriber option' in epoch format [\#230](https://github.com/sympa-community/sympa/issues/230)

## [6.2.26](https://github.com/sympa-community/sympa/tree/6.2.26) (2018-03-20)

Withdrawn.

## [6.2.25b.3](https://github.com/sympa-community/sympa/tree/6.2.25b.3) (2018-03-13)

[Full Changelog](https://github.com/sympa-community/sympa/compare/6.2.25b.2...6.2.25b.3)

**Changes:**

- Parameters to specify location of CSS and subscriber pictures were introduced [\#172](https://github.com/sympa-community/sympa/issues/172). If you have specified `--with-staticdir` configure option or `static_content_path`/`static_content_url` parameter, you may have to fix up. See [Upgrading notes](https://sympa-community.github.io/manual/upgrade/notes.html) for details.
- `css_url` and `css_path` parameters in `robot.conf` are no longer available: Those in `sympa.conf` are used [\#172](https://github.com/sympa-community/sympa/issues/172). Also see notes above.
- `access_web_archive.*` scenarios are renamed to `archive_web_access.*` [\#216](https://github.com/sympa-community/sympa/issues/216). If you have customized any of these scenarios, you have to rename them under config directory.
- Web interface: If a user try to access info page of list, they will be silently redirected to home page, both when access is restricted and when list does not exist [\#193](https://github.com/sympa-community/sympa/issues/193). This behavior is intended not to expose existence of lists.

**Implemented enhancements:**

- Location of static\_content and css directories [\#172](https://github.com/sympa-community/sympa/issues/172)
- Feature: support for Bcrypt password hashes [\#225](https://github.com/sympa-community/sympa/pull/225) ([mpkut](https://github.com/mpkut))

**Fixed bugs:**

- Unify scenario names [\#216](https://github.com/sympa-community/sympa/issues/216)
- Rejection message returned when suscribing to a list restricted info access [\#193](https://github.com/sympa-community/sympa/issues/193)

**Merged pull requests:**

- Deprecate datetime field type in database [\#223](https://github.com/sympa-community/sympa/pull/223) ([ikedas](https://github.com/ikedas))

## [6.2.25b.2](https://github.com/sympa-community/sympa/tree/6.2.25b.2) (2018-03-05)

[Full Changelog](https://github.com/sympa-community/sympa/compare/6.2.25b.1...6.2.25b.2)

**Changes:**

- Parameters to specify location of CSS and subscriber pictures were introduced [\#172](https://github.com/sympa-community/sympa/issues/172). If you have specified `--with-staticdir` configure option or `static_content_path` parameter, you may have to fix up. See [Upgrading notes](https://sympa-community.github.io/manual/upgrade/notes.html) for details.
- smtpc (sympa_smtpc) is no longer bundled.  It was moved to [an independent repository](https://github.com/ikedas/smtpc.git) [\#201](https://github.com/sympa-community/sympa/issues/201).

- On 6.2.28 (the next of next stable), it is planned that "host" list parameter will be deprecated [\#43](https://github.com/sympa-community/sympa/issues/43).  Notice may be shown during upgrading process.

**Implemented enhancements:**

- Location of static\_content and css directories [\#172](https://github.com/sympa-community/sympa/issues/172)

**Fixed bugs:**

- Notification not sent to the owner when a list is confirmed by a listmaster [\#212](https://github.com/sympa-community/sympa/issues/212)
- Firefox freezes on "Edit robot config" page [\#206](https://github.com/sympa-community/sympa/issues/206)
- Language test fails [\#195](https://github.com/sympa-community/sympa/issues/195)
- Change bundled Raleway font from TTF to OTF [\#190](https://github.com/sympa-community/sympa/issues/190)
- Sending an html page to the list from URL doesn't work on 6.2.18 [\#44](https://github.com/sympa-community/sympa/issues/44)

**Closed issues:**

- opensmtpd setup documentation [\#32](https://github.com/sympa-community/sympa/issues/32)

**Merged pull requests:**

- Add Language.t to list of tests for Travis. [\#209](https://github.com/sympa-community/sympa/pull/209) ([racke](https://github.com/racke))
- Use standard 644 perms for $sysconfdir/README [\#203](https://github.com/sympa-community/sympa/pull/203) ([xavierba](https://github.com/xavierba))
- Issue \#43: Preliminary notice on abolishment of "host" list parameter. [\#202](https://github.com/sympa-community/sympa/pull/202) ([ikedas](https://github.com/ikedas))

## [6.2.25b.1](https://github.com/sympa-community/sympa/tree/6.2.25b.1) (2018-02-12)

[Full Changelog](https://github.com/sympa-community/sympa/compare/6.2.24...6.2.25b.1)

**Implemented enhancements:**

- Restore default\_ttl parameter [\#145](https://github.com/sympa-community/sympa/issues/145)
- moderation UI doesn't allow mass operations [\#122](https://github.com/sympa-community/sympa/issues/122)

**Fixed bugs:**

- Hardcoded max picture size in picture\_upload.tt2 [\#180](https://github.com/sympa-community/sympa/issues/180)
- Synchronize members with data source and task manager crash randomly [\#166](https://github.com/sympa-community/sympa/issues/166)
- there is a 'f' missing in a print function [\#159](https://github.com/sympa-community/sympa/issues/159)
- $localstatedir/sympa/static\_content/css directory not created at install time [\#148](https://github.com/sympa-community/sympa/issues/148)
- Create $staticdir/pictures directory [\#189](https://github.com/sympa-community/sympa/pull/189) ([xavierba](https://github.com/xavierba))
- "libexecdir" is misleadingly used instead of "execcgidir" [\#165](https://github.com/sympa-community/sympa/pull/165) ([ikedas](https://github.com/ikedas))
- WWSympa: Redirect without Status field may bring to empty page [\#164](https://github.com/sympa-community/sympa/pull/164) ([ikedas](https://github.com/ikedas))
- Inconsistencies in implementation and documentation of typical list profile \(create list templates\) [\#157](https://github.com/sympa-community/sympa/pull/157) ([ikedas](https://github.com/ikedas))

**Closed issues:**

- RAM consumption is too damn high [\#24](https://github.com/sympa-community/sympa/issues/24)

**Merged pull requests:**

-  Update bundled Raleway font with OTF flavour  [\#191](https://github.com/sympa-community/sympa/pull/191) ([xavierba](https://github.com/xavierba))

## [6.2.24](https://github.com/sympa-community/sympa/tree/6.2.24) (2017-12-21)

[Full Changelog](https://github.com/sympa-community/sympa/compare/6.2.23b.3...6.2.24)

**Fixed bugs:**

- Bundled jquery-ui library is vulnerable to an XSS [\#78](https://github.com/sympa-community/sympa/issues/78)
- Editing Moderators Requires Restart to Take Effect [\#7](https://github.com/sympa-community/sympa/issues/7)

**Closed issues:**

- Notify owner's list when a non-member sends on a mailing list [\#142](https://github.com/sympa-community/sympa/issues/142)

## [6.2.23b.3](https://github.com/sympa-community/sympa/tree/6.2.23b.3) (2017-12-14)

[Full Changelog](https://github.com/sympa-community/sympa/compare/6.2.23b.2...6.2.23b.3)

**Changes:**

- If `ca_file` and `ca_path` parameters are not specified, CA certificate stores defined by OpenSSL on each system will be used. Previously no certificate stores were not chosen in such case. [\#116](https://github.com/sympa-community/sympa/issues/116)
- The "html" reception mode was deprecated. Now it became just a synonym of "mail" (normal) reception mode. [\#125](https://github.com/sympa-community/sympa/issues/125)

**Implemented enhancements:**

- Feature: optionally restrict list ownership to specific domains \(owner\_domain\) [\#131](https://github.com/sympa-community/sympa/pull/131) ([mpkut](https://github.com/mpkut))

**Fixed bugs:**

- Cosmetic issue in error message with ldap driver [\#132](https://github.com/sympa-community/sympa/issues/132)
- No attach recived from mailing list where subscribes are set hmtl-only mode option [\#125](https://github.com/sympa-community/sympa/issues/125)
- default/ca-bundle.crt is outdated [\#116](https://github.com/sympa-community/sympa/issues/116)
- Characters in pages are garbled \(get "mojibake"\) with Perl 5.22.0 or later [\#134](https://github.com/sympa-community/sympa/pull/134) ([ikedas](https://github.com/ikedas))

**Merged pull requests:**

- Issue \#78 quickfix [\#139](https://github.com/sympa-community/sympa/pull/139) ([ikedas](https://github.com/ikedas))

## [6.2.23b.2](https://github.com/sympa-community/sympa/tree/6.2.23b.2) (2017-11-30)

[Full Changelog](https://github.com/sympa-community/sympa/compare/6.2.23b.1...6.2.23b.2)

**Fixed bugs:**

- Perl dies when changing priveleged list owners via web interface [\#37](https://github.com/sympa-community/sympa/issues/37)
- Fix listname typo [\#121](https://github.com/sympa-community/sympa/pull/121) ([jean1](https://github.com/jean1))

**Merged pull requests:**

- Before rebuilding admin\_table, won't clear it \#71 [\#130](https://github.com/sympa-community/sympa/pull/130) ([ikedas](https://github.com/ikedas))
- Remove outdated ca-bundle.crt and use system default \#116 [\#129](https://github.com/sympa-community/sympa/pull/129) ([ikedas](https://github.com/ikedas))
- Remove "html" reception mode \#125 [\#127](https://github.com/sympa-community/sympa/pull/127) ([ikedas](https://github.com/ikedas))

**Closed issues:**

- version 6.2.22, problem with virtual hosts [\#106](https://github.com/sympa-community/sympa/issues/106)
- Database connections not being closed [\#6](https://github.com/sympa-community/sympa/issues/6)

## [6.2.23b.1](https://github.com/sympa-community/sympa/tree/6.2.23b.1) (2017-11-20)

[Full Changelog](https://github.com/sympa-community/sympa/compare/6.2.22...6.2.23b.1)

**Changes:**

- "`%`" sign in SQL data source no longer need escaping by duplicating it, i.e. "`%%`". Administrators on the sites allowing SQL datasources are recommended to check datasource settings and modify them as necessity. [\#66](https://github.com/sympa-community/sympa/pull/66)
- WWSympa: FastCGI support became mandatory. CGI mode was deprecated. [\#69](https://github.com/sympa-community/sympa/issues/69)
- `important_changes.pl` in source distribution was removed. Notable changes will no longer be noticed during building process. [\#73](https://github.com/sympa-community/sympa/issues/73)
- `sympa.spec` and `META.json` will no longer be bundled in source distribution. [\#77](https://github.com/sympa-community/sympa/pull/77)
- Bundled jQuery libraries were upgraded to jquery 3.2.1, jquery-migrate 3.0.1 and jquery-ui 1.12.1 to avoid XSS vulnerability. [\#78](https://github.com/sympa-community/sympa/issues/78)
- Now `topics.conf` treats topic names ignoring cases. Previously names including uppercase letters were ignored.  [\#91](https://github.com/sympa-community/sympa/issues/91)
- `alias_manager.pl` was obsoleted. Alias files will be updated by internal module directly. Though `alias_manager.pl` is still available for backward compatibility, it will be removed in the future. [\#118](https://github.com/sympa-community/sympa/pull/118)
- Several typos and bad wordings in English translation catalog were corrected. Some phrases in default templates, scenarios and tasks were changed. \[[1e2e094](https://github.com/sympa-community/sympa/commit/1e2e0941fd771a702b7d04f2166bbe59d90ca6cd)\]

**Implemented enhancements:**

- Refactoring alias manager: Obsolete alias\_manager.pl [\#118](https://github.com/sympa-community/sympa/pull/118) ([ikedas](https://github.com/ikedas))
- Suppress saving stats file, and solve problem about on-memory cache [\#105](https://github.com/sympa-community/sympa/pull/105) ([ikedas](https://github.com/ikedas))
- Cache list info in Sympa::Scenario::verify to reduce overhead of pinfo… [\#97](https://github.com/sympa-community/sympa/pull/97) ([mpkut](https://github.com/mpkut))
- Feature: add scenari to restrict message submission to list owners [\#96](https://github.com/sympa-community/sympa/pull/96) ([mpkut](https://github.com/mpkut))
- Add use\_tls, ssl, version etc to valid LDAP options in Scenario.pm [\#95](https://github.com/sympa-community/sympa/pull/95) ([mpkut](https://github.com/mpkut))
- When fallback language "en" is used, use "en\_US" translation catalog [\#84](https://github.com/sympa-community/sympa/pull/84) ([ikedas](https://github.com/ikedas))
- Refactoring requests more [\#81](https://github.com/sympa-community/sympa/pull/81) ([ikedas](https://github.com/ikedas))

**Fixed bugs:**

- Archived-At: field on resent messages in archive are wrong. [\#111](https://github.com/sympa-community/sympa/issues/111)
- Review.tt2 button correction. [\#98](https://github.com/sympa-community/sympa/issues/98)
- Change redirect after incorrect choosepasswd - UX suggestion [\#93](https://github.com/sympa-community/sympa/issues/93)
- Topic names in topics.conf with uppercase are ignored [\#91](https://github.com/sympa-community/sympa/issues/91)
- Fix ridiculous English spelling for spam protection button [\#80](https://github.com/sympa-community/sympa/issues/80)
- Change Redirect After List Admin Updates a User's Email - UX Suggestion [\#76](https://github.com/sympa-community/sympa/issues/76)
- important\_changes.pl is broken [\#73](https://github.com/sympa-community/sympa/issues/73)
- Log list not sorted for date [\#70](https://github.com/sympa-community/sympa/issues/70)
- include\_ldap\_query and include\_ldap\_2level\_query behaving differently [\#63](https://github.com/sympa-community/sympa/issues/63)
- Responsive table breaks form submission [\#61](https://github.com/sympa-community/sympa/issues/61)
- Changes on POD format for transition to Markdown [\#123](https://github.com/sympa-community/sympa/pull/123) ([ikedas](https://github.com/ikedas))
- Insignificant bugs related to cache [\#120](https://github.com/sympa-community/sympa/pull/120) ([ikedas](https://github.com/ikedas))
- Refactoring alias manager: Obsolete alias\_manager.pl [\#118](https://github.com/sympa-community/sympa/pull/118) ([ikedas](https://github.com/ikedas))
- Refactoring requests 5 [\#109](https://github.com/sympa-community/sympa/pull/109) ([ikedas](https://github.com/ikedas))
- Suppress saving stats file, and solve problem about on-memory cache [\#105](https://github.com/sympa-community/sympa/pull/105) ([ikedas](https://github.com/ikedas))
- Old variable names used in listmaster error mail [\#104](https://github.com/sympa-community/sympa/pull/104) ([sivertkh](https://github.com/sivertkh))
- Fix CSS attributes for un-hovered navigation menu items using color\_5 [\#94](https://github.com/sympa-community/sympa/pull/94) ([mpkut](https://github.com/mpkut))
- Bugs on subscribe request with custom attributes and/or authorization [\#89](https://github.com/sympa-community/sympa/pull/89) ([ikedas](https://github.com/ikedas))
- Refactoring requests more [\#81](https://github.com/sympa-community/sympa/pull/81) ([ikedas](https://github.com/ikedas))
- "%" sign in SQL data source would be escaped [\#66](https://github.com/sympa-community/sympa/pull/66) ([ikedas](https://github.com/ikedas))

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
