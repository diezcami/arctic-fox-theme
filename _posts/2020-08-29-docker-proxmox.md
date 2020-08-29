---
layout: post
title: "Docker VM on Proxmox (rancherOS/Portainer)"
date: 2020-08-29
permalink: docker-proxmox
tags: homelab
---

## Intro

LXC containers are great, but even so I often find myself wanting to quickly spin up docker projects I find online. Below is my preferred method of hosting and managing docker containers on my proxmox homelab.

## RancherOS

I like [Rancher OS](https://rancher.com/docs/os/v1.x/en/overview/) because it is minimal and designed exactly with docker in mind. Rancher OS is quick and even offers a special proxmox ISO with the proxmox agent preinstalled (which among other things, lets you see the VMs IP address from the proxmox GUI).

From Rancher's [Booting from ISO docs](https://rancher.com/docs/os/v1.x/en/installation/workstation/boot-from-iso/), install the Proxmox VE ISO [(latest download)](https://releases.rancher.com/os/latest/proxmoxve/rancheros.iso).

Add that to your Proxmox ISOs, and create a new VM with your preferred RAM/storage/etc. Set the boot CD to your rancher ISO.

Startup the new VM and you'll be dropped into a rancher shell.

### Install to hard disk/configure

Next we're going to [install rancher to disk](https://rancher.com/docs/os/v1.x/en/installation/server/install-to-disk/).

We will install to disk using `ros install`. We first need to get a `cloud-config` yaml file onto this machine.

Here is the yml file I created on my local machine. It specifies an ssh key (password login is disabled by default on rancher), and my static network settings.

```yaml
#cloud-config

hostname: rancher

rancher:
  network:
    interfaces:
      eth0:
        address: 10.1.0.100/24
        gateway: 10.1.0.1
        dhcp: false
    dns:
      nameservers:
        - 10.1.0.101
        - 1.1.1.1
        - 9.9.9.9

ssh_authorized_keys:
  - ssh-rsa <MY_PUBLIC_KEY> josh@myMacbook
```

To get this config onto the VM, I started a simple python HTTP server in the directory of my config.

#### On laptop/local machine

```bash
python3 -m http.server

# Serving HTTP on 0.0.0.0 port 8000 (http://0.0.0.0:8000/) ...
```

Assuming you're on the same local network, you can now `wget` your config into your rancher instance.

### In Rancher VM

```bash
wget <MY_LAPTOP_IP>:8000/cloud-config.yml

# Connecting to 10.1.0.99:8000 (10.1.0.99:8000)
# cloud-config.yml     100% |*****************************************|   847   0:00:00 ETA
```

Validate the `yml` file with, specify the device you'd like to install to (check with `df`), and install.

```bash
sudo ros config validate -i cloud-config.yml
# No output means no errors!

sudo ros install -c cloud-config.yml -d /dev/sda
# Installing....
```

Now reboot, and remove the mounted ISO within the proxmox GUI. You should now be able to ssh with that ssh key you added in the config.

## Install Portainer

I like to use portainer to visualize the containers running on my system. It's super easy to install. Taken from [their docs](https://www.portainer.io/installation/), simply run within a rancher shell...

```bash
docker volume create portainer_data

docker run -d -p 8000:8000 -p 9000:9000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer
```

Portainer should now be accessible at `http:<YOUR_RANCHER_IP>:9000`.
