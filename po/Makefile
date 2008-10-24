

LINGUAS = af ar br bg ca cs de el en_US es et eu fi fr hu id it ja ko ml nb_NO nn_NO nl oc pl pt pt_BR ro ru sv tr vi zh_CN zh_TW
SYMPA_LOCALES = af_ZA ar_SY br_FR bg_BG ca_ES cs_CZ de_DE el_GR en_US es_ES et_EE eu_ES fi_FI fr_FR hu_HU id_ID it_IT ja_JP ko_KR ml_IN nb_NO nn_NO nl_NL oc_FR pl_PL pt_BR pt_PT ro_RO ru_RU sv_SE tr_TR vi_VN zh_CN zh_TW
MOBASICFILES = $(addsuffix .mo, $(LINGUAS))
MOHELPFILES = $(addprefix web_help_, $(MOBASICFILES))
MOFILES = $(MOBASICFILES) $(MOHELPFILES)

DEPENDON = $(shell cd .. ; ls src/*.p? wwsympa/wwsympa.fcgi wwsympa/*.p? web_tt2/*.tt2 mail_tt2/*.tt2 src/etc/mhonarc-ressources.tt2 src/etc/scenari/*)

MSGMERGE = msgmerge
MSGCAT = msgcat
MSGFMT   = msgfmt
MSGATTRIB = msgattrib
XGETTEXT = po/xgettext.pl

## Available catalogues (languages)
.SUFFIXES: .po .mo

.mo:   .po

.po.mo:
	$(MSGFMT) -o $@ $<

all: $(MOFILES) checklocales

potfile: sympa.pot web_help.pot

checklocales:
	@echo "Checking available locales ..."
	@(	SYMPA_LOCALES="$(SYMPA_LOCALES)"; export SYMPA_LOCALES; \
		$(PERL) ./check_locales.pl \
	)

pot:
	echo "Updating sympa.pot template file..."
	cd .. ;\
	$(XGETTEXT) -u -o po/sympa.pot src/*.p? soap/*.p? soap/*.fcgi wwsympa/wwsympa.fcgi wwsympa/*.p? web_tt2/*.tt2 mail_tt2/*.tt2 src/etc/mhonarc-ressources.tt2 src/etc/scenari/* src/etc/global_task_models/* src/etc/list_task_models/* src/etc/create_list_templates/*/*; \
	$(XGETTEXT) -t helploc -u -o po/web_help.pot web_tt2/help*.tt2;

install: $(MOFILES)
	@( \
	targetdir='$(DESTDIR)$(LOCALEDIR)'; \
	languages='$(LINGUAS)'; \
	for lang in $$languages; do \
		mkdir -p "$$targetdir/$$lang/LC_MESSAGES" || exit 1; \
		dest="$$targetdir/$$lang/LC_MESSAGES/sympa.mo"; \
		cat="$$lang.mo"; \
		echo "Installing mo file...$$dest"; \
		cp -f $$cat $$dest && chmod 644 $$dest || exit 1; \
		dest="$$targetdir/$$lang/LC_MESSAGES/web_help.mo"; \
		cat="web_help_$$lang.mo"; \
		echo "Installing mo file...$$dest"; \
		cp -f $$cat $$dest && chmod 644 $$dest || exit 1; \
	done \
	)

update-po: potfile
	languages='$(LINGUAS)'; \
	mkdir -p tmp; \
	for lang in $$languages; do \
		echo "Updating $$lang.po"; \
		cp -p "$$lang.po" tmp/; \
		$(MSGMERGE) -o "$$lang.po" "$$lang.po" sympa.pot; \
		$(MSGCAT) --use-first -o "$$lang.po" "$$lang.po" tmp/"$$lang.po"; \
		rm -f tmp/"$$lang.po"; \
		echo "Updating web_help_$$lang.po"; \
		cp -p "web_help_$$lang.po" tmp/; \
		touch "web_help_$$lang.po"; \
		$(MSGMERGE) -o "web_help_$$lang.po" "web_help_$$lang.po" web_help.pot; \
		$(MSGCAT) --use-first -o "web_help_$$lang.po" "web_help_$$lang.po" tmp/"web_help_$$lang.po"; \
		rm -f tmp/"web_help_$$lang.po";\
	done
	rm -rf tmp
	msgen en_US.po -o en_US.po
	msgen web_help_en_US.po -o web_help_en_US.po


clean-po: potfile
	languages='$(LINGUAS)'; \
	for lang in $$languages; do \
		echo "Updating $$lang.po"; \
		$(MSGMERGE) -o "$$lang.po" "$$lang.po" sympa.pot; \
		echo "Updating web_help_$$lang.po"; \
		touch "web_help_$$lang.po"; \
		$(MSGMERGE) -o "web_help_$$lang.po" "web_help_$$lang.po" web_help.pot; \
	done
	msgen en_US.po -o en_US.po
	msgen web_help_en_US.po -o web_help_en_US.po


## Prepare a tar.gz with a structure adapted to Pootle
## ie made of subdirectories (ll/sympa.po...templates/sympa.pot
export:
	echo "Building /tmp/sympa-po.tar.gz..."; \
	if [ -d  /tmp/sympa-po ]; then \
		rm -rf /tmp/sympa-po; \
	fi
	mkdir /tmp/sympa-po; \
	mkdir /tmp/sympa-po/sympa; \
	mkdir /tmp/sympa-po/web_help; \
	mkdir /tmp/sympa-po/terminology; \
	languages='$(LINGUAS)'; \
	for lang in $$languages; do \
		mkdir /tmp/sympa-po/sympa/$$lang; \
		cp $$lang.po /tmp/sympa-po/sympa/$$lang/sympa.po; \
		mkdir /tmp/sympa-po/web_help/$$lang; \
		cp web_help_$$lang.po /tmp/sympa-po/web_help/$$lang/web_help.po; \
	done
	mkdir /tmp/sympa-po/sympa/templates; \
	mkdir /tmp/sympa-po/web_help/templates; \
	mkdir /tmp/sympa-po/terminology/templates; \
	cp sympa.pot /tmp/sympa-po/sympa/templates/sympa.pot; \
	cp web_help.pot /tmp/sympa-po/web_help/templates/web_help.pot; \
	cp terminology.pot /tmp/sympa-po/terminology/templates/terminology.pot; \
	(cd /tmp/sympa-po; tar -zcvf /tmp/sympa-po.tar.gz *)

## Check translations, coming from Rosetta for instance
## These PO files are supposed to gathered in a directory
check:
	@echo -n "Enter directory containing PO files to check: "; \
	read dir; \
	for file in $$dir/*.po; do \
		filename=`basename $$file`; \
		count=`$(MSGATTRIB) --translated --no-obsolete "$$file"|grep -c "^msgid"`; \
		if [ ! -f  "$$filename" ]; then \
			echo "New PO file: $$filename ; $$count strings"; \
		else \
			countprevious=`$(MSGATTRIB) --translated --no-obsolete "$$filename"|grep -c "^msgid"`; \
			echo "Stats $$filename : $$countprevious / $$count"; \
		fi \
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
