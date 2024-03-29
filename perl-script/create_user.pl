#!/usr/bin/perl

use warnings;
use strict;
use JSON;

# create-user.pl
#
# processes new user request files

my $working_dir = "./";
my $account_dir = $working_dir."req/";

my $conf_path = $working_dir."lyadmin.conf.json";
my $ul_path = $working_dir."user_list.txt";
my $SHELL_ENUM;

my @g;

# Given a username... prompts and creates that user
sub create($){
    my $id = $_[0];
    
    my $fn1 = $account_dir.$id.".ident";

    my $username;
    my $shell_pref;
    my $user_email;
    my $pub_key;

    # read in username and validate
    open FILE, $fn1 or die "could not open file $fn1";
    $username = <FILE>;
    chomp $username;
    
    if(length($username) > 31 || !($username =~ /^[A-Za-z][A-Za-z0-9]+$/)){
	printf("%s has an INVALID username\n", $id);
	die ("oh no");
    }

    # read in email
    $user_email = <FILE>;
    chomp $user_email;

    # read in shell and validate
    {
	my $s0 = <FILE>;
	chomp $s0;
	unless($SHELL_ENUM->{$s0}){
	    die "invalid shell setting $s0 in file $id.ident";
	}
	$shell_pref = $SHELL_ENUM->{$s0};
    }

    # read in pub key
    $pub_key = <FILE>;
    chomp $pub_key;

    {
	# Prompt to make sure the username looks OK
	my $cmd;
	$cmd = "useradd -m -s " . $shell_pref . " " . $username; 
	printf("Y/N is this command OK?: %s\n", $cmd);
	
	if(!(<STDIN> =~ /^y/i)){
	    die "invalid characters?!!";
	}

	# create the user
	system($cmd);
	system("echo '".$pub_key."' > /home/$username/.ssh/authorized_keys");
	system("chmod 711 /home/$username");
	system("mv $fn1 $fn1.done");
	system("echo $username >> $ul_path");
    }
    close FILE;
}

# MAIN starts here

# Checks if user is root
if(!(`id` =~ /uid=0/)){
    die "please run this script as root";
}

# Adjusts the relative file paths based on where
# the script runs from
if( `pwd` =~ /perl-script\/?\s*$/){
    $working_dir = "../";
    $account_dir = $working_dir."req/";
    $conf_path = $working_dir."lyadmin.conf.json";
    $ul_path = $working_dir."user_list.txt";
    printf("%s\n", $conf_path);
}elsif(!(join(" ", glob("./*")) =~ /perl-script/)){
    die "please run this script with ./perl-script/ as the present working directory";
}

# Opens the conf file to read
# shell enums
open FILE, $conf_path or die "could not open file $conf_path";
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

# Saves all new user requests to an array
@g = glob("$account_dir*");
@g = map { s/.*\/([^\/]*).ident$/$1/; $_ } grep {$_ =~ /ident$/} @g;

# Iterate and create the users
for my $fn (@g){
    create($fn);
}

