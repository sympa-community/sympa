# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id: tools_file.t 8606 2013-02-06 08:44:02Z rousse $

use strict;
use warnings;

use Test::More;
use English qw(-no_match_vars);
use File::Temp;
use File::stat;
use Fcntl qw(:mode);

use Sympa::Tools::File;

#plan tests => 25;
plan tests => 23;

my $user  = getpwuid($UID);
my $group = getgrgid($GID);
my $file  = File::Temp->new();

ok(Sympa::Tools::File::set_file_rights(file => $file),
    'file, nothing else: ok');

ok(!Sympa::Tools::File::set_file_rights(file => $file, user => 'none'),
    'file, invalid user: ko');

ok(!Sympa::Tools::File::set_file_rights(file => $file, group => 'none'),
    'file, invalid group: ko');

ok(Sympa::Tools::File::set_file_rights(file => $file, mode => 999),
    'file, invalid mode: ok (fixme)');

if ($UID) {
    ok( !Sympa::Tools::File::set_file_rights(
            file  => $file,
            user  => $user,
            group => 'none'
        ),
        'file, valid user, invalid group: ko'
    );
} else {
    ok !defined eval {
        Sympa::Tools::File::set_file_rights(
            file  => $file,
            user  => $user,
            group => 'none'
        );
    }, 'file, supere-user, invalid group: ko';
}

ok( !Sympa::Tools::File::set_file_rights(
        file  => $file,
        user  => 'none',
        group => $group
    ),
    'file, invalid user, valid group: ko'
);

if ($UID) {
    ok( Sympa::Tools::File::set_file_rights(
            file  => $file,
            user  => $user,
            group => $group
        ),
        'file, valid user, valid group: ok'
    );
} else {
    ok !defined eval {
        Sympa::Tools::File::set_file_rights(
            file  => $file,
            user  => $user,
            group => $group
        );
    }, 'file, super-user, valid group: ok';
}

if ($UID) {
    ok( Sympa::Tools::File::set_file_rights(
            file  => $file,
            user  => $user,
            group => $group,
            mode  => 0666
        ),
        'file, valid user, valid group, valid mode: ok'
    );
} else {
    ok !defined eval {
        Sympa::Tools::File::set_file_rights(
            file  => $file,
            user  => $user,
            group => $group,
            mode  => 0666
        );
    }, 'file, super-user, valid group, valid mode: ok';
    Sympa::Tools::File::set_file_rights(file => $file, mode => 0666);
}

is(get_perms($file), "0666", "expected mode");

my $dir;

$dir = File::Temp->newdir();
Sympa::Tools::File::del_dir($dir);
ok(!-d $dir, 'del_dir with empty dir');

$dir = File::Temp->newdir();
Sympa::Tools::File::remove_dir($dir);
ok(!-d $dir, 'remove_dir with empty dir');

$dir = File::Temp->newdir();
touch($dir . '/foo');
Sympa::Tools::File::del_dir($dir);
ok(!-d $dir, 'del_dir with non empty dir');

$dir = File::Temp->newdir();
touch($dir . '/foo');
Sympa::Tools::File::remove_dir($dir);
ok(!-d $dir, 'remove_dir with non empty dir');

$dir = File::Temp->newdir();
Sympa::Tools::File::mk_parent_dir($dir . '/foo/bar/baz');
ok(-d "$dir/foo",     'mk_parent_dir first element');
ok(-d "$dir/foo/bar", 'mk_parent_dir second element');

#$dir = File::Temp->newdir();
#Sympa::Tools::File::mkdir_all($dir . '/foo/bar/baz');
#ok(!-d "$dir/foo", 'mkdir_all first element, no mode');
#ok(!-d "$dir/foo/bar", 'mkdir_all second element, no mode');

$dir = File::Temp->newdir();
Sympa::Tools::File::mkdir_all($dir . '/foo/bar/baz', 0777);
ok(-d "$dir/foo",     'mkdir_all first element');
ok(-d "$dir/foo/bar", 'mkdir_all second element');
is(get_perms("$dir/foo"),     "0777", "first element, expected mode");
is(get_perms("$dir/foo/bar"), "0777", "second element, expected mode");

# Note: Some platforms (e.g. macOS with Perl < 5.32) miss or simply don't
# implement futimes system call so that calling utime() on filehandle may
# crash.
utime 1234567890, 123456789, $file->filename;
is(Sympa::Tools::File::get_mtime($file), 123456789);
utime 123456789, 1234567890, $file->filename;
is(Sympa::Tools::File::get_mtime($file), 1234567890);
ok(Sympa::Tools::File::get_mtime("$dir/no-such-file") < -32768);
chmod 0333, $file;
if ($UID) {
    ok(Sympa::Tools::File::get_mtime($file) < -32768, 'unreadable file');
} else {
    is(Sympa::Tools::File::get_mtime($file),
        1234567890, 'readable by super-user');
}

sub touch {
    my ($file) = @_;
    open(my $fh, '>', $file) or die "Can't create file: $ERRNO";
    close $fh;
}

sub get_perms {
    my ($file) = @_;
    return sprintf("%04o", stat($file)->mode() & 07777);
}
