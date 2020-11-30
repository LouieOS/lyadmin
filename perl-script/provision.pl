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
my $INST_DIR = "/tilde";

my $SVC_ACCT = "_lingyind";

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

# Setup install dir
system("mkdir $INST_DIR");
system("useradd -d $INST_DIR -r 100..900 $SVC_ACCT");
system("chown $SVC_ACCT:$SVC_ACCT $INST_DIR");
chdir $INST_DIR;

# clone repo
system("su $SVC_ACCT -c 'git clone $GIT_REPO'");
chdir $REPO_DIR;

# Copy the skel directory
system("mkdir ./skel/public_html/cgi");
system("cp -r ./skel/* /etc/skel/");

# setup admin user
system("cp -r ./skel/* /home/$admin_un/");
system("chown -R $admin_un:$admin_un /home/$admin_un");
system("echo $admin_un >> ./user_list.txt");

# Setup the virtual environment
system("pkg_add python3");
printf("generating virtual enviornment...\n");
system("su $SVC_ACCT -c 'python3 -m venv venv'");
system("su $SVC_ACCT -c '. ./venv/bin/activate && pip3 install -r requirements.txt'");

system("pkg_add p5-JSON");

# Install apache
system("pkg_add apache-httpd");
printf("configuring apache\n");
# enable the userdir module
system("sed -i -e 's/^\\(.\\)*#\\(LoadModule userdir_module\\)/\\1\\2/' /etc/apache2/httpd2.conf");
system("sed -i -e 's/^\\(.\\)*#\\(Include \\/etc\\/apache2\\/extra\\/httpd-userdir.conf\\)/\\1\\2/' /etc/apache2/httpd2.conf");
# Enable the CGI directory
system("echo '<Directory \"/home/*/public_html/cgi/\">
    Require all granted
    Options +ExecCGI
    AddHandler cgi-script .cgi
</Directory>' >> /etc/apache2/extra/httpd-userdir.conf");
# Enable the CGI modules
system("sed -i -e 's/^\\(.\\)*#\\(LoadModule cgi_module\\)/\\1\\2/' /etc/apache2/httpd2.conf");
system("sed -i -e 's/^\\(.\\)*#\\(LoadModule cgid_module\\)/\\1\\2/' /etc/apache2/httpd2.conf");
# Disable directory listing
system("sed -i -e 's/\\(<\\/Directory>\\)/    Options -Indexes\\
       \\1/g' /etc/apache2/extra/httpd-userdir.conf");

# Change the port to 5001
system("sed -i -e 's/^\\(.\\)*Listen *80/\\1Listen 5001/' /etc/apache2/httpd2.conf");
# rev up those apache processes!
system("rcctl start apache2");


# Install and config haproxy
system("pkg_add haproxy");

printf("configuring haproxy\n");
system("cp ./perl-script/conf/haproxy.cfg /etc/haproxy/haproxy.cfg");
system("rcctl start haproxy");

printf("dont forget to setup your ssh pub key at /home/$admin_un/.ssh/authorized_keys\n");
