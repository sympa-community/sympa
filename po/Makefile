

LINGUAS = cs de en_US el es et fi fr hu it ja nl oc pl pt pt_BR ro sv tr zh_CN zh_TW
SYMPA_LOCALES = cs_CZ de_DE el_GR en_US es_ES et_EE fi_FI fr_FR hu_HU it_IT ja_JP nl_NL oc_FR pl_PL pt_BR pt_PT ro_RO sv_SE tr_TR zh_CN zh_TW
MOFILES = $(addsuffix .mo, $(LINGUAS))

DEPENDON = $(shell cd .. ; ls src/*.p? wwsympa/wwsympa.fcgi wwsympa/*.p? web_tt2/*.tt2 mail_tt2/*.tt2 src/etc/mhonarc-ressources.tt2 src/etc/scenari/*)

MSGMERGE = msgmerge
MSGFMT   = msgfmt
MSGATTRIB = msgattrib
XGETTEXT = po/xgettext.pl

## Available catalogues (languages)
.SUFFIXES: .po .mo

.mo:   .po

.po.mo:
	$(MSGFMT) -o $@ $<

all: $(MOFILES) checklocales

potfile: sympa.pot

checklocales:
	@echo "Checking available locales ..."
	@(	SYMPA_LOCALES="$(SYMPA_LOCALES)"; export SYMPA_LOCALES; \
		$(PERL) ./check_locales.pl \
	)

pot:
	echo "Updating sympa.pot template file..."
	cd .. ;\
	$(XGETTEXT) -o po/sympa.pot src/*.p? soap/*.p? soap/*.fcgi wwsympa/wwsympa.fcgi wwsympa/*.p? web_tt2/*.tt2 mail_tt2/*.tt2 src/etc/mhonarc-ressources.tt2 src/etc/scenari/* src/etc/global_task_models/* src/etc/list_task_models/* src/etc/create_list_templates/*/*

install: $(MOFILES)
	targetdir='$(DESTDIR)$(LOCALEDIR)'; \
	languages='$(LINGUAS)'; \
	for lang in $$languages; do \
		mkdir -p "$$targetdir/$$lang/LC_MESSAGES" || exit 1; \
		dest="$$targetdir/$$lang/LC_MESSAGES/sympa.mo"; \
		cat="$$lang.mo"; \
		echo "Installing mo file...$$dest"; \
		cp -f $$cat $$dest && chmod 644 $$dest || exit 1; \
	done

update-po: potfile
	languages='$(LINGUAS)'; \
	for lang in $$languages; do \
		echo "Updating $$lang.po"; \
		$(MSGMERGE) -o "$$lang.po" "$$lang.po" sympa.pot; \
	done

stats:
	languages='$(LINGUAS)'; \
	for lang in $$languages; do \
		echo "Stats for  $$lang.po"; \
		echo -n "  Translated: "; \
		$(MSGATTRIB) --translated --no-obsolete "$$lang.po"|grep -c "^msgid"; \
		echo -n "  Not translated: "; \
		$(MSGATTRIB) --untranslated --no-obsolete "$$lang.po"|grep -c "^msgid"; \
		echo -n "  Fuzzy: "; \
		$(MSGATTRIB) --only-fuzzy --no-obsolete "$$lang.po"|grep -c "^msgid"; \
		echo -n "  Obsolete: "; \
		$(MSGATTRIB) --only-obsolete "$$lang.po"|grep -c "^#~ msgid"; \
		echo ;\
	done
