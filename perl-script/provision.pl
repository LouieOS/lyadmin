#!/usr/bin/perl

use warnings;
use strict;

# This script is intended to be run on a fresh
# OpenBSD install

my $admin_un;

# Check /etc/passwd for the username created during
# installation
if( ($admin_un) = `tail /etc/passwd` =~ /([^:]+):[^:]+:[0-9]{4,}/){
    printf("admin user will be set to %s\n", $admin_un);
}else{
    die "create a non-root user & set user passsword before running this script."
}

