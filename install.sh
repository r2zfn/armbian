#!/bin/bash

# Check that the network is UP and die if its not
if [ "$(expr length `hostname -I | cut -d' ' -f1`x)" == "1" ]; then
	exit 0
fi

# Get the Pi-Star Version
pistarCurVersion=$(awk -F "= " '/Version/ {print $2}' /etc/armbian-release)

DMRIDFILE=/usr/local/etc/DMRIds.dat
#QRAIDFILE=/usr/local/etc/dmrids.dat
XLXHOSTS=/usr/local/etc/XLXHosts.txt
TGLISTBM=/usr/local/etc/TGList_BM.txt

# How many backups
FILEBACKUP=1

# Check we are root
if [ "$(id -u)" != "0" ];then
	echo "This script must be run as root" 1>&2
	exit 1
fi

# Create backup of old files
if [ ${FILEBACKUP} -ne 0 ]; then
	cp ${DMRIDFILE} ${DMRIDFILE}.$(date +%Y%m%d)
	cp ${XLXHOSTS} ${XLXHOSTS}.$(date +%Y%m%d)
	cp ${TGLISTBM} ${TGLISTBM}.$(date +%Y%m%d)
fi

# Prune backups
FILES="${DMRIDFILE}
${QRAIDFILE}
${XLXHOSTS}
${TGLISTBM}"

for file in ${FILES}
do
  BACKUPCOUNT=$(ls ${file}.* | wc -l)
  BACKUPSTODELETE=$(expr ${BACKUPCOUNT} - ${FILEBACKUP})
  if [ ${BACKUPCOUNT} -gt ${FILEBACKUP} ]; then
	for f in $(ls -tr ${file}.* | head -${BACKUPSTODELETE})
	do
		rm $f
	done
  fi
done

echo "Downloading DMRIds.dat Files..."
curl -sSL http://www.pistar.uk/downloads/DMRIds.dat.gz --user-agent "Pi-Star_${pistarCurVersion}" | gunzip -c > ${DMRIDFILE}

# Add QRA DMRID database
echo "Downloading DMRIdsQRA.dat Files..."
curl --fail -o /tmp/DMRIdsQRA.dat -s "https://raw.githubusercontent.com/krot4u/Public_scripts/master/DMRIds.dat"
cat /tmp/DMRIdsQRA.dat >> ${DMRIDFILE}


echo "Downloading XLXHosts.txt Files..."
curl --fail -o ${XLXHOSTS} -s http://www.pistar.uk/downloads/XLXHosts.txt --user-agent "Pi-Star_${pistarCurVersion}"


if [ ! -f /root/XLXHosts.txt ]; then
touch /root/XLXHosts.txt
fi

# Add custom XLX Hosts
if [ -f "/root/XLXHosts.txt" ]; then
cat /root/XLXHosts.txt >> ${XLXHOSTS}
fi

echo "Downloading TGList_BM.txt Files..."
curl --fail -o ${TGLISTBM} -s http://www.pistar.uk/downloads/TGList_BM.txt --user-agent "Pi-Star_${pistarCurVersion}"



	# Download the correct DMR Audio Files
	if [[ ! -d /usr/local/etc/DMR_Audio ]]; then
		echo "Downloading DMR Voice Files..."
		mkdir /usr/local/etc/DMR_Audio
		curl --fail -o /usr/local/etc/DMR_Audio/en_US.ambe -s https://raw.githubusercontent.com/g4klx/DMRGateway/master/Audio/en_US.ambe
		curl --fail -o /usr/local/etc/DMR_Audio/en_US.indx -s https://raw.githubusercontent.com/g4klx/DMRGateway/master/Audio/en_US.indx
	fi

	# Download the correct P25 Audio Files
	if [[ ! -d /usr/local/etc/P25_Audio ]]; then
		echo "Downloading P25 Voice Files..."
		mkdir /usr/local/etc/P25_Audio
		curl --fail -o /usr/local/etc/P25_Audio/en_US.imbe -s https://raw.githubusercontent.com/g4klx/P25Clients/master/P25Gateway/Audio/en_US.imbe
		curl --fail -o /usr/local/etc/P25_Audio/en_US.indx -s https://raw.githubusercontent.com/g4klx/P25Clients/master/P25Gateway/Audio/en_US.indx
		echo "Done"
	fi

	# Download the correct M17 Audio Files
	if [[ ! -d /usr/local/etc/M17_Audio ]]; then
		echo "Downloading M17 Voice Files..."
		mkdir /usr/local/etc/M17_Audio
		curl --fail -o /usr/local/etc/M17_Audio/en_US.indx -s https://raw.githubusercontent.com/g4klx/M17Gateway/main/Audio/en_US.indx
		curl --fail -o /usr/local/etc/M17_Audio/en_US.m17 -s hhttps://raw.githubusercontent.com/g4klx/M17Gateway/main/Audio/en_US.m17
		echo "Done"
	fi



# Fix DMRGateway issues with brackets
#if [ -f "/etc/dmrgateway" ]; then
#	sed -i '/Name=.*(/d' /etc/dmrgateway
#	sed -i '/Name=.*)/d' /etc/dmrgateway
#fi

exit 0
