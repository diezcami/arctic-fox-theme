---
layout: post
title: "Pi-Hole & Wireguard on Azure (in 10 minutes or less!)"
date: 2020-05-30
permalink: wireguard-azure
tags: azure linux networking
---

## Intro

Are you searching for cheap, reliable privacy for your mobile devices when on the go? With wireguard and pi-hole, you can quickly set up a remote, encrypted tunnel that provides basic DNS filtering and DNS server cycling.

Note: I'm just providing the bare minimum to get you going in this guide. Feel free to extend upon this guide to increase security and flexibility for your needs. (PRs welcome if you'd like to share your tweaks!).

## Create an Ubuntu VM in Azure

The first step is to create your Azure instance in the cloud! You can certainly configure your resource [via the Azure webapp](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/quick-create-portal). Here i'm going to run down the basics with the [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli). This below assumes you have an Azure account set up, and have the cli authentication all set too.

You can use any name you'd like. For this guide i'm using `wgph` (wireguard pihole) to preface my resource's names.

```bash
# Creates resource group
az group create --name wgphRG --location eastus

# Creates VM
az vm create \
--resource-group wgphRG \
--name wgphVM \
--image UbuntuLTS \
--admin-username ubuntu \
--public-ip-address wgphIP \
--public-ip-address-allocation static \
--generate-ssh-keys

# Open Port (Pick something random >1024 that we'll use for wireguard later)
az vm open-port --port 4400 --resource-group wgphRG --name wgphVM

# Check your IP
az network public-ip show \
  --resource-group wgphRG \
  --name wgphIP \
  --query [ipAddress,publicIpAllocationMethod,sku] \
  --output table

```

If you have any issue with the above, be sure to reference the [Microsoft Azure VM docs](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/).

Note that I would (later) remove the Azure firewall rule allowing SSH, and only allow connections behind the VPN. We definitely do NOT want to expose your DNS service or pi-hole web console to the internet, so make sure to go back and check your firewall is correctly configured with the least amount of privilege needed (VPN access).

Note if you ever want to tear this all down, you can run:

```bash
# Deletes your resource group and everything in it.
az group delete --name wgphRG --yes
```

## Setup Wireguard

Now, SSH to your new VM to set up the VPN. [Wireguard](http://wireguard.com) is an awesome, modern VPN solution that we're going to be setting up. We're going to use [PiVPN](http://pivpn.io) to conduct the entire wireguard process for us.

Your SSH key should've been automatically placed in `~/.ssh`.

```bash
ssh ubuntu@<PUBLIC-IP-ADDRESS>

# Update, upgrade, install ufw
sudo apt update && sudo apt upgrade && sudo apt install ufw

# Allow ssh and the VPN PORT you chose above through UFW (Uncomplicated Firewall)
sudo ufw allow 22
sudo ufw allow <PORT> # We chose 4400 above
sudo ufw enable

# Pull and execute pivpn script (https://pivpn.io/)
curl -L https://install.pivpn.io | bash

```

Follow the PiVPN prompts, being sure to choose "wireguard" over "OpenVPN". Be sure to enter the same PORT you opened above (I chose 4400).

After install, you can configure new clients with the `pivpn` command.

```bash
josh@wgph:~$ pivpn
::: Control all PiVPN specific functions!
:::
::: Usage: pivpn <command> [option]
:::
::: Commands:
:::  -a,  add              Create a client conf profile
:::  -c,  clients          List any connected clients to the server
:::  -d,  debug            Start a debugging session if having trouble
:::  -l,  list             List all clients
:::  -qr, qrcode           Show the qrcode of a client for use with the mobile app
:::  -r,  remove           Remove a client
:::  -h,  help             Show this help dialog
:::  -u,  uninstall        Uninstall pivpn from your system!
:::  -up, update           Updates PiVPN Scripts
:::  -bk, backup           Backup VPN configs and user profiles
```

```bash
josh@wgph:~$ pivpn -a
Enter a Name for the Client: iphone
::: Client Keys generated
::: Client config generated
::: Updated server config
::: WireGuard restarted
======================================================================
::: Done! iphone.conf successfully created!
::: iphone.conf was copied to /home/josh/configs for easy transfer.
::: Please use this profile only on one device and create additional
::: profiles for other devices. You can also use pivpn -qr
::: to generate a QR Code you can scan with the mobile app.
======================================================================

josh@wgph:~$ pivpn -qr
::  Client list  ::
• iphone
Please enter the Name of the Client to show: iphone
::: Showing client iphone below

[QR CODE HERE]
```

If you have a mobile phone you can scan the QR code with the Wireguard app. If you're setting this up on a laptop, download the correct [wireguard client](https://www.wireguard.com/install/) and copy the config from `/home/<yourname>/configs`.

You should now be able to connect via VPN!

## Set up pi-hole

We're going to set up pi-hole directly on the host, but note you could also use Docker if you'd like.

Be sure to select `wg0` as your interface and use the following values for your IP and gateway.

`ip a show dev wg0` and note the IP there. Mine was `10.4.0.1/24`.

Then run `ip r | grep default` and note your default gateway. Mine was `10.0.0.1`.

```bash
# Pull and execute pi hole script
sudo curl -sSL https://install.pi-hole.net | bash
```

To set ourselves up for pi-hole, we are going to also allow ports inbound 80 and 53 from anyone within our VPN subnet. This will allow web traffic (for pi-hole console) and DNS traffic to pass through the server firewall from any client (your phone and laptop) on the VPN subnet.

```bash
# Use what you got from `ip a show dev wg0`
sudo ufw allow from 10.4.0.0/24 to any port 53
sudo ufw allow from 10.4.0.0/24 to any port 80
```

### DHCP

Azure's DHCP servers will reset `/etc/resolv.conf` on each reboot. To keep our localhost in the list of resolvers, we need to add the following:

```bash
echo "prepend domain-name-servers 172.0.0.1;" >> /etc/dhcp/dhclient.conf
```

#### Debug tips

If you get into a state where DNS won't resolve and you need to download something from the internet, you can tempoarily add in a DNS server into `/etc/resolv.conf`.

```bash
echo "nameserver 1.1.1.1" >> /etc/resolv.conf
```

### Conclusion

You should now be able to access the pi-hole admin interface at `http://10.4.0.1/admin` (or whatever your local IP was) from within the VPN.

To forward DNS traffic from other VPN clients through pi-hole, edit your client's wireguard config.

For example, this would be my iPhone's config.

```
[Interface]
PrivateKey = <KEY>
Address = 10.4.0.3/24
DNS = 10.4.0.1

[Peer]
PublicKey = <KEY>
PresharedKey = <KEY>
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = <PUBLIC_IP>:4400
```

You should now see traffic in the pi-hole logs! You can also use my [pi-hole iOS app to observe the traffic](https://joshspicer.com/pihole) :)
