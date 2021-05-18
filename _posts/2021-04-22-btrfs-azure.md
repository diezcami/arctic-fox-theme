---
layout: post
title: "Create a btrfs data disk with Azure + Packer"
date: 2021-04-22
permalink: btrfs-azure
tags: azure linux
---

Recently, I spent some time creating a repeatable method of generating a customized Linux disk image. This disk image is then consumed within an Azure VM Scale Set, (and consequently) in an Azure Devops (ADO) pipeline.

On this disk image we pre-cache a large (20GB) file and repeatedly copy that large files into "work" directories.  Copying large files in the default ext4 filesystem is unnecessarily slow, so I decided to try and utilize a [copy-on-write filesystem](https://en.wikipedia.org/wiki/Copy-on-write) like btrfs to speed up that operation. I found that it was best to leave the OS disk to something default on the marketplace, and create a separate data disk which I will format and mount in.

[Packer](https://www.packer.io/docs/builders/azure/arm) allows you to specify additional data disks, but that still leaves you to configure the block device from scratch. On the Microsoft Docs the steps to [Attach a data disk to Linux VM](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/attach-disk-portal) are laid out. Below the provisioner JSON block programatically detects our block device (which we created as a `128GB` disk - you'll need to update accordingly for your disk size), formats it to our preferred filesystem `btrfs`, and updates the `/etc/fstab` accordingly so it will be mounted again in the future.

{% raw %}
```jsonc
{
  "execute_command": "chmod +x {{ .Path }}; {{ .Vars }} sudo -E sh '{{ .Path }}'",
  "inline": [
    // Print all the block "sd*" block devices (for visual debugging if necessary)
    "lsblk -o NAME,HCTL,SIZE,MOUNTPOINT | grep -i \"sd\"",
    // Use the size of your DATA disk, specified in your packer's `disk_additional_size`, as a key for this grep.
    // Ensure only one block device is expected to be this size!
    "DEVICE=$(lsblk -o NAME,HCTL,SIZE,MOUNTPOINT | grep -i \"sd\" | grep \"128\" | cut -d' ' -f1)",
    "echo \"DEVICE FOUND = $DEVICE\"",
    // Ensure the btrfs module is loaded
    "modprobe btrfs",
    // Make filesystem over the entire block device (no need to partition, like with other filesystems)
    "mkfs.btrfs /dev/$DEVICE -f",
    // Make a directory to mount into. I call it butter
    "mkdir /butter",
    // Mount your directory
    "mount /dev/$DEVICE /butter",
    // Do this so that blkid will pick up the right UUID
    "partprobe /dev/$DEVICE",
    "blkid",
    "UUID=$(blkid | grep \"$DEVICE\" | cut -d' ' -f2 | cut -d\\\" -f2)",
    "echo \"UUID = $UUID\"",
    // You'll need this entry in your /etc/fstab for the device to get remounted again.
    "echo \"UUID=$UUID   /butter   btrfs   defaults,nofail   1   2\" >> /etc/fstab",
    // Overkill on the permissions for this example :')
    "chmod -R 777 /butter",
    // Some output sanity checks
    "df -khT",
    "mount | grep \"/dev\""
  ],
  "inline_shebang": "/bin/bash -xe",
  "type": "shell"
}
```
{% endraw %}

Here is the output of the provisioner command above - yours should look similar!

```
==> azure-arm: Provisioning with shell script: /tmp/packer-shell973735153

    azure-arm: sda     3:0:0:0     128G
    azure-arm: sdb     0:0:0:0      32G
    azure-arm: ├─sdb1             31.9G /
    azure-arm: ├─sdb14               4M
    azure-arm: └─sdb15             106M /boot/efi
    azure-arm: sdc     1:0:1:0      14G
    azure-arm: └─sdc1               14G /mnt

    azure-arm: DEVICE FOUND = sda

    azure-arm: btrfs-progs v4.15.1
    azure-arm: See http://btrfs.wiki.kernel.org for more information.
    azure-arm:
    azure-arm: Label:              (null)
    azure-arm: UUID:               7e8428d8-3fe0-4f20-825a-75c399fd0e56
    azure-arm: Node size:          16384
    azure-arm: Sector size:        4096
    azure-arm: Filesystem size:    128.00GiB
    azure-arm: Block group profiles:
    azure-arm:   Data:             single            8.00MiB
    azure-arm:   Metadata:         DUP               1.00GiB
    azure-arm:   System:           DUP               8.00MiB
    azure-arm: SSD detected:       no
    azure-arm: Incompat features:  extref, skinny-metadata
    azure-arm: Number of devices:  1
    azure-arm: Devices:
    azure-arm:    ID        SIZE  PATH
    azure-arm:     1   128.00GiB  /dev/sda
    azure-arm:

    azure-arm: /dev/sdc1: UUID="565fc1fa-02ae-4447-8751-d2f3ac7302aa" TYPE="ext4" PARTUUID="24a32a70-01"
    azure-arm: /dev/sdb1: LABEL="cloudimg-rootfs" UUID="37fdcc01-3e3c-465c-b84c-bd2a1c3b8cd7" TYPE="ext4" PARTUUID="9d108ed7-f15f-44ce-b80f-941ffa82141c"
    azure-arm: /dev/sdb15: LABEL="UEFI" UUID="88C1-EAC7" TYPE="vfat" PARTUUID="ffce7944-90d8-4378-bceb-912ef0275ddf"
    azure-arm: /dev/sda: UUID="7e8428d8-3fe0-4f20-825a-75c399fd0e56" UUID_SUB="8bb6a99f-3e93-425c-a163-db477278e7b1" TYPE="btrfs"
    azure-arm: /dev/sdb14: PARTUUID="13b2afac-ab90-472a-b083-f6250f43796a"

    azure-arm: UUID = 7e8428d8-3fe0-4f20-825a-75c399fd0e56

    azure-arm: Filesystem     Type      Size  Used Avail Use% Mounted on
    azure-arm: udev           devtmpfs  3.4G     0  3.4G   0% /dev
    azure-arm: tmpfs          tmpfs     696M  716K  695M   1% /run
    azure-arm: /dev/sdb1      ext4       31G  3.9G   27G  13% /
    azure-arm: tmpfs          tmpfs     3.4G  4.0K  3.4G   1% /dev/shm
    azure-arm: tmpfs          tmpfs     5.0M     0  5.0M   0% /run/lock
    azure-arm: tmpfs          tmpfs     3.4G     0  3.4G   0% /sys/fs/cgroup
    azure-arm: /dev/sdb15     vfat      105M  6.1M   99M   6% /boot/efi
    azure-arm: /dev/sdc1      ext4       14G   41M   13G   1% /mnt
    azure-arm: tmpfs          tmpfs     696M     0  696M   0% /run/user/1000
    azure-arm: /dev/sda       btrfs     128G  3.8M  126G   1% /butter

    azure-arm: udev on /dev type devtmpfs (rw,nosuid,relatime,size=3541800k,nr_inodes=885450,mode=755)
    azure-arm: devpts on /dev/pts type devpts (rw,nosuid,noexec,relatime,gid=5,mode=620,ptmxmode=000)
    azure-arm: /dev/sdb1 on / type ext4 (rw,relatime,discard)
    azure-arm: tmpfs on /dev/shm type tmpfs (rw,nosuid,nodev)
    azure-arm: cgroup on /sys/fs/cgroup/devices type cgroup (rw,nosuid,nodev,noexec,relatime,devices)
    azure-arm: hugetlbfs on /dev/hugepages type hugetlbfs (rw,relatime,pagesize=2M)
    azure-arm: mqueue on /dev/mqueue type mqueue (rw,relatime)
    azure-arm: /dev/sdb15 on /boot/efi type vfat (rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=iso8859-1,shortname=mixed,errors=remount-ro,discard)
    azure-arm: /dev/sdc1 on /mnt type ext4 (rw,relatime,x-systemd.requires=cloud-init.service)
    azure-arm: /dev/sda on /butter type btrfs (rw,relatime,space_cache,subvolid=5,subvol=/)
```

A full example  packer file can be found below.

This configuration...

- Creates an ordinary Ubuntu 18.04 VM from the Azure marketplace
- Attaches a 128GB data disk
- Installs some useful tools (Azure CLI, dotnet, docker, docker-compose, etc)
- Formats the attached block device as btrfs and mounts it
- Deprovisions the image
- Publishes this image to an Azure Image Gallery (to be consumed by an Azure Scaleset, etc...)

Note that I had manually created the resource group and image gallery prior to running this packer file.

{% raw %}
```jsonc
{
  "variables": {
    "image_version": "0.0.1",
    "rg": "YOUR_RG"
  },
  "builders": [
    {
      "type": "azure-arm",
      "use_azure_cli_auth": true,
      "os_type": "Linux",
      "os_disk_size_gb": 32,
      "image_publisher": "Canonical",
      "image_offer": "UbuntuServer",
      "image_sku": "18.04-LTS",
      "build_resource_group_name": "{{user `rg`}}",
      "managed_image_resource_group_name": "{{user `rg`}}",
      "managed_image_name": "local-packer",
      "managed_image_storage_account_type": "Premium_LRS",
      "vm_size": "Standard_DS2_v2",
      "disk_additional_size": [128],
      "azure_tags": {
        "localversion": "{{user `image_version`}}"
      },
      "shared_image_gallery_destination": {
        "resource_group": "{{user `rg`}}",
        "gallery_name": "local_shared_image_gallery",
        "image_name": "local-packed",
        "image_version": "{{user `image_version`}}",
        "replication_regions": ["West US 2"]
      }
    }
  ],
  "provisioners": [
    {
      "execute_command": "chmod +x {{ .Path }}; {{ .Vars }} sudo -E sh '{{ .Path }}'",
      "inline": [
        "export DEBIAN_FRONTEND=noninteractive",
        "apt-get update",
        "apt-get upgrade -y",
        "apt-get install -y jq dirmngr gnupg apt-transport-https ca-certificates",
        "echo \"deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main\" > /etc/apt/sources.list.d/azure-cli.list",
        "curl -sL https://packages.microsoft.com/keys/microsoft.asc | (OUT=$(apt-key add - 2>&1) || echo $OUT)",
        "apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF",
        "'echo \"deb https://download.mono-project.com/repo/ubuntu stable-bionic main\" > /etc/apt/sources.list.d/mono-official-stable.list'",
        "apt-get update",
        "apt-get install -y azure-cli mono-complete",
        "mono --version",
        "az --version",
        "DISTRO=$(lsb_release -is | tr '[:upper:]' '[:lower:]')",
        "CODENAME=$(lsb_release -cs)",
        "curl -s https://packages.microsoft.com/keys/microsoft.asc | (OUT=$(apt-key add - 2>&1) || echo $OUT)",
        "echo \"deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-${DISTRO}-${CODENAME}-prod ${CODENAME} main\" > /etc/apt/sources.list.d/microsoft.list",
        "apt-get update",
        "apt-get -y install --no-install-recommends moby-cli moby-engine",
        "LATEST_COMPOSE_VERSION=$(curl -sSL \"https://api.github.com/repos/docker/compose/releases/latest\" | grep -o -P '(?<=\"tag_name\": \").+(?=\")')",
        "curl -sSL \"https://github.com/docker/compose/releases/download/${LATEST_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose",
        "chmod +x /usr/local/bin/docker-compose",
        "wget https://dot.net/v1/dotnet-install.sh",
        "chmod +x ./dotnet-install.sh",
        "apt-get install -y dotnet-sdk-3.1",
        "./dotnet-install.sh  -v 3.1.404 --install-dir /usr/share/dotnet"
      ],
      "inline_shebang": "/bin/sh -xe",
      "type": "shell"
    },
    {
      "execute_command": "chmod +x {{ .Path }}; {{ .Vars }} sudo -E sh '{{ .Path }}'",
      "inline": [
        "lsblk -o NAME,HCTL,SIZE,MOUNTPOINT | grep -i \"sd\"",
        "DEVICE=$(lsblk -o NAME,HCTL,SIZE,MOUNTPOINT | grep -i \"sd\" | grep \"128\" | cut -d' ' -f1)",
        "echo \"DEVICE FOUND = $DEVICE\"",
        "modprobe btrfs",
        "mkfs.btrfs /dev/$DEVICE -f",
        "mkdir /butter",
        "mount /dev/$DEVICE /butter",
        "partprobe /dev/$DEVICE",
        "blkid",
        "UUID=$(blkid | grep \"$DEVICE\" | cut -d' ' -f2 | cut -d\\\" -f2)",
        "echo \"UUID = $UUID\"",
        "echo \"UUID=$UUID   /butter   btrfs   defaults,nofail   1   2\" >> /etc/fstab",
        "chmod -R 777 /butter",
        "df -khT",
        "mount | grep \"/dev\""
      ],
      "inline_shebang": "/bin/bash -xe",
      "type": "shell"
    },
    // ...ANY OTHER PROVISIONERS YOU WANT HERE...
    // ...
    {
      "execute_command": "chmod +x {{ .Path }}; {{ .Vars }} sudo -E sh '{{ .Path }}'",
      "inline": [
        "/usr/sbin/waagent -force -deprovision+user && export HISTSIZE=0 && sync"
      ],
      "inline_shebang": "/bin/sh -xe",
      "type": "shell"
    }
  ]
}
```
{% endraw %}
