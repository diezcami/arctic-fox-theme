---
layout: post
title: "Linux/Over The Wire Workshop - CoSMO"
date: 2019-04-01
permalink: wargames
tags: hacking linux
---

> I helped start [CoSMO](https://nuCoSMO.club/), a computer science mentorship club at Northeastern. Below is the workshop I conducted teaching
> Linux fundamentals through Over The Wire "War Games".

# Linux CLI / Bandit Workshop

Linux is an operating system that sits the at core of much of the technology we interact with daily. Linux is free, secure, and to work with it on the job is unavoidable.

We'll start the workshop by reviewing some common and good-to-know linux commands. We'll then move into Bandit ["War Games"](http://overthewire.org/wargames/bandit/), an interactive shell-based game that reinforces basic commands and teaches security concepts.

## Why Learn Linux?

Linux is an operating system, like MacOS or Windows. Linux knowledge is invaluable in the CS field. Odds are servers you'll interact with on the job will be running some distro of Linux. In addition, small or embedded systems often run some flavor of Linux. Ever used a raspberry pi? Those devices are generally running Raspbian, a Linux distribution. Linux provides a stable development environment, and of course is free and open for users to get started with!

## Setup

Before we start, lets get our environment set up.

### Khoury Account

Khoury college provides a Linux server for students to utilize. You connect to this server over SSH, a protocol that forwards all the terminal commands you type locally, to the remote server. You can administer remote servers from your own computer this way. We're going to SSH into the Khoury College servers to practice some basics.

We will be using our CCIS/Khoury accounts (this is the same account you use for Bottlenose!). Note: If you aren't a CCIS student you can skip this step and just connect directly to Over The Wire (more on that later), or just pay attention to the demonstration!

- You can create your CCIS account [here](https://www.khoury.northeastern.edu/systems/getting-started/)
- If you have an account but [forgot your password](https://my.ccs.neu.edu/forgot/password) you can reset it here.
- If you have an account but [forgot your username](https://my.ccs.neu.edu/forgot/username), check here.

### MacOS/Linux

MacOS and Linux come with terminal programs out of the box. On MacOS this can be done by opening Spotlight (CMD+Spacebar) and typing in "Terminal".

You can now connect to our college SSH server by typing
`ssh <YOUR-USERNAME>@login.ccs.neu.edu`

#### Pro Tip

To make it easier to connect in the future you can add the following configuration to your ssh config. Open up the file by typing `vim ~/.ssh/config`. Press "i" to enter vim's insert (typing) mode.

```bash
 Host ccis
      Hostname login.ccs.neu.edu
      User <YOUR USERNAME>

```

You can save the file by entering `ESC :wq`. This will (w)rite the file and (q)uit vim. Now all I have to type is `ssh ccis` and all the information is autofilled for me.

### Windows

If on Windows, you'll need to install a program like [PuTTY](https://bit.ly/2pV44Vj). You can also use the [Windows Linux Subsystem](https://docs.microsoft.com/en-us/windows/wsl/install-win10).

After installing PuTTY, open the program and enter `login.ccs.neu.edu` as the hostname. You'll then be able to add in your username and password, and eventually connect.

## The Basics

### Directory Traversal

Great - at this point you should be ssh'd into the server and ready to practice some commands! Linux at its core is just a collection of files organized into different directories. Check what directory you're in by typing `pwd` (Print Working Directory). You can (c)hange your working (d)irectory with the `cd` command.

When changing directory, you can either specify the **absolute path**, or provide a **relative path** with `.` and `..`. A single dot represents the current directory you are in. Double dots represent the parent directory.

```bash
-bash-4.2$ pwd
/home/joshua

-bash-4.2$ cd ./Desktop

-bash-4.2$ pwd
/home/joshua/Desktop

-bash-4.2$ cd ..

-bash-4.2$ pwd
/home/joshua

```

All commands you run will be executed with this directory (my home directory) as context. When cloning something like a git repo, those files will be cloned into whatever your working directory is, unless you specify otherwise.

Lets fire off a few other commands while we're here.

- `ls` - lists all files and directories in the current working directory
- `mkdir <NAME>` - make a new directory in the current working directory
- `touch <NAME>` - Creates a new (empty) file in the working directory
- `cat <FILE>` - Print the contents of the file to standard out.
- `echo <TEXT>` - "Echos" a given string to standard out (the screen)

```bash
bash-4.2$ pwd
/home/joshua

-bash-4.2$ ls
cs3650       hw05         My Music     Systems       Visual Studio 2012
Desktop      hw07         My Pictures  tmp

-bash-4.2$ mkdir CoSMO

-bash-4.2$ ls
CoSMO        cs3650       hw05         My Music     Systems          Visual Studio 2008
Desktop      hw07         My Pictures  tmp
Contacts/ CoSMO/

-bash-4.2$ cd CoSMO/

-bash-4.2$ touch file.txt

-bash-4.2$ ls
file.txt
```

### Bash Operators

Bash is a special kind of programming language that we interact with in our terminals. Just like Java or Python have operators like `+` and `*`, we see operators in Bash too. Below are some useful ones (although there are plenty more)!

- `>` Used to redirect standard output to a file. Overwrites existing file is it exists!
- `>>` Also used to redirect output to a file, but appends to a current file.
- `<` Redirect input from a file.
- `|` A "Pipe". Sends the output of the first command as the input of the next command.

```bash
-bash-4.2$ echo "Hello, CoSMO" > greeting.txt

-bash-4.2$ cat greeting.txt
Hello, CoSMO

-bash-4.2$ echo "How are you?" >> greeting.txt

-bash-4.2$ cat greeting.txt
Hello, CoSMO
How are you?

-bash-4.2$ cat greeting.txt | grep "CoSMO"
Hello, CoSMO
```

## Useful Linux Programs

### grep

Let's break down that last command we issued with `grep`. Grep is a built in unix program that searches files for a specified pattern of words. In the above command we passed our file `greeting.txt` as the input to grep, and searched for a line with the pattern "CoSMO". Grep scanned the file line by line and, as you can see, found one line that matched. Grep, by defaults, prints the lines it matches.

### Manual Pages

You might be asking at this point, how am I supposed to remember all these commands? Good news - you don't! Most linux programs will come with a "manual" file that explains exactly how to use them. Let's see what grep's manual page looks like by running the `man` command.

Type `man grep`

```
GREP(1)                                          General Commands Manual                                         GREP(1)

NAME
       grep, egrep, fgrep - print lines matching a pattern

SYNOPSIS
       grep [OPTIONS] PATTERN [FILE...]
       grep [OPTIONS] [-e PATTERN | -f FILE] [FILE...]

DESCRIPTION
       grep  searches the named input FILEs (or standard input if no files are named, or if a single hyphen-minus (-) is
       given as file name) for lines containing a match to the given PATTERN.  By  default,  grep  prints  the  matching
       lines.

       In  addition,  two  variant  programs egrep and fgrep are available.  egrep is the same as grep -E.  fgrep is the
       same as grep -F.  Direct invocation as either egrep or fgrep is deprecated, but is provided to  allow  historical
       applications that rely on them to run unmodified.

OPTIONS
   Generic Program Information
       --help Print  a  usage message briefly summarizing these command-line options and the bug-reporting address, then
              exit.

       -V, --version

    ...
    ...
    ...
```

The file is divided into general program synopsis, what the program is used for, the correct syntax, as well as a variety of options that can be utlized.

The man page can be searched by first pressing `/`, and then typing the pattern you want to search for. Press the `n` key to swap to the next match in the search! You can use the arrow keys to scroll through a man page, and can press `q` to quit out.

### Options

Linux programs often can do more than one thing, and grep is no exception. If you look on grep's man page you see a lot of options to modify the behavior of the program.

```
    ...
    ...
   Matching Control
       -e PATTERN, --regexp=PATTERN
              Use PATTERN as the pattern.  This can be used to specify multiple search patterns, or to protect a pattern
              beginning with a hyphen (-).  (-e is specified by POSIX.)

       -f FILE, --file=FILE
              Obtain patterns from FILE, one per line.  The empty file contains zero  patterns,  and  therefore  matches
              nothing.  (-f is specified by POSIX.)

       -i, --ignore-case
              Ignore case distinctions in both the PATTERN and the input files.  (-i is specified by POSIX.)

       -v, --invert-match
              Invert the sense of matching, to select non-matching lines.  (-v is specified by POSIX.)

    ...
    {... lots more ...}
    ...
```

As you can see above, specifying the flag `-i` tells grep to ignore case.

```bash
-bash-4.2$ cat greeting.txt | grep -i "cosmo"
Hello, CoSMO

-bash-4.2$ cat greeting.txt | grep  "cosmo"

```

### vim

So far we've learned how to create files, but how do we edit those later on? There's lot of options of text editor (including `nano`, `emacs`, and more). Vim is one popular text editor.

Opening files is as simple as `vim <NAME OF FILE>`. If the file doesn't exist in your working directory, it wil be created.

Once inside a file, you're placed in _command_ mode. Pressing `i` will place you into _insert_ mode, where you can edit the file how you'd expect. To exit _insert_ mode and move back into _command_ mode, press `ESC`. From command mode you can (w)rite and (q)uit by entering `:wq`.

Vim is very powerful. You can find a (more) complete vim cheatsheet [here](https://vim.rtorr.com/).

### file

`file <FILE>` is a program that tries to classify and determine the filetype of a given file. This is useful when a file extension isn't specified.

### find

Similar to `grep`, the program `find` can be used to locate files based on certain criteria.

```bash
-bash-4.2$ find ./CoSMO/ -name "greeting*"
./CoSMO/greeting.txt
```

The example looks inside our CoSMO directory for any files that begin with the word "greeting". We used the dot in our file path to indicate we are looking relative to our current working directory. What's returned is a list of all the files that match!

## Tips

### Reverse Bash search

One of my favorite bash features is reverse command search. Often times you'll need to run the same command twice. You can find any command in your history by pressing `control + R` on Mac/Linux. You can now type the beginning of the command you're looking for and bash will match against your previous commands. Press `control + R` again to cycle through older options, and press enter to issue the command.

Below I typed `ssh` into the search, and was presented with the full login command we used earlier.

```bash
$
(reverse-i-search)`ssh': ssh joshua@login.ccs.neu.edu
```

## Over The Wire

Congrats - you just learned all you need to know to hop into [Bandit](http://overthewire.org/wargames/bandit)! Bandit and the rest of the Over The Wire "war games" are security labs intended to teach you the security fundamentals. Bandit especially is a great introduction to practical Linux usage! Through Bandit you'll also learn some quirks about bash, linux, and technology in general.

Head over the [Level0](http://overthewire.org/wargames/bandit/bandit0.html) and SSH into the first challenge. (You'll _first_ need to disconnect from the Khoury college server!).

```bash
josh$ ssh -p 2220 bandit0@bandit.labs.overthewire.org

The authenticity of host '[bandit.labs.overthewire.org]:2220 ([176.9.9.172]:2220)' can't be established.
ECDSA key fingerprint is SHA256:98UL0ZWr85496E...hczc.

Are you sure you want to continue connecting (yes/no)? yes

Welcome to OverTheWire!
...
...
```

Note that we had to specify a port with ssh's `-p` flag. By default ssh tries to connect over port 22.

Let's apply what we just learned to find next level's password!

#### Level 0 -> Level 1

```bash
bandit0@bandit:~$ pwd
/home/bandit0
bandit0@bandit:~$ ls
readme
bandit0@bandit:~$ cat readme
boJ9jbbUNNfktd78OOpsqOltutMc3MY1
bandit0@bandit:~$
```

Hey look, we found something in a file called `readme` that looks like a password. If we use this password on [the next level](http://overthewire.org/wargames/bandit/bandit1.html) we see that it works! Note that we changed the username below from `bandit0` to `bandit1`.

#### Level 1 -> Level 2

```bash
bandit0@bandit:~$ exit
logout
Connection to bandit.labs.overthewire.org closed.
tracy:bandit-workshop josh$ ssh -p 2220 bandit1@bandit.labs.overthewire.org

Password: boJ9jbbUNNfktd78OOpsqOltutMc3MY1

Welcome to Overthewire!
...
...
```

This challenge is designed to emphasize special characters in the bash language. More specifically, the special character `-`. Check out the "Helpful Reading Material" if you ever get stuck!

```bash
bandit1@bandit:~$ ls
-

bandit1@bandit:~$ file ./-
./-: ASCII text

bandit1@bandit:~$ cat ./-
CV1DtqXWVFXTvM2F0k09SHz0YwRINYA9

```

#### Level 2 -> Level 3

Level two can be accessed by changing the username to `bandit2`, just like before! Be sure to supply the new password we just discovered above.

```bash
bandit2@bandit:~$ ls
spaces in this filename

bandit2@bandit:~$ file spaces\ in\ this\ filename
spaces in this filename: ASCII text

bandit2@bandit:~$ cat spaces\ in\ this\ filename
UmHadQclWmgdLOKQ3YNgjWxGoRMb5luK
```

The spaces in this file name had to be escaped, which is why it was necessary to add the escape character `\`. Again, over the wire supplies hints on [readings](https://www.google.com/search?q=spaces+in+filename) for each level - take advantage of them!

#### Level 3 -> Level 4

This level mentions that the password file is _hidden_ from us. Upon inspection, it looks like that's true!

```bash
bandit3@bandit:~$ ls
inhere
bandit3@bandit:~$ cd inhere/
bandit3@bandit:~/inhere$ ls
bandit3@bandit:~/inhere$
```

I first solved this problem by starting with the Google search "hidden files linux". You'll quickly find lots of information about [dot files](https://en.wikipedia.org/wiki/Hidden_file_and_hidden_directory) where you can read up and learn what command should be used.

> In Unix-like operating systems, any file or folder that starts with a dot character (for example, /home/user/.config), commonly called a dot file or dotfile, is to be treated as hidden – that is, the ls command does not display them unless the -a flag (ls -a) is used. In most command-line shells, wildcards will not match files whose names start with . unless the wildcard itself starts with an explicit . .

Here we learn that `ls` has a `-a` flag, which displays these hidden dot files. We can confirm that by checking `ls`'s man page, or by testing it out for ourselves.

```bash
bandit3@bandit:~/inhere$ ls -a
.  ..  .hidden

bandit3@bandit:~/inhere$ cat .hidden
pIwrPrtPN36QITSp3EQaw936yaFoFgAB
```

#### Level 4 -> Level 5

[This level](http://overthewire.org/wargames/bandit/bandit5.html) mentions that there is only one "human readable" file. At the start we may not know what that means, but we can again use the `file` command to check the types of data in each file. You can use the `*` shorthand to mean "all files in the directory".

```
bandit4@bandit:~/inhere$ file ./*
./-file00: data
./-file01: data
./-file02: data
./-file03: data
./-file04: data
./-file05: data
./-file06: data
./-file07: ASCII text
./-file08: data
./-file09: data
bandit4@bandit:~/inhere$ cat ./-file07
koReBOKuIDDepwhWk7jZC0RTdopnAYKh
```

We notice that `-file07` is the only one that contains a different type of data. Taking a look yields us the password!

#### Level 5 -> Level 6

This challenge gives us some attributes of the file we're looking for.

> human-readable, 1033 bytes in size, and not executable

I approached this by taking a look at the man page for `find`. I searched for "size", which told me that `-size 1033c` means "find files of exactly 1033 bytes". I approached the other attributes similarly to construct the below "find" command.

```bash
bandit5@bandit:~$ find . -type f ! -executable -readable -size 1033c
./inhere/maybehere07/.file2
bandit5@bandit:~$ cat ./inhere/maybehere07/.file2
DXjZPULLxYr17uwoI01bNLQbtFemEgo7
```

#### Level 6 -> Level 7

Let's do one more together! This one is similar, but this time we need to search the entire server for the file, not just a certain directory. By indicating `/` in our command, we are saying start your search at the root (top) of the filesystem, and search down from there. I again used

```bash
bandit6@bandit:/$ find / -user bandit7 -group bandit6 -size 33c 2> /dev/null
/var/lib/dpkg/info/bandit7.password
bandit6@bandit:/$ cat /var/lib/dpkg/info/bandit7.password
HKBPTKQnIay4Fw76bEy8PVxKEDQRKTzs
```

Note: As you can see I added a `2> /dev/null` to the end of the command. While perhaps a bit outside the scope of this lab, that served to redirect all of _standard error_ to someplace else (not our terminal screen). If we didn't do that, would would have gotten `permission denied` errors clouding our screen, since we searched the entire server (we did `/`, instead of `.`) for the file.

# What's next?

As you can see, the challenges are getting a bit harder!

Bandit itself has 34 levels. As you progress the challenges will start to cover basic concepts over cryptography, networking, and system security.

With all our remaining time, feel free to work through the problems and ask mentors for advice if you need it! After tonight, try to get through as many as you can!

If you want another challenge, Over The Wire offers a wide variety of security labs. One of my favorites is [natas](http://overthewire.org/wargames/natas/), which teaches the basics of serverside web security.

# Acknowledgments

Thanks to Anuj Modi for inspiration on some of the supporting content!

Written for the April 1st, 2019 Northeastern CoSMO Meeting.
