---
layout: post
title: "AWS ec2 Auto Deploy Scripts"
date: 2018-10-08
permalink: aws-deploy
---

Over the past few months i've really gained a lot of experience working with
AWS, whether it be through CCDC, Parade, or other personal projects.

Recently, I was asked to write a script to automatically deploy a new copy
of some predefined service (as an example, a webserver). I was asked to host
this service on an ec2 instance. I've gotten decently familiar with the aws-cli
lately - hopefully this script can help someone else trying to accomplish
a similar task!

<script src="https://gist.github.com/joshspicer/39fd9aa423aca17ef0703b60416920b0.js"></script>

I also created a destroy script, that terminates this created instance.

<script src="https://gist.github.com/joshspicer/db1fcec8988afd36a320062570eca219.js"></script>
