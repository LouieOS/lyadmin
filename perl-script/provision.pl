#!/usr/bin/perl

use warnings;
use strict;

# provision.pl
# script to provision a tilde instance
# 
# This script is intended to be run on a fresh
# OpenBSD install
#
# gashapwn
# Nov 2020


my $pwuid;
my $admin_un;


# Make sure we're running as root
$pwuid = getpwuid( $< );

if($pwuid ne "root"){
    die "script must be run as root";
}

# Check /etc/passwd for the username created during
# installation
if( ($admin_un) = `tail /etc/passwd | grep -v "nobody:"` =~ /([^:\n]+):[^:]+:[0-9]{4,}/){
    printf("admin user will be set to %s\n", $admin_un);
}else{
    die "create a non-root user & set user passsword before running this script."
}

