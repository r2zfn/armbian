#!/bin/bash

# Check that the network is UP and die if its not
if [ "$(expr length `hostname -I | cut -d' ' -f1`x)" == "1" ]; then
    exit 0
fi

# Get the Distr Version
distrCurVersion=$(awk -F "= " '/Version/ {print $2}' /etc/armbian-release) > /dev/null 2<&1

DMRIDFILE=/usr/local/etc/DMRIds.dat
#QRAIDFILE=/usr/local/etc/dmrids.dat
XLXHOSTS=/usr/local/etc/XLXHosts.txt
TGLISTBM=/usr/local/etc/TGList_BM.txt
LIB=/lib/systemd/system/
BIN=/usr/local/bin/
SBIN=/usr/local/sbin/
ETC=/etc/
SETC=/usr/local/etc/
GITURL=https://github.com/g4klx/
RGITURL=https://raw.githubusercontent.com/g4klx/
KROTURL=https://raw.githubusercontent.com/krot4u/Public_scripts/master/
PIURL=http://www.pistar.uk/downloads/
MURL=https://raw.githubusercontent.com/r2zfn/armbian/main/




# Check we are root
if [ "$(id -u)" != "0" ];then
    echo "This script must be run as root" 1>&2
    exit 1
fi

#apt update && apt upgrade

apt-get install -y git nano build-essential cmake automake > /dev/null 2<&1
apt-get install -y libsamplerate0-dev > /dev/null 2<&1
chmod ugo+w /opt/ > /dev/null 2<&1
cd /opt/ > /dev/null 2<&1
echo "Git clone MMDVMHost"
git clone ${GITURL}MMDVMHost.git > /dev/null 2<&1
echo "Git clone MMDVMCal"
git clone ${GITURL}MMDVMCal.git > /dev/null 2<&1
echo "Git clone DMRGateway"
git clone ${GITURL}DMRGateway.git > /dev/null 2<&1
apt-get install lighttpd > /dev/null 2<&1
groupadd www-data > /dev/null 2<&1
usermod -G www-data -a mmdvm > /dev/null 2<&1
usermod -G www-data -a root > /dev/null 2<&1
apt-get install php7.4-common php7.4-cgi php > /dev/null 2<&1
echo "Git clone MMDVMHost-Dashboard"
git clone https://github.com/dg9vh/MMDVMHost-Dashboard.git > /dev/null 2<&1
cp -R -f /opt/MMDVMHost-Dashboard/* /var/www/html/ > /dev/null 2<&1
chown -R www-data:www-data /var/www/html > /dev/null 2<&1
chmod -R 775 /var/www/html > /dev/null 2<&1
rm -f /var/www/html/index.lighttpd.html > /dev/null 2<&1
lighty-enable-mod fastcgi > /dev/null 2<&1
lighty-enable-mod fastcgi-php > /dev/null 2<&1
service lighttpd force-reload > /dev/null 2<&1
cd /opt/MMDVMHost > /dev/null 2<&1
echo "Make MMDVMHost"
git pull > /dev/null 2<&1
make > /dev/null 2<&1
cd /opt/MMDVMCal > /dev/null 2<&1
echo "Make MMDVMCal"
git pull > /dev/null 2<&1
make > /dev/null 2<&1
cd /opt/DMRGateway > /dev/null 2<&1
echo "Make DMRGateway"
git pull > /dev/null 2<&1
make > /dev/null 2<&1
echo "Downloading Service Files..."
cp -F /opt/DMRGateway/DMRGateway ${BIN} > /dev/null 2<&1
cp -F /opt/DMRGateway/DMRGateway.ini ${SETC}dmrgateway > /dev/null 2<&1
cp -F /opt/MMDVMCal/MMDVMCal ${BIN} > /dev/null 2<&1
cp -F /opt/MMDVMHost/MMDVMHost ${BIN} > /dev/null 2<&1
cp -F /opt/MMDVMHost/MMDVM.ini ${SETC}mmdvmhost > /dev/null 2<&1
cp -F /opt/MMDVMHost/RemoteCommand ${BIN} > /dev/null 2<&1
chmod -R 775 /usr/local/bin > /dev/null 2<&1

echo "Downloading Start Service Files..."
curl --fail -o ${SBIN}dmrgateway.service -s ${MURL}sbin/dmrgateway.service > /dev/null 2<&1
curl --fail -o ${SBIN}mmdvmhost.service -s ${MURL}sbin/mmdvmhost.service > /dev/null 2<&1
curl --fail -o ${SBIN}update.sh -s ${MURL}update.sh > /dev/null 2<&1
chmod -R 775 /usr/local/sbin > /dev/null 2<&1

echo "Downloading Service Files..."
curl --fail -o ${LIB}dmrgateway.service -s ${MURL}system/dmrgateway.service > /dev/null 2<&1
curl --fail -o ${LIB}dmrgateway.timer -s ${MURL}system/dmrgateway.timer > /dev/null 2<&1
curl --fail -o ${LIB}mmdvmhost.service -s ${MURL}system/mmdvmhost.service > /dev/null 2<&1
curl --fail -o ${LIB}mmdvmhost.timer -s ${MURL}system/mmdvmhost.timer > /dev/null 2<&1

echo "Enable Service and Reload"
systemctl enable dmrgateway.service > /dev/null 2<&1
systemctl enable dmrgateway.timer > /dev/null 2<&1
systemctl enable mmdvmhost.service > /dev/null 2<&1
systemctl enable mmdvmhost.timer > /dev/null 2<&1
systemctl daemon-reload > /dev/null 2<&1


echo "Downloading Etc Files..."
curl --fail -o ${SETC}RSSI.dat -s ${MURL}etc/RSSI.dat > /dev/null 2<&1
curl --fail -o ${SETC}dmrgateway -s ${MURL}etc/dmrgateway > /dev/null 2<&1
curl --fail -o ${SETC}mmdvmhost -s ${MURL}etc/mmdvmhost > /dev/null 2<&1




echo "Downloading DMRIds.dat Files..."
curl --fail -o ${DMRIDFILE} -s ${PIURL}DMRIds.dat > /dev/null 2<&1

# Add QRA DMRID database
echo "Downloading DMRIdsQRA.dat Files..."
curl --fail -o /tmp/DMRIdsQRA.dat -s "${KROTURL}master/DMRIds.dat" > /dev/null 2<&1
cat /tmp/DMRIdsQRA.dat >> ${DMRIDFILE} > /dev/null 2<&1

echo "Downloading DMR_Hosts.txt Files..."
curl --fail -o ${DMRHOSTS} -s ${PIURL}DMR_Hosts.txt > /dev/null 2<&1

echo "Downloading XLXHosts.txt Files..."
curl --fail -o ${XLXHOSTS} -s ${PIURL}XLXHosts.txt > /dev/null 2<&1


if [ ! -f /root/XLXHosts.txt ]; then
touch /root/XLXHosts.txt > /dev/null 2<&1
fi

# Add custom XLX Hosts
if [ -f "/root/XLXHosts.txt" ]; then
cat /root/XLXHosts.txt >> ${XLXHOSTS} > /dev/null 2<&1
fi

echo "Downloading TGList_BM.txt Files..."
curl --fail -o ${TGLISTBM} -s ${PIURL}TGList_BM.txt > /dev/null 2<&1



    # Download the correct DMR Audio Files
    if [[ ! -d ${SETC}DMR_Audio ]]; then
	echo "Downloading DMR Voice Files..."
	mkdir ${SETC}DMR_Audio > /dev/null 2<&1
	curl --fail -o ${SETC}DMR_Audio/en_US.ambe -s ${RGITURL}DMRGateway/master/Audio/en_US.ambe > /dev/null 2<&1
	curl --fail -o ${SETC}DMR_Audio/en_US.indx -s ${RGITURL}DMRGateway/master/Audio/en_US.indx > /dev/null 2<&1
    fi


exit 0
