#!/usr/bin/perl

use Getopt::Std;
use vars qw/ %opt /;

# Just change this command line to be compatible with your setup
$zimbra_status_command="su - zimbra -c '/opt/zimbra/bin/zmcontrol status'";


# You should'n change anything behind this line.
$DEBUG=0;
$output="";
$faulty_service=0;
$faulty_daemon=0;

getopts('sSChde:', \%opt);

if (exists $opt{h}) {
    usage();
    exit(0);
}
if (exists $opt{d}) {
    $DEBUG=1;
}
if (exists $opt{e}) {
    $exclude_list=$opt{e};
    print "Excluded list : $exclude_list\n" if $DEBUG;
}


# Getting zimbra status :
open (ZMSTATUS, "$zimbra_status_command |");
while (<ZMSTATUS>){
    print $_ if $DEBUG;
    if (/^Host/){
        my ($tmp,
        $hostname)=split();
        $output=
"HOST : $hostname"
    } else {
        ($service,
        $state)=split();    
    }
    if ($exclude_list =~ /$service/){
        print "Service $service is excluded from monitoring\n" if $DEBUG;
        next;
    }
    if ( $state eq "Running" ){
        $output=$output . "
$service:OK";
    } elsif ( $state eq "Stopped" ){
        $output=$output . "
$service:STOPPED";
        $faulty_service++;
    }
#elsif ( $state eq "is" ){
#$output=$output . " and $service down";
#        $faulty_daemon++;
#    }
    
    
    
}
print $output . "\n";
close (ZMSTATUS);

print "Faulty Services : $faulty_service, Faulty Daemons : $faulty_daemon\n" if $DEBUG;
# Choosing right exit code :
# 0 OK, 1 Warning, 2 Critical, 3 Unknow
if (exists $opt{s}) {
    #stopped service are ignored until some daemon is faulty
    if ( $faulty_service > 0 && $faulty_daemon > 0){
        exit(2);
    } elsif ( $faulty_service > 0 && $faulty_daemon == 0){
        exit(0);
    } elsif ( $faulty_service == 0 && $faulty_daemon == 0){
        exit(0);
    } else {
        exit(3);
    }
}

if (exists $opt{S}) {
    #stopped service give warning state
    if ( $faulty_service > 0 && $faulty_daemon > 0){
        exit(2);
    } elsif ( $faulty_service > 0 && $faulty_daemon == 0){
        exit(1);
    } elsif ( $faulty_service == 0 && $faulty_daemon == 0){
        exit(0);
    } else {
        exit(3);
    }
}

if (exists $opt{C}) {
    #stopped service give critical state in all cases
    if ( $faulty_service > 0 && $faulty_daemon > 0){
        exit(2);
    } elsif ( $faulty_service > 0 && $faulty_daemon == 0){
        exit(2);
    } elsif ( $faulty_service == 0 && $faulty_daemon == 0){
        exit(0);
    } else {
        exit(3);
    }
}


sub usage {
    if (@_ == 1) {
        print "$0: $_[0].\n";
    }
    print << "EOF";
Usage: $0 [options]
  -s
     stopped service are ignored until some daemon is faulty
  -S
     stopped service give warning state if a service is faulty
  -C
     stopped service give critical if a service is faulty
  -e service1,service2,..
     list of excluded services from monitoring
  -d
     enable debug mode
  -h
     display usage information
EOF
}
