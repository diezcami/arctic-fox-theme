---
layout: post
title: "SSL issues with Python 3.7 Install From Source"
date: 2019-02-26
permalink: python37-ssl-issue
---

Recently I was configuring Python on a fresh Ubuntu server. The environment I was in required me to install Python 3.7 from source. Easy enough, I found Manivannan’s [quick bash -script](https://medium.com/@manivannan_data/install-python3-7-in-ubuntu-16-04-dfd9b4f11e5c) to run through the dependencies for me.

```bash
# Install requirements
sudo apt-get install -y build-essential
sudo apt-get install -y checkinstall
sudo apt-get install -y libreadline-gplv2-dev
sudo apt-get install -y libncursesw5-dev
sudo apt-get install -y libssl-dev
sudo apt-get install -y libsqlite3-dev
sudo apt-get install -y tk-dev
sudo apt-get install -y libgdbm-dev
sudo apt-get install -y libc6-dev
sudo apt-get install -y libbz2-dev
sudo apt-get install -y zlib1g-dev
sudo apt-get install -y openssl
sudo apt-get install -y libffi-dev
sudo apt-get install -y python3-dev
sudo apt-get install -y python3-setuptools
sudo apt-get install -y wget
# Prepare to build
mkdir /tmp/Python37
cd /tmp/Python37
# Pull down Python 3.7, build, and install
wget https://www.python.org/ftp/python/3.7.0/Python-3.7.0.tar.xz
tar xvf Python-3.7.0.tar.xz
cd /tmp/Python37/Python-3.7.0
./configure --enable-optimizations
sudo make altinstall
```

The installation went fine until I tried to pip install some modules.

```
pip is configured with locations that require TLS/SSL, however the ssl module in Python is not available.

Retrying (Retry(total=1, connect=None, read=None, redirect=None, status=None)) after connection broken by 'SSLError("Can't connect to HTTPS URL because the SSL module is not available.")': /simple/django/

Retrying (Retry(total=2, connect=None, read=None, redirect=None, status=None)) after connection broken by 'SSLError("Can't connect to HTTPS URL because the SSL module is not available.")': /simple/django/

Retrying (Retry(total=3, connect=None, read=None, redirect=None, status=None)) after connection broken by 'SSLError("Can't connect to HTTPS URL because the SSL module is not available.")': /simple/django/

Retrying (Retry(total=4, connect=None, read=None, redirect=None, status=None)) after connection broken by 'SSLError("Can't connect to HTTPS URL because the SSL module is not available.")': /simple/django/
```

Strange. It looked like openSSL had not been correctly linked. OpenSSL was installed, but what I later found out was that my local OpenSSL was up to date from apt’s perspective, but was incompatible with python 3.7.

The fix for this problem is pretty simple, but took me a tad too long to figure out.

## Steps

I decided to just install openSSL again by pulling down the newest version of the source code.

```bash
sudo apt-get install -y wget
mkdir /tmp/openssl
cd /tmp/openssl
wget https://www.openssl.org/source/openssl-1.0.2q.tar.gz
tar xvf openssl-1.0.2q.tar.gz
cd /tmp/openssl/openssl-1.0.2q
./config
make
sudo make install
```

The key here (and the reason i’m writing this post) is to show how to tell Python where this new installation of openSSL is. By default your manual install of openSSL will be in `/usr/local/ssl`. You can confirm this by checking the modify time of the ssl directory with `ls -la /usr/local/ssl` .

By default, Python isn’t going to look here. We need to fix that. To begin, run the _first part_ of the Python install script (as seen below).

```bash
# Install requirements
sudo apt-get install -y build-essential
sudo apt-get install -y checkinstall
sudo apt-get install -y libreadline-gplv2-dev
sudo apt-get install -y libncursesw5-dev
sudo apt-get install -y libssl-dev
sudo apt-get install -y libsqlite3-dev
sudo apt-get install -y tk-dev
sudo apt-get install -y libgdbm-dev
sudo apt-get install -y libc6-dev
sudo apt-get install -y libbz2-dev
sudo apt-get install -y zlib1g-dev
sudo apt-get install -y openssl
sudo apt-get install -y libffi-dev
sudo apt-get install -y python3-dev
sudo apt-get install -y python3-setuptools
sudo apt-get install -y wget
# Prepare to build
mkdir /tmp/Python37
cd /tmp/Python37
# Pull down Python 3.7, build, and install
wget https://www.python.org/ftp/python/3.7.0/Python-3.7.0.tar.xz
tar xvf Python-3.7.0.tar.xz
```

Now STOP, cd to `/tmp/openssl/Python-3.7.0` and open up the file `Modules/Setup.dist`

You should see the following lines COMMENTED.

```
# Socket module helper for SSL support; you must comment out the other
# socket line above, and possibly edit the SSL variable:
:SSL=/usr/local/ssl
 _ssl _ssl.c \
    -DUSE_SSL -I$(SSL)/include -I$(SSL)/include/openssl \
    -L$(SSL)/lib -lssl -lcrypto
```

What you need to do is UNCOMMENT these lines so that they are seen during our Python compile. Now you can finish up by running that last few lines of our python script.

```bash
cd /tmp/Python37/Python-3.7.0
./configure --enable-optimizations
sudo make altinstall
```

At this point I now had a working python and pip (mapped to `python3.7` and `pip3.7` in my path).
