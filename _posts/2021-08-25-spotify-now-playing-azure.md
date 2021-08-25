---
layout: post
title: "Spotify "Now Playing" v2"
date: 2021-08-25
permalink: spotify-now-playing-azure
tags: spotify aws music
---
<!-- ![1.png]({{site.url}}/assets/resources-spotify-now-playing-azure/1.png) -->


The most astute readers of this blog would've noticed that for the past couple months, its homepage has been missing its characteristic [Josh is listening to "XXX" on Spotify]({{site.url}}/spotify-now-playing). As my final AWS credits from "student-hood" expired, I decided it was time to move this script over to a new home.  

Functionally, the new project you'll find [**on GitHub**](https://github.com/joshspicer/spotify-now-playing-azure) is nearly identical, but now it's packaged into an easily to deploy [Azure Function](https://docs.microsoft.com/en-us/azure/azure-functions/functions-overview).  All you need is to gather some Spotify secrets, and press the deploy button in the VSCode extension.

![1.png]({{site.url}}/assets/resources-spotify-now-playing-azure/1.png)


## Setup

1. Clone repo and open in either Codespaces or VSCode Remote containers
    1. This will drop you in a container with the necessary VSCode extension (Azure Functions), the required tooling (`func`), and the runtime (`node`).
    1. Run `yarn` once after any postcreate steps have completed.
1. Create your Spotify developer account and get your client secret/refresh token - like outlined in my [old guide](https://joshspicer.com/spotify-now-playing).
1. Deploy with the VSCode 'Azure Functions' extension.
    1. Select 'anonymous' access
    1. Do create a storage account
1. In the Azure Portal, navigate to your newly created storage account
    1. Manually create a table with whatever `TableName` you'd like
    1. Copy the `StorageKey` out
    1. Fill in `StorageKey`, `StorageAccountName`, and `TableName` in your Azure Function's settings (and local settings if you want to debug)
1. On the Azure Portal navigate to your Function app's "Configuration" page.
    1. Add all the secrets into your configuration by hitting the `+ New application setting` button.  These secrets are exposed as environment variables to the node application at runtime.


### Local Testing

For local testing, place all your environment variables into a file named `local.settings.json`, like so.  All of these secrets should also exist in your Function app's "Configuration".

### `local.settings.json`

```
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "DefaultEndpointsProtocol=https;AccountName=.....",
    "FUNCTIONS_WORKER_RUNTIME": "node",
    "StorageKey": "...",
    "RefreshToken": "...",
    "ClientIdSecret": "...",
    "StorageAccountName": "...",
    "TableName": "..."
  }
}
```

Then run `yarn start` in the root directory.
