#!/usr/bin/perl
# Satellite-install ip-mask helper script - to extract and print the ip, netmask, and subnet of an ipv4 address.
# Copyright (C) 2016  Billy Holmes <billy@gonoph.net>
# 
# This file is part of Satellite-install.
# 
# Satellite-install is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option) any
# later version.
# 
# Satellite-install is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
# 
# You should have received a copy of the GNU General Public License along with
# Satellite-install.  If not, see <http://www.gnu.org/licenses/>.


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
