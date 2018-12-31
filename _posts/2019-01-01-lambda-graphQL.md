---
layout: post
title: "Hosting a GraphQL API on AWS Lambda"
date: 2019-01-01
permalink: lambda-graphql
tags: aws mobile-dev
---

> Its been a while since i've written about Parade. I've been meaning to share my
> process of getting our GraphQL API onto Lambda for quite some time...now seems as good a time
> as any!

The API for [Parade](https://parade.events/) is written in node using, among other things, GraphQL as a query language between
our mobile client and our database. Originally I ran this API server on an ec2 instance, but factors like scalability and reliability
made me investigate the serverless approach.

## Prerequisites

- A functional node (express) server running GraphQL
- AWS account (and aws-cli configured)
- Node dependencies like babel

## The existing code

The existing code was written in ES5/6 syntax. I had to add an additional `build` command to the
scripts section of my package.json in order to instruct babel to translate the code, but not execute it. I wrote it to a folder called
`dist`.
{% highlight javascript %}
"scripts": {
"start": ...
"build": "babel server -d dist --presets es2015,stage-2",
"serve": ...
},
{% endhighlight %}

This step is important, as it allows you to decouple the following lambda proxy code from our node project. This means you can
continue to locally run your node server during development (as you probably have already been doing), but eventually can package that code up and deploy it to lambda with just a little more helper code.

## Lambda Proxy

Since i'm using express, I utilized awslab's [aws-serverless-express](https://github.com/awslabs/aws-serverless-express) package. I added this file into the root of my `/server` directory, and named it `lambda.js`. This file acts as the entry point for AWS, and will proxy all the code from API Gateway to your node instance. The path `./dist/app.js` represents the entry point into the express server we translated a moment ago.
{% highlight javascript %}
// lambda.js
'use strict';

var awsServerlessExpress = require('aws-serverless-express');
var mongoose = require('mongoose');

const app = require('./dist/app.js').default;

var server = awsServerlessExpress.createServer(app);

// Export and proxy lambda into our express server.
exports.handler = function(event, context, callback) {
context.callbackWaitsForEmptyEventLoop = false;
awsServerlessExpress.proxy(server, event, context);
};
{% endhighlight %}

## Configure Lambda and API Gateway

I created two lambda instances, one for our staging API and one for our production API. Two important fields during lambda creation to configure are `Runtime` and `Handler`, which should be set to `Node.js 8.10` and `lambda.handler`, respectively. The API Gateway should be configured to simply `{proxy+}` any http requests directly to the lambda function. I've done past lambda writeups on this, and the procedure is very similar! Make sure you configure CORS to allow requests appropriately, and don't forget to press "deploy" after configuring the API (which is buried in a menu for reasons i'll never understand).

## Deployment

The best part of this process is how easy lambda lets us update our server code. Below I wrote a simple bash script that does the following.

1. Runs our `build` command we set up
2. Zips up that destination folder along with the lambda.js (and excludes other items)
3. With `aws-cli`, pushes this lambda code to your function

Since I often need to push code to both the production and the staging APIs, the first section of the code allows me to choose between either. Note that the `$FUNCTIONNAME` must exactly match the name of the lambda function you created. Also make sure you're in the right region. Your IAM settings also need be configured appropriately.

{% highlight bash %}
#!/bin/bash

# Builds, zips, and uploads server code to AWS Lambda

# Place in root folder at SAME LEVEL as `/server`.

# aws-cli must be configured. Will use default aws account.

ZIPNAME=<ANY NAME>
REGION=<YOUR REGION>

if [ "$#" -ne 1 ]; then
echo "[-] Usage: ./deploy-server-to-lambda <prod|staging>"
exit 1
fi

case \$1 in
'prod' )
FUNCTIONNAME='prod-server' ;; # This name must exactly match the lambda func you created above.
'staging' )
FUNCTIONNAME='staging-server' ;; \* )
echo "[-] Usage: ./deploy-server-to-lambda <prod|staging>"
exit 1
;;
esac

read -p "[+] Deploying to <$FUNCTIONNAME>. Are you sure? (Y) " -n 1 -r
echo
if [[$REPLY =~ ^[Yy]$]]
then
echo "===== Running Lambda Deploy ====="
rm$ZIPNAME
rm -r dist/
yarn build &> /dev/null
echo "[+] Zipping Lambda Build..."
zip -r $ZIPNAME . -x "./server/*" &> /dev/null
rm -r dist/
echo "[+] Uploading to Lambda..."
aws lambda  update-function-code --function-name$FUNCTIONNAME --zip-file fileb://./$ZIPNAME --region$REGION | grep "LastModified" | sed -e 's/^[ \t]\*//'
echo "[+] Upload Complete."
rm \$ZIPNAME
echo "[+] Cleanup Complete."
echo "===== Finished Lambda Deploy ====="
else
echo "[-] Lambda Deploy Canceled"
fi

{% endhighlight %}

If all goes well, you'll get the "Last Modified" time printed (should be now!). Give it a few minutes, and your API should be live and accessible!
