#!/bin/bash

function prompt_default()
{
	local __resultvar=$1
	local result=""
	read -r -p "$2 [$3]: " result
	if [ -z "$result" ]; then
		result="$3"
	fi
	eval $__resultvar=$result
}

ISOFILE=$1
if [ ! -f "$ISOFILE" ]; then
	echo "Please specify a valid installer file"
	exit
fi

# Get options
prompt_default VMNAME   "Name of new VM" "default"
prompt_default HOSTNAME "Hostname" "${VMNAME}.my"
prompt_default IPADDR   "IP Address" "10.0.0.99"
prompt_default RAM      "RAM (MiB)" "4096"
prompt_default VCPUS    "VCPUs" "2"
prompt_default POOL     "VHD Storage Pool" "default"

echo "\nSettings chosen:"
echo "  Name:             ${VMNAME}"
echo "  Host Name:        ${HOSTNAME}"
echo "  IP Address:       ${IPADDR}"
echo "  RAM:              ${RAM} MiB"
echo "  VCPUS:            ${VCPUS}"
echo "  Storage Pool:     ${POOL}"
echo "  Installation ISO: ${ISOFILE}"
read -r -p "Continue? [y/N]: " CONTINUE

CONTINUE=${CONTINUE,,}    # tolower
if [[ ! $CONTINUE =~ ^(yes|y)$ ]]; then
	echo "Aborting"
	exit
fi

# Work in tmp
TEMPDIR=$(mktemp --tmpdir -d createvm.sh.tmp.XXXXX)
cp base-ks.cfg $TEMPDIR
echo $TEMPDIR
pushd $TEMPDIR

# Modify the kickstart template
sed -i "s/%IPADDR%/$IPADDR/" base-ks.cfg
sed -i "s/%HOSTNAME%/$HOSTNAME/" base-ks.cfg

VHD="${VMNAME}.raw"
echo "Creating virtual disk volume as ${POOL}/${VHD}"

# Create a virtual disk
virsh vol-create-as ${POOL} ${VHD} 20G --format raw --allocation 20G

echo "Beginning install"

# Start virt-install
virt-install \
--name $VMNAME \
--ram $RAM \
--vcpus=$VCPUS \
--os-variant=fedora21 \
--accelerate \
--network=bridge:br0 \
--hvm \
--nographics \
--initrd-inject="$TEMPDIR/base-ks.cfg" \
--extra-args="ks=file:/base-ks.cfg text console=ttyS0,115200" \
--disk vol=${POOL}/${VHD} \
--location $ISOFILE

# Clean up
popd
rm -rf $TEMPDIR
