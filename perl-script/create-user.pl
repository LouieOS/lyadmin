#!/usr/bin/perl

use warnings;
use strict;

my $WORKING_DIR = "/home/gashapwn/lyadmin/";
my $ACCOUNT_DIR = "test/";

my $FULL_PATH = "$WORKING_DIR$ACCOUNT_DIR";

my @g;


die "test 0";

@g = glob("$FULL_PATH*");
@g = map { s/.*\/([^\/]*).pub$/$1/; $_ } grep {$_ =~ /pub$/} @g;

for my $fn (@g){
    printf("%s\n", $fn);
}

