#!/bin/bash
debInst() {
    dpkg-query -Wf'${db:Status-abbrev}' "$1" 2>/dev/null | grep -q '^i'
}


# REMOVE PACKAGES NOT NEEDED

# GUI-related packages
pkgs="
xserver-xorg-video-fbdev
xserver-xorg xinit
gstreamer1.0-x gstreamer1.0-omx gstreamer1.0-plugins-base
gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-alsa
gstreamer1.0-libav
epiphany-browser
lxde lxtask menu-xdg gksu
xserver-xorg-video-fbturbo
xpdf gtk2-engines alsa-utils
netsurf-gtk zenity
desktop-base lxpolkit
weston
omxplayer
raspberrypi-artwork
lightdm gnome-themes-standard-data gnome-icon-theme
qt50-snapshot qt50-quick-particle-examples
"
 
# Edu-related packages
pkgs="$pkgs
idle python3-pygame python-pygame python-tk
idle3 python3-tk
python3-rpi.gpio
python-serial python3-serial
python-picamera python3-picamera
debian-reference-en dillo x2x
scratch nuscratch
raspberrypi-ui-mods
timidity
smartsim penguinspuzzle
pistore
sonic-pi
python3-numpy
python3-pifacecommon python3-pifacedigitalio python3-pifacedigital-scratch-handler python-pifacecommon python-pifacedigitalio
oracle-java8-jdk
minecraft-pi python-minecraftpi
wolfram-engine
"
 
# Remove packages
for pkg in $pkgs; do
	if debInst "$pkg"; then
	    apt-get -y remove --purge $pkg
	fi	
done















# INSTALL MOSQUITTO-CLIENTS
if [ -f /etc/apt/sources.list.d/mosquitto-repo.list ]; then
	echo "mosquitto-repo is installed"
else
	echo "Installing mosquitto-repo repository"
    curl -O http://repo.mosquitto.org/debian/mosquitto-repo.gpg.key
	sudo apt-key add mosquitto-repo.gpg.key
	rm mosquitto-repo.gpg.key

	curl -O http://repo.mosquitto.org/debian/mosquitto-repo.list
	mv mosquitto-repo.list /etc/apt/sources.list.d/

	apt-get update
fi
pkg="mosquitto-clients"
if debInst "$pkg"; then
    echo "$pkg package is installed"
else
    echo "Installing $pkg"
    apt-get -y install $pkg
fi





# INSTALL FAIL2BAN AND CONFIGURE
pkg="fail2ban"
if debInst "$pkg"; then
    echo "$pkg package is installed"
else
    echo "Installing $pkg"
    apt-get -y install $pkg

	echo "" >> /etc/fail2ban/jail.conf
	echo "# notify mqtt broker" >> /etc/fail2ban/jail.conf
	echo "[ssh-mosquitto]" >> /etc/fail2ban/jail.conf
	echo "enabled  = true" >> /etc/fail2ban/jail.conf
	echo "filter   = sshd" >> /etc/fail2ban/jail.conf
	echo "action   = mosquitto[name=ssh]" >> /etc/fail2ban/jail.conf
	echo "logpath  = /var/log/auth.log" >> /etc/fail2ban/jail.conf

	mv fail2ban-mosquitto.conf /etc/fail2ban/action.d/mosquitto.conf
	sed -e '/ignoreip/{:a;n;/^$/!ba;i\ignoreip = 127.0.0.1/8 10.0.0.0/8 192.168.0.0/16 172.16.0.0/16' -e '}' /etc/fail2ban/jail.conf > ~/jail.conf
	mv -f ~/jail.conf /etc/fail2ban/jail.conf
	chown root:root /etc/fail2ban/jail.conf

	service fail2ban restart
fi





# INSTALL VIM
pkg="vim"
if debInst "$pkg"; then
    echo "$pkg package is installed"
else
    echo "Installing $pkg"
    apt-get -y install $pkg
fi



# INSTALL OPENVPN AND CONFIGURE
pkg="openvpn"
if debInst "$pkg"; then
    echo "$pkg package is installed"
else
    echo "Installing $pkg"
    apt-get -y install $pkg
fi




# INSTALL OPENVPN AND CONFIGURE
pkg="ntp"
if debInst "$pkg"; then
    echo "$pkg package is installed"
else
	echo "Installing $pkg"
    apt-get -y install $pkg

    sed -e '/#server/{:a;n;/^$/!ba;i\server time.moranit.com' -e '}' /etc/ntp.conf > ~/ntp.conf
    mv -f ~/ntp.conf /etc/ntp.conf 
    chown root:root /etc/ntp.conf
fi



# INSTALL DDCLIENT FOR CLOUDFLARE
if [ ! -f /usr/sbin/ddclient ]; then
	wget https://github.com/danielheth/ddclient-for-cloudflare/archive/master.zip
	unzip master.zip
	cd ddclient-for-cloudflare-master/

	echo "Installing ddclient for cloudflare"
	read -p "What zone is this system a part of (domain name listed on cloudflare)? " zone
	read -p "What is your cloudflare username? " login
	read -p "What is your cloudflare API key (look under account settings)? " password
	read -p "What is the fully qualified (hostname.$zone) for this device? " fqdn

	echo "Installing Pre-reqs"
	apt-get install perl libjson-any-perl libio-socket-ssl-perl -y

	echo "Installing ddclient"
	cp etc_rc.d_init.d_ddclient.ubuntu /etc/init.d/ddclient
	chmod +x /etc/init.d/ddclient
	cp ddclient /usr/sbin/
	mkdir /var/cache/ddclient

	echo "Configuring ddclient"
	mkdir /etc/ddclient
	cp ddclient.conf /etc/ddclient/ddclient.conf
	echo "zone=$zone," >> /etc/ddclient/ddclient.conf
	echo "login=$login," >> /etc/ddclient/ddclient.conf
	echo "password=$password" >> /etc/ddclient/ddclient.conf
	echo "$fqdn," >> /etc/ddclient/ddclient.conf

	echo "Adding to Startup"
	update-rc.d ddclient defaults

	echo "Starting ddclient"
	service ddclient Starting

	cd ..
fi








# ADD MY PPA
if [ -f /etc/apt/sources.list.d/danielheth-hethio-trusty.list ]; then
	echo "danielheth-hethio-trusty repository is installed"
else
	echo "Installing danielheth-hethio-trusty repository"
    # for Raspberry Pi's...
	if [ -f /etc/init.d/raspi-config ]; then
		apt-get install python-software-properties -y
		add-apt-repository -y ppa:danielheth/hethio
		rm /etc/apt/sources.list.d/danielheth-hethio-wheezy.list

		echo "deb http://ppa.launchpad.net/danielheth/hethio/ubuntu trusty main" > /etc/apt/sources.list.d/danielheth-hethio-trusty.list
		echo "deb-src http://ppa.launchpad.net/danielheth/hethio/ubuntu trusty main" >> /etc/apt/sources.list.d/danielheth-hethio-trusty.list

	# for Pi's and Ubuntu
	else
		add-apt-repository -y ppa:danielheth/hethio

	fi

	apt-get update
fi






# Remove automatically installed dependency packages
echo apt-get -y autoremove