#!/usr/bin/perl

use warnings;
use strict;

my $WORKING_DIR = "/home/gashapwn/lyadmin/";
my $ACCOUNT_DIR = "test/";

my $FULL_PATH = "$WORKING_DIR$ACCOUNT_DIR";

my $SHELL_ENUM = {
    "SHELL_BASH" => "/usr/local/bin/bash",
    "SHELL_KSH" => "/bin/ksh"
};

my @g;

sub fun1($){
    my $id = $_[0];
    
    my $fn1 = $FULL_PATH.$id.".ident";
    my $fn2 = $FULL_PATH.$id.".pub";

    my $username;
    my $shell_pref;
    my $user_email;

    open FILE, $fn1 or die "could not open file";
    $username = <FILE>;
    chomp $username;
    
    $user_email = <FILE>;
    chomp $user_email;
    
    {
	my $shell_var = <FILE>;
	chomp $shell_var;
	$shell_pref = $SHELL_ENUM->{$shell_var};
    }

    # printf("checking username %s\n", $username);
    if(length($username) > 31 || !($username =~ /^[A-Za-z][A-Za-z0-9]+$/)){
	printf("%s has an INVALID username\n", $id);
	die ("oh no");
    }

    {
	my $cmd;
	$cmd = "useradd -m -s " . $shell_pref . " " . $username; 
	printf("Y/N is this command OK?: %s\n", $cmd);
	
	if(<STDIN> ne "Y\n"){
	    die "invalid characters?!!";
	}
	
	system($cmd);
	#system("mkdir /home/$username/.ssh");
	system("chmod 700 /home/$username/.ssh");
	system("mv $FULL_PATH/$id.pub /home/$username/.ssh/authorized_keys");
	system("chmod 600 /home/$username/.ssh/authorized_keys");
	system("chown $username:$username /home/$username/.ssh");
	system("chown $username:$username /home/$username/.ssh/authorized_keys");
	system("rm $FULL_PATH/$id.ident");
    }
    close FILE;
}

fun1("00004");

die "test 0";

@g = glob("$FULL_PATH*");
@g = map { s/.*\/([^\/]*).pub$/$1/; $_ } grep {$_ =~ /pub$/} @g;

for my $fn (@g){
    printf("%s\n", $fn);
}

