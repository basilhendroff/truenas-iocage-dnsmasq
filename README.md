# truenas-iocage-dnsmasq

This is a simple script to automate the installation of DNSMasq in a FreeNAS jail. It will create a jail, install the latest version of DNSMasq for FreeNAS, and store the `dnsmasq.conf` file outside the jail.  

## Status
This script will work with FreeNAS 11.3, and TrueNAS CORE 12 and later. Due to the EOL status of FreeBSD 11.2, it is unlikely to work reliably with earlier releases of FreeNAS.

## Usage
A local DNS resolver for small networks. DNSMasq also provides network services that may be missing in low-cost routers. 

### Prerequisites

Although not required, it's recommended to create a Dataset named `apps` with a sub-dataset named `dnsmasq` on your main storage pool.  Many other jail guides also store their configuration and data in subdirectories of `pool/apps/` If this dataset is not present, directory `/apps/dnsmasq` will be created in `$POOL_PATH`.

### Installation

Download the repository to a convenient directory on your FreeNAS system by changing to that directory and running `git clone https://github.com/basilhendroff/truenas-iocage-dnsmasq`. Then change into the new truenas-iocage-dnsmasq directory and create a file called dnsmasq-config with your favorite text editor. In its minimal form, it would look like this:

```
JAIL_IP="10.1.1.3"
DEFAULT_GW_IP="10.1.1.1"
```

Many of the options are self-explanatory, and all should be adjusted to suit your needs, but only a few are mandatory. The mandatory options are:

- JAIL_IP is the IP address for your jail. You can optionally add the netmask in CIDR notation (e.g., 192.168.1.199/24). If not specified, the netmask defaults to 24 bits. Values of less than 8 bits or more than 30 bits are invalid.
- DEFAULT_GW_IP is the address for your default gateway

In addition, there are some other options which have sensible defaults, but can be adjusted if needed. These are:

- JAIL_NAME: The name of the jail, defaults to `dnsmasq`.
- POOL_PATH: The path for your data pool. It is set automatically if left blank.
- CONFIG_PATH: The `dnsmasq.conf` file is stored in this path; defaults to `$POOL_PATH/apps/dnsmasq`.
- INTERFACE: The network interface to use for the jail. Defaults to `vnet0`.
- VNET: Whether to use the iocage virtual network stack. Defaults to `on`.

### Execution

Once you've downloaded the script and prepared the configuration file, run this script (`./dnsmasq-jail.sh`). The script will run for several minutes. When it finishes, your jail will be created and DNSMasq will be installed.

### Test

Assuming your jail name is `dnsmasq`, enter the jail `iocage console dnsmasq` and check the DNSMasq status `service dnsmasq status`. It should be running.

## Support and Discussion

Google is your friend.

Questions or issues about this resource can be raised in [this forum thread](https://www.ixsystems.com/community/threads/scripted-tautulli-installation.87434/).  
