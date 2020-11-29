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
chdir $admin_home_dir;
# clone repo
system("su $admin_un -c 'git clone $GIT_REPO'");
chdir $REPO_DIR;

# Copy the skel directory
system("mkdir ./skel/public_html/cgi");
system("cp -r ./skel/* /etc/skel/");

# Setup the virtual environment
system("pkg_add python3");
printf("generating virutal enviornment...\n");
system("su $admin_un -c 'python3 -m venv venv'");
system("su $admin_un -c '. ./venv/bin/activate && pip3 install -r requirements.txt'");

system("pkg_add p5-JSON");

# Install apache
system("pkg_add apache-httpd");

# enable the userdir module
system("sed -i -e 's/^\(.\)*#\(LoadModule userdir_module\)/\1\2/' /etc/apache2/httpd2.conf");
system("sed -i -e 's/^\(.\)*#\(Include \/etc\/apache2\/extra\/httpd-userdir.conf\)/\1\2/' /etc/apache2/httpd2.conf");
# Enable the CGI directory
system("echo '<Directory \"/home/*/public_html/cgi/\">
    Require all granted
    Options +ExecCGI
    AddHandler cgi-script .cgi
</Directory>' >> /etc/apache2/extra/httpd-userdir.conf");
# Enable the CGI modules
system("sed -i -e 's/^\(.\)*#\(LoadModule cgi_module\)/\1\2/' /etc/apache2/httpd2.conf");
system("sed -i -e 's/^\(.\)*#\(LoadModule cgid_module\)/\1\2/' /etc/apache2/httpd2.conf");
# Disable directory listing
system("sed -i -e 's/\(<\/Directory>\)/    Options -Indexes\
       \1/g' /etc/apache2/extra/httpd-userdir.conf");

# Change the port to 5001
system("sed -i -e 's/^\(.\)*Listen *80/\1Listen 5001/' /etc/apache2/httpd2.conf");
