# shutdown VM so we can export it
vagrant halt

timestamp=$(date +"%d%m%Y_%H%M")

rm -rf build/ovf/vmware/Kilo6.2.0.$timestamp
mkdir -p build/ovf/vmware/Kilo6.2.0.$timestamp

#   --allowAllExtraConfig \
#get ovftool path and vagrant machine id
if [[ "$OSTYPE" == "linux-gnu" ]]; then
   OVFTOOL=/usr/bin/ovftool
   IDCAT=`cat .vagrant/machines/stackinabox/vmware_workstation/id`
elif [[ "$OSTYPE" == "darwin"* ]]; then
   OVFTOOL=/Applications/VMware\ Fusion.app/Contents/Library/VMware\ OVF\ Tool/ovftool
   IDCAT=`cat .vagrant/machines/stackinabox/vmware_fusion/id`
fi
"$OVFTOOL" \
	--name=KiloLandscaper620 \
	--computerName:vm=KiloLandscaper620 \
	--compress=9 \
	--chunkSize=756mb \
	--maxVirtualHardwareVersion=9 \
	--sourceType=VMX \
	--targetType=OVF \
	--numberOfCpus:vm=4 \
	--memorySize:vm=8192 \
	--diskSize:vm,5=40960 \
    --diskSize:vm,6=204800 \
	--diskMode=monolithicFlat \
	--overwrite \
	--powerOffSource \
	--powerOffTarget \
    --allowExtraConfig \
    --extraConfig:vhv.enable=TRUE \
    --extraConfig:uuid.action=keep \
    --extraConfig:ethernet0.addresstype=static \
    --extraConfig:ethernet0.connectiontype=nat \
    --extraConfig:ethernet0.present=TRUE \
    --extraConfig:ethernet0.virtualdev=e1000 \
    --extraConfig:ethernet0.vnet=vmnet8 \
    --extraConfig:ethernet0.startConnected=TRUE \
    --extraConfig:logging=FALSE \
    --extraConfig:MemTrimRate=0 \
    --extraConfig:MemAllowAutoScaleDown=FALSE \
    --extraConfig:mainMem.backing=swap \
    --extraConfig:mainMem.allow8GB=TRUE \
    --extraConfig:mainMem.prefetchMB=8192 \
    --extraConfig:sched.mem.pshare.enable=FALSE \
    --extraConfig:snapshot.disabled=TRUE \
    --extraConfig:isolation.tools.unity.disable=TRUE \
    --extraConfig:isolation.tools.hgfs.disable=TRUE \
    --extraConfig:isolation.tools.copy.disable=TRUE \
    --extraConfig:isolation.tools.paste.disable=TRUE \
    --extraConfig:isolation.tools.dnd.disable=TRUE \
    --extraConfig:unity.allowCompostingInGuest=FALSE \
    --extraConfig:unity.enableLaunchMenu=FALSE \
    --extraConfig:unity.showBadges=FALSE \
    --extraConfig:unity.showBorders=FALSE \
    --extraConfig:unity.wasCapable=FALSE \
    --extraConfig:priority.grabbed=high \
    --extraConfig:priority.ungrabbed=high \
    --extraConfig:mks.enable3d=FALSE \
    --extraConfig:remotedisplay.vnc.enabled=FALSE \
    --extraConfig:proxyapps.publishtohost=FALSE \
    --extraConfig:host.TSC.noForceSync=TRUE \
    --extraConfig:host.useFastclock=FALSE \
    --extraConfig:hard-disk.useUnbuffered=TRUE \
    --extraConfig:aiomgr.buffered=TRUE \
    --extraConfig:gui.available=FALSE \
    --extraConfig:guestOS=ubuntu-64 \
	--X:logLevel=verbose \
	--X:logToConsole \
	$IDCAT \
	build/ovf/vmware/Kilo6.2.0.$timestamp
