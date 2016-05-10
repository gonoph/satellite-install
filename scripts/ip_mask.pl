#!/usr/bin/perl

use Socket qw(inet_ntoa inet_aton);

$IP_MASK=shift || "127.0.0.1/8";
($IP, $MASK) = split(/\//, $IP_MASK);
$IP = "127.0.0.1" unless $IP;
$MASK = 32 unless $MASK;
$aton=unpack("N", inet_aton($IP));
$M=2**32 - (2**(32 - $MASK));
$N=$aton & $M;
$B=$aton | ((2**32 - $M) - 1);
$NA=inet_ntoa(pack("N", $N));
$BA=inet_ntoa(pack("N", $B));
$MA=inet_ntoa(pack("N", $M));
print << "PERL_EOF";
IP=$IP
MASK=$MASK
NETWORK=$NA
BROADCAST=$BA
NETMASK=$MA
PERL_EOF
