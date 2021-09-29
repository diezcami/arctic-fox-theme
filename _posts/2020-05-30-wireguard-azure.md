---
layout: post
title: "Pi-Hole & Wireguard on Azure (in 10 minutes or less!)"
date: 2020-05-30
permalink: wireguard-azure
tags: azure linux networking
---

> UPDATE: Sept 2021 - I've recently made some edits (thanks to a helpful email and slack message) that should resolve a _pesky_ DNS issue.  Please [contact me](/contact) or put up a [PR](https://github.com/joshspicer/joshspicer.github.io/edit/master/_posts/2020-05-30-wireguard-azure.md) if you see anything funny!

## Intro

Are you searching for cheap, reliable privacy for your mobile devices when on the go? With wireguard and pi-hole, you can quickly set up a remote, encrypted tunnel that provides basic DNS filtering and DNS server cycling.

Note: I'm just providing the bare minimum to get you going in this guide. Feel free to extend upon this guide to increase security and flexibility for your needs. (PRs welcome if you'd like to share your tweaks!).

## Create an Ubuntu VM in Azure

The first step is to create your Azure instance in the cloud! You can certainly configure your resource [via the Azure webapp](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/quick-create-portal). Here i'm going to run down the basics with the [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli). This below assumes you have an Azure account set up, and have the cli authentication all set too.

You can use any name you'd like. For this guide i'm using `wgph` (wireguard pihole) to preface my resource's names.

```bash

# Set this to whatever you'd like, (or keep it)
NAME='wgph'

# Creates resource group
az group create --name ${NAME}-rg --location eastus

# Creates VM
az vm create \
--resource-group ${NAME}-rg \
--name ${NAME}-vm \
--image UbuntuLTS \   # At time of writing Ubuntu 18.04.6 LTS
--admin-username ubuntu \
--public-ip-address ${NAME}-ip \
--public-ip-address-allocation static \
--generate-ssh-keys

# Open Port (Pick something random >1024 that we'll use for wireguard later)
az vm open-port --port 4400 --resource-group ${NAME}-rg --name ${NAME}-vm

```

You can then look at the output above, or run the query below, to find your VM's public IP address.

```bash

# Check your IP
az network public-ip show \
  --resource-group ${NAME}-rg \
  --name ${NAME}-ip \
  --query '[ipAddress,publicIpAllocationMethod,sku]' \
  --output table
```

If you have any issue with the above, be sure to reference the [Microsoft Azure VM docs](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/).

At the time of writing, Ubuntu "Bionic Beaver" is the LTS version Azure gives us.  If your `/etc/os-release` looks different than mine, YMMV with this guide. 

```
ubuntu@wgph:~$ cat /etc/os-release | head -n 6
NAME="Ubuntu"
VERSION="18.04.6 LTS (Bionic Beaver)"
ID=ubuntu
ID_LIKE=debian
PRETTY_NAME="Ubuntu 18.04.6 LTS"
VERSION_ID="18.04"
```

_Please do leave a [PR](https://github.com/joshspicer/joshspicer.github.io/edit/master/_posts/2020-05-30-wireguard-azure.md) if you need to modify any steps in the future!_



Note that I would (later) remove the Azure firewall rule allowing SSH, and only allow connections behind the VPN. We definitely do NOT want to expose your DNS service or pi-hole web console to the internet, so make sure to go back and check your firewall is correctly configured with the least amount of privilege needed (VPN access).

Note if you ever want to tear this all down, you can run:

```bash
# Deletes your resource group and everything in it.
az group delete --name ${NAME}-rg --yes
```

## Setup Wireguard

Now, SSH to your new VM to set up the VPN. [Wireguard](http://wireguard.com) is an awesome, modern VPN solution that we're going to be setting up. We're going to use [PiVPN](http://pivpn.io) to conduct the entire wireguard process for us.

If you didn't have an SSH key already, it should've been automatically placed in `~/.ssh`.

```bash
ssh -i ~/.ssh/id_rsa ubuntu@<PUBLIC-IP-ADDRESS> 

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

I chose `public IP` for "How will people connect".  Additionally, I said `yes` to unattended upgrades.

Ok - now Reboot!

### Tweak Ubuntu DNS

> _Edit 9/23/21 - Thanks to Jon H. for emailing me with this fix!_

One additional step you'll need to do is tweak the current DNS settings on the machine. 

First, edit `/etc/systemd/resolved.conf` by uncommenting `#DNS`, setting your preference of upstream DNS provider(s). The field is space-separated.

```
[Resolve]
DNS=1.1.1.1 9.9.9.9
#FallbackDNS=
#Domains=
#LLMNR=no
#MulticastDNS=no
#DNSSEC=no
#Cache=yes
#DNSStubListener=yes
```

Next, symlink the systemd resolve file to /etc/resolv.conf.

```bash
sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
sudo systemctl stop systemd-resolved
sudo systemctl start systemd-resolved
```

Do a quick `dig` check, and see that now your DNS provider is set as the system default.

```bash
josh@wgph:~$ dig joshspicer.com | grep "SERVER"
;; SERVER: 1.1.1.1#53(1.1.1.1)
```

Definitely make sure DNS is working _before_ continuing.

### Configure Wireguard

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

`ip a show dev wg0` and note the IP there. Mine was `10.6.0.1/24`.

Then run `ip r | grep default` and note your default gateway. Mine was `10.0.0.1`.

Be sure to select `wg0` as your interface when running through the pihole installer, and use the previous values for your IP and gateway.

Again, **make sure to select `wg0` - the wireguard interface**

```bash
# Pull and execute pi hole script
sudo curl -sSL https://install.pi-hole.net | bash
```

_Note_: Use **SPACEBAR** to select an option, then **TAB, ENTER** to move and select the \<Ok\>.

<img width="537" alt="Screen Shot 2021-07-14 at 8 19 04 AM" src="https://user-images.githubusercontent.com/23246594/125621078-bb104b7c-91e1-46dc-a2b3-6fbcd03d5d21.png">
  
<img width="537" alt="Screen Shot 2021-07-14 at 8 19 04 AM" src="https://user-images.githubusercontent.com/23246594/125624502-ebe73a5d-c3c7-4341-98be-83c8ade0c19b.png">

To set ourselves up for pi-hole, we are going to also allow ports inbound 80 and 53 from anyone within our VPN subnet. This will allow web traffic (for pi-hole console) and DNS traffic to pass through the server firewall from any client (your phone and laptop) on the VPN subnet.

```bash
# Use what you got from `ip a show dev wg0`
sudo ufw allow from 10.6.0.0/24 to any port 53
sudo ufw allow from 10.6.0.0/24 to any port 80
```

### DHCP

<details>
  <summary><i>NOTE: I don't think this step is necessary anymore, but leaving here for posterity.</i></summary>
  <br>
  
Azure's DHCP servers will reset `/etc/resolv.conf` on each reboot. To keep our localhost in the list of resolvers, we need to add the following:

  
```bash
echo "prepend domain-name-servers 127.0.0.1;" >> /etc/dhcp/dhclient.conf
```
  
</details>  
<br>

#### Debug tips

If you get into a state where DNS won't resolve and you need to download something from the internet, you can temporarily add in a DNS server into `/etc/resolv.conf`.

NOTE: Given the step we did above symlinking `/run/systemd/resolve/resolv.conf -> /etc/resolv.conf`, you should never _have_ to do this since systemd is setting our preferred DNS providers for us.

```bash
ubuntu@wgph:~$ ls -la /etc/resolv.conf
lrwxrwxrwx 1 root root 32 Sep 23 22:50 /etc/resolv.conf -> /run/systemd/resolve/resolv.conf


ubuntu@wgph:~$ cat /etc/resolv.conf
# This file is managed by man:systemd-resolved(8). Do not edit.
...
...

nameserver 1.1.1.1           # Our custom DNS nameserver 1
nameserver 9.9.9.9           # Our custom DNS nameserver 2
nameserver 168.63.129.16.    # Azure's default DNS nameserver
search t0wcdadekjekljelmzg.ax.internal.cloudapp.net

```

Nonetheless, if you're stuck you can try something like this:

```bash
echo "nameserver 1.1.1.1" >> /etc/resolv.conf
```

### Setting up the DNS to use Pi-Hole

Now that Pi-hole is running and you're connected through the VPN, you just need to change your DNS settings inside the wireguard app to use the Pi-hole machine's IP.  On android this was as simple as selecting the pivpn connection and editing the DNS field to say 10.6.0.1.

### Conclusion

You should now be able to access the pi-hole admin interface at `http://10.6.0.1/admin` (or whatever your local IP was) from within the VPN.

To forward DNS traffic from other VPN clients through pi-hole, edit your client's wireguard config.

For example, this would be my iPhone's config.

```
[Interface]
PrivateKey = <KEY>
Address = 10.6.0.3/24
DNS = 10.6.0.1

[Peer]
PublicKey = <KEY>
PresharedKey = <KEY>
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = <PUBLIC_IP>:4400
```
 
The DNS endpoint can also be edited directly from the wireguard app.
  
![IMG_8564D7F3ACD5-1](https://user-images.githubusercontent.com/23246594/125625361-67b2a8d6-e5e1-4fcb-a75b-6b5eb216c624.jpeg)

----
<br>

You should now see traffic in the pi-hole logs! You can also use my [pi-hole iOS app to observe the traffic](https://joshspicer.com/pihole) :)

![IMG_F88731CDA6EF-1](https://user-images.githubusercontent.com/23246594/125625875-690cae2a-0a84-443e-85c4-3d030b820783.jpeg)





