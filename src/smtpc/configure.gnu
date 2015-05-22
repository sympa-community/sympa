# $Id$

args=
for arg; do
    case "$arg" in
    *\'*)
        arg=`cat <<EOF | sed -e "s/'/'\\''/g"`
$arg
EOF
        ;;
    *)
        ;;
    esac
    args="$args '$arg'"
done

cat <<EOF
configure.gnu: running ./configure $args $SMTPC_CONFIGURE_OPTIONS
EOF
eval "./configure $args $SMTPC_CONFIGURE_OPTIONS"
