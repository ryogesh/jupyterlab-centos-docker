#!/usr/bin/bash

# Change the docker image, as required
DKR_IMAGE=cdp_ml:v1

# java is installed on host; mount JAVA_HOME
if [ X$(readlink -f /usr/bin/java) != "X" ]; then
  JH=$(readlink -f /usr/bin/java |sed "s/\/bin\/java//")
  echo "Java is available on host: $JH"
  JHMNT=" --mount type=bind,source=${JH},target=${JH},readonly"
  JHMNT=${JHMNT}" --mount type=bind,source=/usr/share/java,target=/usr/share/java,readonly"
  if [ -d  /usr/share/javazi-1.8 ]; then
    JHMNT=${JHMNT}" --mount type=bind,source=/usr/share/javazi-1.8,target=/usr/share/javazi-1.8,readonly"
  fi 
fi

# cloudera parcels is installed, mount parcels and config directories
if [ -d  /opt/cloudera/parcels/CDH ]; then
  echo "Add CDP mounts"
  CDH=/opt/cloudera/parcels/CDH
  CDHMNT=" --mount type=bind,source=${CDH},target=${CDH},readonly"
  CDHF=$(readlink -f $CDH)
  CDHFMNT=" --mount type=bind,source=${CDHF},target=${CDHF},readonly"
  CONFMNT=""
  for i in hadoop hive spark; do CONFMNT=${CONFMNT}" --mount type=bind,source=/etc/$i/conf,target=/etc/$i/conf,readonly"; done
fi

if [ -d  /opt/cloudera/parcels/SPARK3 ]; then
  echo "Add SPARK3 mounts"
  SP3=/opt/cloudera/parcels/SPARK3
  SP3MNT=" --mount type=bind,source=${SP3},target=${SP3},readonly"
  SP3F=$(readlink -f $SP3)
  SP3FMNT=" --mount type=bind,source=${SP3F},target=${SP3F},readonly"
  SP3CONFMNT=" --mount type=bind,source=/etc/spark3/conf,target=/etc/spark3/conf,readonly"
fi

# kerberos is installed, mount /etc/krb5.conf file
if ! [ -e  /etc/krb5.conf ]; then
  KRBMNT=" --mount type=bind,source=/etc/krb5.conf,target=/etc/krb5.conf,readonly"
fi 

# Local ntp installed and configured, mount /etc/ntp.conf 
if [ -e  /etc/ntp.conf ]; then
  NTPMNT=" --mount type=bind,source=/etc/ntp.conf,target=/etc/ntp.conf,readonly"
fi

# Check for an open port between 8878..8898 and assign it to the container
for i in {8878..8898}; do
  if [ X$(ss -tanp|grep python|grep LISTEN|awk '{print $4}'|awk -F':' '{print $2}' |grep $i) == "X" ]; then 
    CPORT=$i
    break  
  fi
done

#launch docker
echo -e "launching container on port $CPORT, with the mounts:  $JHMNT $CDHMNT $CDHFMNT $CONFMNT $SP3MNT $SP3FMNT $SP3CONFMNT $KRBMNT $NTPMNT \n"
echo "Docker container id is:"
docker run --log-opt mode=non-blocking --log-opt max-buffer-size=4m --init --network=host -m 2G --rm -d -i \
$JHMNT $CDHMNT $CDHFMNT $CONFMNT $SP3MNT $SP3FMNT $SP3CONFMNT $KRBMNT $NTPMNT $DKR_IMAGE start-process.sh --port $CPORT

echo -e "\n*******JupyterLab is available at *********"
echo "http://$(hostname -f):${CPORT}"
