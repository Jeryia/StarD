#!/bin/bash

# default settings
VERSION="0.3.6"
INSTALLDIR='/var'
STANDALONE=0



## main
# This is the main control flow for the program (script execution starts here)
# This calls the other functions in their needed run order.
function main {
	general_validation $@

	prep_starmade_tools

	echo 
	echo 
	echo 
	echo "####################################################################################"
	echo "Would you like to have this installer install packages for you using yum/apt-get?"
	echo "This may ask for your sudo password"
	echo "If you are not sure, please select type y"
	while [ "x$INSTALL_DEPS" != 'xy' ] && [ "x$INSTALL_DEPS" != 'xn' ]; do
		read -a INSTALL_DEPS -p "type y or n for yes or no: " -n 1 -r
		echo
	done
	echo
	if [ "x$INSTALL_DEPS" == 'xy' ]; then
		install_dependancies
	fi

	install_stard

	download_starmade

	start_stard

	if [ $STANDALONE -eq 0 ]; then
		validate_install
	fi
}

## on_die
# when killed perform these actions to cleanup
function on_die {
	trap "exit 0" SIGINT
	trap "exit 0" SIGTERM
	kill 0
	exit 0
}

## general validation
# Ensure everything we need to install stard is in place.
function general_validation {
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

	if [ ! -e ./StarMade-Starter.jar ]; then
		echo "Please download the StarMade-Starter.jar from http://www.starmade.org/download."
		echo "Then, place StarMafe-Starter.jar in the same directory you are running this script from and run it again"
		exit 1
	fi
}


## prep_starmade_tools
# Puts the starmade tools in place so stard knows where to find them
function prep_starmade_tools {
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
}





## install_dependancies
# installs all the needed dependancies to run stard and StarMade
function install_dependancies {
	apt_packages=""
	apt_cpan=""
	yum_packages=""
	dep_list=""

	## Get a list of what we need to install

	command -v java > /dev/null 2>&1
	RET=$?
	if [ $RET -ne 0 ]; then
		apt_packages="$apt_packages default-jre"
		yum_packages="$yum_packages java"
		dep_list="$dep_list java"
	fi

	command -v perl > /dev/null 2>&1
	RET=$?
	if [ $RET -ne 0 ]; then
		apt_packages="$apt_packages perl-base"
		yum_packages="$yum_packages perl"
		dep_list="$dep_list perl"
	fi
	
	command -v lsof > /dev/null 2>&1
	RET=$?
	if [ $RET -ne 0 ]; then
		apt_packages="$apt_packages lsof"
		yum_packages="$yum_packages lsof"
		dep_list="$dep_list lsof"
	fi
	
	command -v pkill > /dev/null 2>&1
	RET=$?
	if [ $RET -ne 0 ]; then
		apt_packages="$apt_packages procps"
		yum_packages="$yum_packages procps-ng"
		dep_list="$dep_list pkill"
	fi
		
	command -v sed > /dev/null 2>&1
	RET=$?
	if [ $RET -ne 0 ]; then
		apt_packages="$apt_packages sed"
		yum_packages="$yum_packages sed"
		dep_list="$dep_list sed"
	fi

	command -v rsync > /dev/null 2>&1
	RET=$?
	if [ $RET -ne 0 ]; then
		apt_packages="$apt_packages rsync"
		yum_packages="$yum_packages rsync"
		dep_list="$dep_list rsync"
	fi

	command -v make > /dev/null 2>&1
	RET=$?
	if [ $RET -ne 0 ]; then
		apt_packages="$apt_packages make"
		yum_packages="$yum_packages make"
		dep_list="$dep_list make"
	fi

	command -v wget > /dev/null 2>&1
	RET=$?
	if [ $RET -ne 0 ]; then
		apt_packages="$apt_packages wget"
		yum_packages="$yum_packages wget"
		dep_list="$dep_list wget"
	fi

	perl -e "use Config::IniFiles" > /dev/null 2>&1
	RET=$?
	if [ $RET -ne 0 ]; then
		apt_packages="$apt_packages libconfig-inifiles-perl"
		yum_packages="$yum_packages perl-Config-IniFiles"
		dep_list="$dep_list perl(Config::IniFiles)"
	fi

	perl -e "use Text::ParseWords" > /dev/null 2>&1
	RET=$?
	if [ $RET -ne 0 ]; then
		apt_packages="$apt_packages perl-modules"
		yum_packages="$yum_packages perl-Text-ParseWords"
		dep_list="$dep_list perl(Text::ParseWords)"
	fi

	perl -e "use File::Basename" > /dev/null 2>&1
	RET=$?
	if [ $RET -ne 0 ]; then
		yum_packages="$yum_packages perl-File-Basename"
		dep_list="$dep_list perl(File::Basename)"
	fi

	perl -e "use File::Path" > /dev/null 2>&1
	RET=$?
	if [ $RET -ne 0 ]; then
		yum_packages="$yum_packages perl-File-Path"
		dep_list="$dep_list perl(File::Path)"
	fi

	perl -e "use XML::Merge" > /dev/null 2>&1
	RET=$?
	if [ $RET -ne 0 ]; then
		apt_cpan="$apt_cpan XML::Merge"
		yum_packages="$yum_packages perl-XML-Merge"
		dep_list="$dep_list perl(XML::Merge)"
	fi

	perl -e "use XML::Parser" > /dev/null 2>&1
	RET=$?
	if [ $RET -ne 0 ]; then
		apt_packages="$apt_packages librpc-xml-perl"
		dep_list="$dep_list perl(XML::Parser)"
	fi

	perl -e "use Carp" > /dev/null 2>&1
	RET=$?
	if [ $RET -ne 0 ]; then
		yum_packages="$yum_packages perl-Carp"
		dep_list="$dep_list perl(Carp)"
	fi

	perl -e "use Cwd" > /dev/null 2>&1
	RET=$?
	if [ $RET -ne 0 ]; then
		yum_packages="$yum_packages perl-PathTools"
		dep_list="$dep_list perl(Cwd)"
	fi

	command -v python > /dev/null 2>&1
	RET=$?
	if [ $RET -ne 0 ]; then
		apt_packages="$apt_packages python-minimal"
		yum_packages="$yum_packages python"
		dep_list="$dep_list python"
	fi
		
	## Check to see if we need to do anything
	if [ "x$dep_list" == 'x' ]; then
		echo "All dependancies are already installed!"
		echo "Moving on..."
		return 0
	fi

	## Install Dependancies
	command -v apt-get > /dev/null 2>&1
	RET=$?
	if [ $RET -eq 0 ]; then
		dpkg -l coreutils > /dev/null 2>&1
		RET=$?
		if [ $RET -ne 0 ]; then
			apt_packages="$apt_packages coreutils"
		fi

		echo "Program wants to run: sudo apt-get install -y $apt_packages"
		sudo apt-get install -y $apt_packages
		echo "Program wants to run: cpan -i $apt_cpan"
		sudo cpan -i $apt_cpan
		return 0
	fi

	command -v yum > /dev/null 2>&1
	RET=$?
	if [ $RET -eq 0 ]; then
		rpm -q coreutils > /dev/null 2>&1
		RET=$?
		if [ $RET -ne 0 ]; then
			yum_packages="$yum_packages coreutils"
		fi

		echo "Program wants to run: sudo 'yum install -y epel-release"
		sudo yum install -y epel-release
		echo "Program wants to run: yum install -y $yum_packages"
		sudo yum install -y $yum_packages
		
		return 0
	fi

	echo 'Could not find a package manager that works with your system!'
	echo 'You need to find a way to install the following items:'
	for item in $dep_list; do
		echo $item
	done
}


## install_stard
# Do the compilation and install of stard
function install_stard {
	echo "Downloading Stard..."

	# download and compile
	TMP=`mktemp -d /tmp/stard-XXXXXX`
	cd $TMP
	rm -f StarD.tar.gz
	wget --no-check-certificate https://github.com/Jeryia/StarD/archive/$VERSION.tar.gz -O StarD-$VERSION.tar.gz || exit 1

	echo "Unpacking Stard..."
	tar -xzf StarD-$VERSION.tar.gz || exit 1
	cd StarD-$VERSION

	echo "Installing Stard..."
	./configure $CFGOPTS || exit 1
	make || exit 1

	## install stard
	if [ "$STANDALONE" -eq 0 ]; then
		echo "program wants to run 'make install'. If you are being asked for a password here, it's because it wants you to use your sudo password"
		sudo make install || exit 1
	else
		rsync -ar --exclude starmade/stard/stard-launcher.conf build/starmade "$INSTALLDIR/"
		cp -n build/starmade/stard/stard-launcher.conf "$INSTALLDIR/starmade/stard/"
		for plugin in ./src/stard/plugins.disabled/*; do 
			name=$(basename $plugin)
			test -d "$INSTALLDIR/starmade/stard/plugins/$name" && cp -R "$INSTALLDIR/starmade/stard/plugins.disabled/$name" "$INSTALLDIR/stard/plugins/"
			test -d "$INSTALLDIR/starmade/stard/plugins/$name" && rm -rf "$INSTALLDIR/starmade/stard/plugins.disabled/$name"
		done
	fi
	
	## install starmade
	cd $INSTALLDIR/starmade/
}




## download_starmade
# Download StarMade so we can actually, you know, run a StarMade server :D
function download_starmade {
	cd $INSTALLDIR/starmade/
	if [ "$STANDALONE" -eq 0 ]; then
		sudo su starmade -c $INSTALLDIR/starmade/stard/bin/download_starmade 
	else 
		$INSTALLDIR/starmade/stard/bin/download_starmade 
	fi
	cd -
	cd $INSTALLDIR/starmade/StarMade/
	timeout --foreground 10 java -jar StarMade.jar -server -port:0 > /dev/null 2>&1
	cd -
}


## start_stard
# Launch Stard itself, this will also cause StarMade to start up.
# Moment of truth!
function start_stard {
	## setup stard
	echo "running initial setup please wait..."

	## start stard
	if [ $STANDALONE -eq 0 ]; then
		systemctl daemon-reload 2>&1 > /dev/null ||:
		sleep 1
		sudo service stard start

		echo "Starmade server has started. Waiting a few to let it collect itself before we start poking it"
		sleep 30
	else
		$INSTALLDIR/starmade/stard/bin/stard-launcher
	fi
}


## validate_install
# Make sure things look sane for the stard/StarMade setup. Only runs in non 
# standalone, as standalone will have the launcher run directly on their screen. 
#
# Still leaving code for standalone to work though, as I would like to validate 
# the server there as well. Must give this more thought...
function validate_install {

	## validate stard
	echo "Checking to see if stard is healthy"
	if [ $STANDALONE -eq 0 ]; then
		sudo systemctl status stard --no-pager
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
		echo "To set it to run at boot, run the command sudo systemctl enable stard"
	fi
}

trap on_die SIGINT
trap on_die SIGTERM

main $@
exit 0
