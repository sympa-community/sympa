
foreach $src (@ARGV) {

   unless (open(IN, $src)) {
      print STDERR "Can't read $src: $!\n";
      next;
   }

   unless (defined ($ENV{'INSTALLDIR'})) {
       die "Missing INSTALLDIR variable";
   }

   my $dest = "$ENV{'DESTDIR'}$ENV{'INSTALLDIR'}/$src";

   if (-f $dest) {
      print STDERR "Overwriting $dest\n";
   } else {
      print STDERR "Creating $dest\n";
   }
   unless (open(OUT, "> $dest")) {
      print STDERR "Can't write $dest: $!\n";
      close(IN);
      next;
   }
   
#   foreach my $v (keys %ENV) {
#       printf "ENV %s=%s\n", $v, $ENV{$v};
#   }

   while (<IN>) {
       s/--(\w+)--/$ENV{$1}/g;
       print OUT $_;
   }
   close(OUT);
   close(IN);
#   chown ((getpwnam($ENV{'USER'}))[2,3], $dest);
   chmod oct($ENV{'UMASK'}), $dest;
}
exit(0);
