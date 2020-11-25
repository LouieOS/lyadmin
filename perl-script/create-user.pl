#!/usr/bin/perl

use warnings;
use strict;

my $WORKING_DIR = "/home/gashapwn/lyadmin/";
my $ACCOUNT_DIR = "test/";

my $FULL_PATH = "$WORKING_DIR$ACCOUNT_DIR";

my $SHELL_ENUM = {
    "SHELL_BASH" => "/bin/bash",
    "SHELL_KSH" => "/bin/ksh"
};

my @g;

sub fun1($){
    my $id = $_[0];
    
    my $fn1 = $FULL_PATH.$id.".ident";
    my $fn2 = $FULL_PATH.$id.".pub";

    my $username;
    # my $displayname;
    # my $name_pref;
    my $shell_pref;
    my $user_email;

    open FILE, $fn1 or die "could not open file";
    $username = <FILE>;
    chomp $username;
    
    # $displayname = <FILE>;
    # chomp $displayname;

    # # Save this for later
    # $name_pref = <FILE>;
    # chomp $name_pref;

    $user_email = <FILE>;
    chomp $user_email;
    
    {
	my $shell_var = <FILE>;
	chomp $shell_var;
	# printf("\$shell_var: %s\n", $shell_var);
	$shell_pref = $SHELL_ENUM->{$shell_var};
    }

    printf("checking username %s\n", $username);
    if(length($username) > 31 || !($username =~ /^[A-Za-z][A-Za-z0-9]+$/)){
	printf("%s has an INVALID username\n", $id);
	die ("oh no");
    }

    # if(length($displayname) > 31 || $displayname =~ /^[A-Za-z0-9]+$/){
    # 	printf("%s has an INVALID username\n", $id);
    # }
    
    {
	my $cmd;
	$cmd = "useradd -m -s $shell_pref $username";
	printf("gonna run this command: %s\n", $cmd);
    }
    close FILE;
}

fun1("00000");

die "test 0";

@g = glob("$FULL_PATH*");
@g = map { s/.*\/([^\/]*).pub$/$1/; $_ } grep {$_ =~ /pub$/} @g;

for my $fn (@g){
    printf("%s\n", $fn);
}

