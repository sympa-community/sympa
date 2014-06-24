# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

use strict;
use warnings;
use English qw(-no_match_vars);
use File::Temp;
use Test::More;

use Sympa::LockedFile;

plan tests => 19;

my $lock;
my $temp_dir  = File::Temp->newdir(CLEANUP => $ENV{TEST_DEBUG} ? 0 : 1);
my $main_file = $temp_dir . '/file';
my $lock_file = $main_file . '.LOCK';

eval {
    $lock = Sympa::LockedFile->new();
    $lock->open();
};
like($@, qr/^Usage: /, 'Usage: ');

eval { $lock = Sympa::LockedFile->new($main_file, 0, 'something'); };
like($@, qr/^IO::Handle: bad open mode/, 'IO::Handle: bad open mode');

ok(!-f $lock_file, "underlying lock file doesn't exist");

open my $fh, '>', $main_file;
close $fh;
eval { $lock = Sympa::LockedFile->new($main_file); };
ok(!$@, 'all parameters OK');

isa_ok($lock, 'Sympa::LockedFile');
can_ok($lock, 'open');
can_ok($lock, 'close');

ok(-f $lock_file, "underlying lock file does exist");

ok($lock->open($main_file), 'locking locked file, unspecified mode');
##ok($lock->open($main_file, 0, 'Anything'), 'locking, irrelevant mode');
ok($lock->open($main_file, 0, '<'), 'locking locked file, read mode');
ok(!$lock->open($main_file, 2, '>'), 'prevented locking, write mode');
ok(!$lock->open($main_file, -1, '>'),
    'prevented non-blocking locking, write mode');
ok($lock->close, 'unlocking');
ok($lock->open($main_file, 0, '>'), 'locking unlocked file, write mode');

ok(attempt_parallel_lock($temp_dir . '/foo', '>'),
    'write lock on another file');
ok(!attempt_parallel_lock($main_file, '<'), 'read lock on same file');
ok(!attempt_parallel_lock($main_file, '>'), 'write lock on same file');

$lock->close;
$lock->open($main_file);
my $another_lock = Sympa::LockedFile->new($main_file);
ok($another_lock->close(), 'unlocking, new lock');

$lock->close;
ok(!-f $lock_file, "all locks released, underlying lock file doesn't exist");

sub attempt_parallel_lock {
    my ($file, $mode) = @_;

    my $code = <<EOF;
my \$lock = Sympa::LockedFile->new("$file", -1, "$mode");
exit \$lock + 0;
EOF
    my @command = ($EXECUTABLE_NAME, "-MSympa::LockedFile", "-e", $code);
    system(@command);
    return $CHILD_ERROR >> 8;
}
