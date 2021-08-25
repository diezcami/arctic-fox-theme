---
layout: post
title: "Spotify \"Now Playing\" v2"
date: 2021-08-25
permalink: spotify-now-playing-azure
tags: spotify azure music
---
<!-- ![1.png]({{site.url}}/assets/resources-spotify-now-playing-azure/1.png) -->


> The most astute readers of this blog would've noticed that for the past couple months, its homepage has been missing its characteristic [Josh is listening to "XXX" on Spotify]({{site.url}}/spotify-now-playing).  As the last of my student AWS credits expired, I decided it was time to move this script over to a new home.

## Goal

To show a simple message on the front page of a website/blog/etc (or even on some embedded device like a smart mirror, etc.) with the current song you're listening to on Spotify.  If you aren't currently listening, the API will fetch you last listened to song, as reported by the Spotify API.

The end result (on my blog) looks like this:

![1.png]({{site.url}}/assets/resources-spotify-now-playing-azure/1.png)

## Usage

Once deployed - fetching your currently playing music is as easy as making a GET request.  

```bash
[~]$ curl https://api.joshspicer.com/api/spotify | jq

{
  "artistName": "Bombay Bicycle Club",
  "isPlaying": false,
  "response": "Josh last listened to Home By Now by Bombay Bicycle Club on spotify.",
  "songName": "Home By Now"
}

```

On my website i'm reusing my old [piece of javascript](https://github.com/joshspicer/joshspicer.github.io/blob/master/js/pollLambdaAPI.js#L52) that parses this JSON string and writes the HTML to `<span>` on the front page of my website. Easy!

## AWS Lambda to Azure Functions

For whatever reason (the challenge?), I decided to implement my function in typescript instead of my previous implemention language of python.  

The [entrypoint](https://github.com/joshspicer/spotify-now-playing-azure/blob/main/spotify/index.ts#L140-L162) for my Azure function listens for HTTP triggers in (a GET request to my endpoint), and on execution reads in state that I store in a Table.

```typescript

const httpTrigger: AzureFunction = async function (context: Context, req: HttpRequest, cachedAuth: any): Promise<void> {

    let accessToken = cachedAuth.Token;
    const expiry = new Date(cachedAuth.Expiry)

    const now = new Date()
    if (expiry <= now) {
        accessToken = await refreshToken(context)
    }
    
    const nowPlaying: NowPlaying = await getNowPlaying(accessToken, context);

    context.res = {
        body: JSON.stringify(nowPlaying),
    };
};

export default httpTrigger;

```

Since Spotify access tokens last for 1 hour, I cache the token and only refresh it when the expiry i've stored is nearing an hour.  In that case, I invoke `refreshToken`, which then creates a service connection to the same database, refreshes my Spotify token, and then places the token in storage (and returns it to the caller)

```typescript
...

// Create table service with azure-storage SDK
var tableSvc = azure.createTableService(storageAccountName, storageKey);

// ~ fetch updated token from Spotify ~ //

var updatedTask = {
    PartitionKey: { '_': 'primary' },
    RowKey: { '_': 'auth' },
    Token: { '_': authPayload.access_token },
    // Right before this token will expire
    Expiry: {'_': date.minutesFromNow(55) }
};

tableSvc.insertOrReplaceEntity(tableName, updatedTask, function(error, result, response){
    if(error
      context.res.status = 400;
    }
    // Success
  });
```



You map each argument to the entrypoint **in order** in the [function.json](https://github.com/joshspicer/spotify-now-playing-azure/blob/main/spotify/function.json).  As I explain below, you have to pre-create the table (`database` in my case) in your created storage account (which the Azure Function extension will do for you on your first deploy).


```jsonc

{
  "bindings": [
    {
      "authLevel": "anonymous",
      "type": "httpTrigger",
      "direction": "in",
      "name": "req",
      "methods": [
        "get"
      ]
    },
    {
      "type": "http",
      "direction": "out",
      "name": "res"
    },
    {
      "name": "cachedAuth",
      "type": "table",
      "tableName": "database",
      "partitionKey": "primary",
      "rowKey": "auth",
      "connection": "AzureWebJobsStorage",
      "direction": "in"
    }
  ],
  "scriptFile": "../dist/spotify/index.js"
}
```


## Setup

The setup for this project is very straightforward, and essentially boils down to collecting the following environment variable. This time around I'm hosting this script on an Azure Function.  

The following example outlines the contents of a `local.settings.json`, which you can place untracked in the root of the project repo for local development.  You'll also need to upload these to your function's `Configuration` on the Azure portal.

```jsonc
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "DefaultEndpointsProtocol=https;AccountName=.....",
    "FUNCTIONS_WORKER_RUNTIME": "node",
    "StorageKey": "...",                   // Same key embedded in your AzureWebJobsStorage
    "RefreshToken": "...",                 // From Spotify, see spcr.me/spotify-now-playing
    "ClientIdSecret": "...",               // From Spotify, see spcr.me/spotify-now-playing
    "StorageAccountName": "...",           // The generated storage account name when you first deploy your Azure Function via the extension
    "TableName": "..."                     // Manually added table name in the "Tables" section of your storage account
  }
}
```

These variables are injected into our function as environment variables, which I then use to authenticate with the Spotify API and with the Azure Storage API.

Do check out my [older guide]({{site.url}}/spotify-now-playing) for how to generate those Spotify secrets.

### Running the code

This project has a [devcontainer](https://github.com/joshspicer/spotify-now-playing-azure/tree/main/.devcontainer), which will automatically launch into a pre-built container when opened in a [Codespace](https://codespace.new) or with the VSCode Remote Containers extension.  You'll then have all the necessary VSCode extensions (Azure Functions), required tooling (func), and runtime (node).

### Custom Domains

In the Azure portal I followed the "custom domain" prompts, `api.joshspicer.com`, as a CNAME for `spotify-now-playing.azurewebsites.net`. Following the guided setup in the portal will also generate you a free SSL certificate.

### Cors

Again in the Azure portal, be sure to modify your CORS settings if any other webpage is going to invoke your API cross-domain.  My website `https://joshspicer.com` invokes this domain, so I simply added that entire URI to the cors list, and it instantly worked.  This was _so_ much easier to fix than it was on AWS 3+ years ago.



