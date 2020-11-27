#!/usr/bin/perl

use warnings;
use strict;
use JSON;

my $WORKING_DIR = "/home/gashapwn/lyadmin/";
my $ACCOUNT_DIR = "test/";

my $FULL_PATH = "$WORKING_DIR$ACCOUNT_DIR";
my $CONF_PATH = $WORKING_DIR."lyadmin.conf.json";
my $SHELL_ENUM;

open FILE, $CONF_PATH or die "could not open file $CONF_PATH";
{
    my $conf_str;
    my $conf_obj;
    local $/=undef;
    $conf_str = <FILE>;
    chomp $conf_str;
    $conf_obj = decode_json($conf_str);
    $SHELL_ENUM = $conf_obj->{"shell"};
};
close FILE;

my @g;

sub create($){
    my $id = $_[0];
    
    my $fn1 = $FULL_PATH.$id.".ident";

    my $username;
    my $shell_pref;
    my $user_email;
    my $pub_key;

    open FILE, $fn1 or die "could not open file $fn1";
    $username = <FILE>;
    chomp $username;

    $user_email = <FILE>;
    chomp $user_email;
    
    {
	my $s0 = <FILE>;
	chomp $s0;
	unless($SHELL_ENUM->{$s0}){
	    die "invalid shell setting $s0 in file $id.ident";
	}
	$shell_pref = $SHELL_ENUM->{$s0};
    }

    $pub_key = <FILE>;
    chomp $pub_key;

    if(length($username) > 31 || !($username =~ /^[A-Za-z][A-Za-z0-9]+$/)){
	printf("%s has an INVALID username\n", $id);
	die ("oh no");
    }

    {
	my $cmd;
	$cmd = "useradd -m -s " . $shell_pref . " " . $username; 
	printf("Y/N is this command OK?: %s\n", $cmd);
	
	if(!(<STDIN> =~ /^y/i)){
	    die "invalid characters?!!";
	}
	
	system($cmd);
	system("echo '$pub_key' > /home/$username/.ssh/authorized_keys");
	system("chmod 711 /home/$username");
	system("mv $fn1 $fn1.done");
	system("echo $username >> user_list.txt");
    }
    close FILE;
}

@g = glob("$FULL_PATH*");
@g = map { s/.*\/([^\/]*).ident$/$1/; $_ } grep {$_ =~ /ident$/} @g;

for my $fn (@g){
    create($fn);
}

