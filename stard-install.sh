#!/bin/bash


INSTALLDIR='/var'
STANDALONE=0

if [ "x$1" != "x" ]; then
	if [ "$1" == "standalone" ]; then
		STANDALONE=1;
		CFGOPTS="--standalone"
		INSTALLDIR=`pwd`
		echo "Installing Standalone version in $INSTALLDIR"
	else
		echo "$1 is not a valid option"
		echo "usage $0 [options]"
		echo 
		echo "Options:"
		echo "standalone - setup to run as current user, and to run from the current directory only, nothing else will be setup"
		exit 1
	fi
fi
echo "INSTALLDIR: $INSTALLDIR"

if [ ! -e ./StarMade-Starter.jar ]; then
	echo "Please download the StarMade-Starter.jar from http://www.starmade.org/download."
	echo "Then, place StarMafe-Starter.jar in the same directory you are running this script from and run it again"
	exit 1
fi

if [ $STANDALONE -eq 0 ]; then
	/etc/init.d/stard stop

	echo "Program wants to run 'mkdir -p $INSTALLDIR/starmade/tools'."
	echo "If you are being asked for a password here, it's because it wants you to use your sudo password"
	sudo mkdir -p $INSTALLDIR/starmade/tools
	echo "Program wants to run 'sudo cp -f ./StarMade-Starter.jar $INSTALLDIR/starmade/tools/'."
	echo "If you are being asked for a password here, it's because it wants you to use your sudo password"
	sudo cp -f ./StarMade-Starter.jar $INSTALLDIR/starmade/tools/ || exit 1
	chmod 644 $INSTALLDIR/starmade/tools/*
else 
	mkdir -p $INSTALLDIR/starmade/tools
	cp -f ./StarMade-Starter.jar $INSTALLDIR/starmade/tools/ || exit 1
fi

## install dependancies

echo "Would you like to have this installer install packages for you using yum/apt-get?"
echo "This may ask for your sudo password"
echo "If you are not sure, please select type y"
read -a INSTALL_DEPS -p "type y or n for yes or no: " -n 1 -r
echo
if [ "x$INSTALL_DEPS" == 'xy' ]; then
	command -v yum
	RET=$?
	if [ $RET -eq 0 ]; then
		echo "Program wants to run 'yum install -y epel-release'."
		echo "If you are being asked for a password here, it's because it wants you to use your sudo password"
		sudo yum install -y epel-release
		echo "Program wants to run 'yum install -y java perl perl-Carp perl-File-Path perl-File-Basename perl-Text-ParseWords perl-Config-IniFiles perl-Proc-Daemon perl-PathTools procps-ng sed coreutils rsync make wget'."
		echo "If you are being asked for a password here, it's because it wants you to use your sudo password"
		sudo yum install -y java perl perl-Carp perl-File-Path perl-File-Basename perl-Text-ParseWords perl-Config-IniFiles perl-Proc-Daemon perl-PathTools procps-ng sed coreutils rsync make wget 
	fi

	command -v apt-get
	RET=$?
	if [ $RET -eq 0 ]; then
		sudo apt-get install -y default-jre perl-base perl-modules procps coreutils sed rsync make wget libconfig-inifiles-perl libproc-daemon-perl python-minimal 
	fi
fi

# download and compile
TMP=`mktemp -d /tmp/stard-XXXXXX`
cd $TMP
rm -f stard.tar.gz
wget https://github.com/Jeryia/StarD/releases/download/0.0.10/stard.tar.gz || exit 1
tar -xzvf stard.tar.gz || exit 1
DIR=`ls -d stard-* | sort -V | tail -n 1`
cd $DIR
./configure $CFGOPTS || exit 1
make || exit 1

## install stard
if [ "$STANDALONE" -eq 0 ]; then
	echo "program wants to run 'make install'. If you are being asked for a password here, it's because it wants you to use your sudo password"
	sudo make install || exit 1
else
	cp -ar build/starmade $INSTALLDIR
fi

## install starmade
cd $INSTALLDIR/starmade/


if [ "$STANDALONE" -eq 0 ]; then
	sudo su starmade -c $INSTALLDIR/starmade/stard/bin/download_starmade
else 
	$INSTALLDIR/starmade/stard/bin/download_starmade
fi
	

## setup stard
echo "running initial setup please wait..."

## start stard
if [ $STANDALONE -eq 0 ]; then
	sudo service stard start
else
	nohup $INSTALLDIR/starmade/stard/bin/stard-launcher > $INSTALLDIR/starmade/stard/log/stard-launcher.out &
fi



echo "Starmade server has started. Waiting a few to let it collect itself before we start poking it"
sleep 20



## validate stard
echo "Checking to see if stard is healthy"
if [ $STANDALONE -eq 0 ]; then
	sudo service stard status
fi


if [ $STANDALONE -eq 0 ]; then
	sudo su starmade -c $INSTALLDIR/starmade/stard/bin/stard_test || exit 1
else
	$INSTALLDIR/starmade/stard/bin/stard_test || exit 1
fi


echo "StarD has been successfully installed."
echo "The server is currently running, and accessible. Be sure to check your firewall settings to ensure it is not blocking starmade"

if [ $STANDALONE -eq 1 ]; then
	echo 
	echo "Though stard is running, it is doing so in the background, and will stop running when the system is rebooted."
	echo "to start it again run $INSTALLDIR/starmade/stard/bin/stard-launcher"
else
	echo 
	echo "Though stard is running, it is not set to start on boot."
	echo "To set it to run at boot, run the command sudo chkconfig stard on"
fi
