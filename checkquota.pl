#!/usr/bin/perl

print "email;usage;total quota\n";

my @hostname = `su - zimbra -c "zmprov -l gas mailbox"`;

foreach my $mailbox(@hostname) {

my @quotas = `su - zimbra -c 'zmprov gqu $mailbox'`;

foreach my $quotaline(@quotas)

{

chop($quotaline);

my ($email, $quota, $usage) = split(' ', $quotaline);

$quota=utils_convert_bytes_to_optimal_unit($quota);

$usage=utils_convert_bytes_to_optimal_unit($usage);

print "$email;$usage;$quota\n";

}
}

sub utils_convert_bytes_to_optimal_unit{

my($bytes) = @_;

return '' if $bytes eq '';

my $size;

$size = $bytes . ' Bytes' if $bytes < 1024;

$size = sprintf("%.2f", $bytes/1024) . ' KB' if $bytes >= 1024 && $bytes < 1048576;

$size = sprintf("%.2f", $bytes/1048576) . ' MB' if $bytes >= 1048576 && $bytes < 1073741824;

$size = sprintf("%.2f", $bytes/1073741824) . ' GB' if $bytes >= 1073741824 && $bytes < 1099511627776;

$size = sprintf("%.2f", $bytes/1099511627776) . ' TB' if $bytes >= 1099511627776;

return $size;

}
