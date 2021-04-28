#!/bin/sh
# Build an iocage jail under FreeNAS 11.3-12.0 using the current release of DNSMasq
# git clone https://github.com/basilhendroff/freenas-iocage-dnsmasq

# Check for root privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

#####
#
# General configuration
#
#####

# Initialize defaults
JAIL_IP=""
JAIL_INTERFACES=""
DEFAULT_GW_IP=""
INTERFACE="vnet0"
VNET="on"
POOL_PATH=""
JAIL_NAME="dnsmasq"
CONFIG_NAME="dnsmasq-config"
CONFIG_PATH=""

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "${SCRIPT}")

# Check for dnsmasq-config and set configuration
if ! [ -e "${SCRIPTPATH}"/"${CONFIG_NAME}" ]; then
  echo "${SCRIPTPATH}/${CONFIG_NAME} must exist."
  exit 1
fi
. "${SCRIPTPATH}"/"${CONFIG_NAME}"
INCLUDES_PATH="${SCRIPTPATH}"/includes

JAILS_MOUNT=$(zfs get -H -o value mountpoint $(iocage get -p)/iocage)
RELEASE=$(freebsd-version | cut -d - -f -1)"-RELEASE"

#####
#
# Input/Config Sanity checks
#
#####

# Check that necessary variables were set by rslsync-config
if [ -z "${JAIL_IP}" ]; then
  echo 'Configuration error: JAIL_IP must be set'
  exit 1
fi
if [ -z "${JAIL_INTERFACES}" ]; then
  echo 'JAIL_INTERFACES not set, defaulting to: vnet0:bridge0'
  JAIL_INTERFACES="vnet0:bridge0"
fi
if [ -z "${DEFAULT_GW_IP}" ]; then
  echo 'Configuration error: DEFAULT_GW_IP must be set'
  exit 1
fi
if [ -z "${POOL_PATH}" ]; then
  POOL_PATH="/mnt/$(iocage get -p)"
  echo 'POOL_PATH defaulting to '$POOL_PATH
fi

# If CONFIG_PATH wasn't set in dnsmasq-config, set it.
if [ -z "${CONFIG_PATH}" ]; then
  CONFIG_PATH="${POOL_PATH}"/apps/dnsmasq/
fi

if [ "${CONFIG_PATH}" = "${POOL_PATH}" ]
then
  echo "CONFIG_PATH must be different from POOL_PATH!"
  exit 1
fi

# Extract IP and netmask, sanity check netmask
IP=$(echo ${JAIL_IP} | cut -f1 -d/)
NETMASK=$(echo ${JAIL_IP} | cut -f2 -d/)
if [ "${NETMASK}" = "${IP}" ]
then
  NETMASK="24"
fi
if [ "${NETMASK}" -lt 8 ] || [ "${NETMASK}" -gt 30 ]
then
  NETMASK="24"
fi

#####
#
# Jail Creation
#
#####

# List packages to be auto-installed after jail creation
cat <<__EOF__ >/tmp/pkg.json
	{
  "pkgs":[
  "nano","bash","dnsmasq"
  ]
}
__EOF__

# Create the jail and install previously listed packages
if ! iocage create --name "${JAIL_NAME}" -p /tmp/pkg.json -r "${RELEASE}" interfaces="${JAIL_INTERFACES}" ip4_addr="${INTERFACE}|${IP}/${NETMASK}" defaultrouter="${DEFAULT_GW_IP}" boot="on" host_hostname="${JAIL_NAME}" vnet="${VNET}" bpf="on"
then
	echo "Failed to create jail"
	exit 1
fi
rm /tmp/pkg.json

#####
#
# Directory Creation and Mounting
#
#####

mkdir -p "${CONFIG_PATH}"

iocage exec "${JAIL_NAME}" mkdir -p /config
iocage fstab -a "${JAIL_NAME}" "${CONFIG_PATH}" /config nullfs rw 0 0

#####
#
# DNSMasq Setup
#
#####

# Always copy across the latest version of the sample configuration file
iocage exec "${JAIL_NAME}" cp /usr/local/etc/dnsmasq.conf.sample /config
# Do not overwrite dnsmasq.conf if it already exists
iocage exec "${JAIL_NAME}" cp -n /usr/local/etc/dnsmasq.conf.sample /config/dnsmasq.conf 2>/dev/null

iocage exec "${JAIL_NAME}" sysrc dnsmasq_enable="YES"
iocage exec "${JAIL_NAME}" sysrc dnsmasq_conf="/config/dnsmasq.conf"

iocage restart "${JAIL_NAME}"
