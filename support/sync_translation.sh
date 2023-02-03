#!/bin/bash
set -Ceu
SET_X="$(set +o | grep xtrace)"

AUTHOR_EMAIL="devel@sympa.community"
AUTHOR_NAME="Sympa authors"
SYMPA_PUSH_BRANCH="translation"
TRANS_PROJECTS="sympa web_help terminology"
TRANS_DIRECTORY=/var/lib/pootle/translations
VIRTUALENV_USER="pootle"
VIRTUALENV_SOURCE="$HOME"/env/bin/activate

function cmp_templates() {
    python <<'EOF' - "$1" "$2"
import re, sys

def msgids(filename):
    ret = set()
    with open(filename) as f:
        for line in ''.join(f.readlines()).replace('"\n"', '').split("\n"):
            m = re.match(r'^msgid\s+(.+)', line)
            if m:
                ret.add(m.group(1))
    return ret

store = msgids(sys.argv[1])
curr = msgids(sys.argv[2])

sys.stderr.write(
    'Message counts: store=%d, repo=%d\n'
    'Difference: removed=%d, added=%d\n'
    % (len(store), len(curr), len(store - curr), len(curr - store))
)

sys.exit(0 if (curr - store) else 1)
EOF
}


# Activate environment for pootle, preventing execution by the other user.
if [ -v USER ]; then
    test "$USER" = "$VIRTUALENV_USER"
else
    test "$LOGNAME" = "$VIRTUALENV_USER"
fi
set +x
# shellcheck disable=SC1090
. "$VIRTUALENV_SOURCE"
$SET_X

if [ -v 1 ]; then
    TRANS_DIRECTORY="$1"
fi
test -d "$TRANS_DIRECTORY"
test -r "$TRANS_DIRECTORY"
test -w "$TRANS_DIRECTORY"

# Confirm that remote repository has been cloned using the Deploy Key.
# Confirm that any branches in remote origin may be fetched.

git config --get remote.origin.url
git config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
git fetch --quiet --depth 50

# Export recent translations under TRANS_DIRECTORY.
# "pootle sync_stores" is the command to export them.

pootle sync_stores -v 2 --traceback |& grep -v Running:

# Update translation catalog according to changes in source code.
# This needs autoconf, automake and gettext packages.
# If additions are found, merge it into translation store.

autoreconf -i
./configure -q

for project in $TRANS_PROJECTS; do
    cd po/"$project"

    if [ "$project" '!=' "terminology" ]; then
        make --quiet "$project".pot-update
    fi
    if cmp_templates \
        "$TRANS_DIRECTORY"/"$project"/"$project".pot "$project".pot; then
        for po in *.po; do
            msgcat -o "$po".new --use-first \
                "$TRANS_DIRECTORY"/"$project"/"$po" "$po"
            mv "$po".new "$po"
        done
        make --quiet MSGMERGE_OPTIONS="--quiet" update-po

        if [ -e "$TRANS_DIRECTORY"/"$project".3 ]; then
            rm -Rf "$TRANS_DIRECTORY"/"$project".3
        fi
        if [ -e "$TRANS_DIRECTORY"/"$project".2 ]; then
            mv "$TRANS_DIRECTORY"/"$project".2 "$TRANS_DIRECTORY"/"$project".3
        fi
        if [ -e "$TRANS_DIRECTORY"/"$project".1 ]; then
            mv "$TRANS_DIRECTORY"/"$project".1 "$TRANS_DIRECTORY"/"$project".2
        fi
        cp -Rp "$TRANS_DIRECTORY"/"$project" "$TRANS_DIRECTORY"/"$project".1

        cp -p "$project".pot ./*.po "$TRANS_DIRECTORY"/"$project"/
        pootle update_stores -v 2 --traceback --project "$project"
    else
        echo "$project: No need to update pootle store."
    fi

    cd ../..
done
# Cleanup changes
make --quiet distclean
git checkout .

#XXXexit 0

# Initialize workspace.
# Create a new branch "translation".

git config user.email "$AUTHOR_EMAIL"
git config user.name "$AUTHOR_NAME"
git checkout -b "$SYMPA_PUSH_BRANCH"

# Update translations on repo with ones on translation server.
# And commit the changes.

for project in $TRANS_PROJECTS; do
    cd po/"$project"

    for po in *.po; do
        msgcat -o "$po".new --use-first \
            "$TRANS_DIRECTORY"/"$project"/"$po" "$po"
        mv "$po".new "$po"
    done

    cd ../..
done

if git diff HEAD \
    | grep -E -v '^(---|\+\+\+|[-+]"POT-Creation-Date:)' \
    | grep -q '^[-+]'; then
    git commit -a \
        -m '[-feature] Committing latest translations from translate.sympa.community'
else
    echo 'Nothing to update.'
    exit 0
fi

# Typo fixes: If en_US.po is updated, update translated messages in
# po files and source code.  "correct_msgid" will do it.
# And commit the changes.

for project in $TRANS_PROJECTS; do
    if [ "$project" '!=' "terminology" ]; then
        support/correct_msgid --dry_run --domain "$project"
        support/correct_msgid --domain "$project"
    fi
done

if git diff --quiet HEAD; then
    echo 'Nothing to update according to fixes on en_US catalog.'
else
    git commit -a \
        -m 'Updating source texts according to fixes on en_US catalog'
fi

# Update translation catalog according to changes in source code.
# This needs autoconf, automake and gettext packages.
# And if any, commit the changes.

autoreconf -i
./configure -q

for project in $TRANS_PROJECTS; do
    cd po/"$project"

    cp -p "$project".pot "$project".pot-HEAD
    if [ "$project" '!=' "terminology" ]; then
        make --quiet "$project".pot-update
    fi
    if cmp_templates \
        "$project".pot-HEAD "$project".pot; then
        make --quiet MSGMERGE_OPTIONS="--quiet" update-po
    else
        # No update
        mv "$project".pot-HEAD "$project".pot
    fi

    cd ../..
done
if git diff --quiet HEAD; then
    echo 'No need to update translation catalog.'
else
    git commit -a \
        -m 'Updating translation catalog'
fi

# Push the changes
#XXXexit 0

if git branch -r | grep -q ' origin/'"$SYMPA_PUSH_BRANCH"'$'; then
    if git diff origin/"$SYMPA_PUSH_BRANCH" -- po \
        | grep -E -v '^(---|\+\+\+|[-+]"POT-Creation-Date:)' \
        | grep -q '^[-+]'; then
        do_push="yes"
    else
        do_push="no"
    fi
else
    do_push="yes"
fi
if [ "$do_push" = "yes" ]; then
    git push -f origin "$SYMPA_PUSH_BRANCH"
else
    echo 'Nothing to push.'
fi

