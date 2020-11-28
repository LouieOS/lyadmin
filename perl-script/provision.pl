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

my $GIT_REPO = 'https://git.lain.church/gashapwn/lyadmin.git';
my ($REPO_DIR) = $GIT_REPO =~ /\/([^\/]*)\.git$/;

my $pwuid;
my $admin_un;

my $admin_home_dir;

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

$admin_home_dir = "/home/$admin_un";

# grant doas access to admin user
system("echo 'permit $admin_un' > /etc/doas.conf");

# install git
system("pkg_add git");
system("pkg_add python3");
chdir $admin_home_dir;
system("su gashapwn -c 'git clone $GIT_REPO'");
chdir $REPO_DIR;
system("su gashapwn -c 'python3 -m venv venv'");
# system("su gashapwn -c '. ./venv/bin/activate && pip3 install -r ");

