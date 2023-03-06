---
layout: post
title: "Easy Auth with Client Certificates (Apple Watch App + Cloudflare WAF)"
date: 2023-03-06
permalink: client-cert-auth
---

## Introduction

I have an Apple watch app that I build myself and use to communicate with a service running at home.  I recently set up a [Cloudflare Tunnel](https://www.cloudflare.com/products/tunnel/) and wanted to find a way to protect that resource without needing to do complicated auth on the Apple watch (likely through some companion app which I don't have set up).  In talking with a friend, I discovered a very easy way to set up client certificates with Cloudflare as a means of authentication.  Furthermore, the certificate can be embedded directly in the watch app for maximum convenience. 

## Cloudflare Setup

As a prerequsite, ensure that your service's domain is being proxied through Cloudflare.

Next, [generate a client certificate on the Cloudflare dashboard (`SSL > Client Certificates)](https://developers.cloudflare.com/ssl/client-certificates/). From here we can download the certificate and the secret.  Make sure to enable `mTLS`, as outlined in [these docs](https://developers.cloudflare.com/ssl/client-certificates/enable-mtls/).

After generating a certificate, navigate to the Web Application Firewall (WAF) portal under `Security > WAF`.  You'll want to add a new rule that blocks when not `cf.tls_client_auth.cert_verified` for your subdomain.  

```
(http.host in {"subdomain.example.com"} and not cf.tls_client_auth.cert_verified)
```

If all is setup correctly, navigating to your service will be blocked.  To access the service, you'll now need to offer the client certificate to Cloudflare.

![1.png]({{site.url}}/assets/resources-client-cert-auth/2.png)


## App/Device Setup

### Embedding into an Apple Watch app


Using the downloaded certificate and key from Cloudflare, I generated a combined `p12` file secured by a password (keep this for later!) using the `openssl` command below.

```
openssl pkcs12 -export -out cert.p12 -in cloudflare.pem -inkey cloudflare.key
```

Then, taking inspiration from [Cloudflare's 'Client certificates Configure your Mobile app or IoT Device`](https://developers.cloudflare.com/ssl/client-certificates/configure-your-mobile-app-or-iot-device/) and a great [Swift example project by @MarcoEidinger](https://github.com/MarcoEidinger/ClientCertificateSwiftDemo) I embedded the certificate into [this apple watch app](https://github.com/joshspicer/jarvis-apple-watch).  The interesting bits are:

Reading in the certificate name (bundled into the application) and the password. These are exposded  as an extension to `Bundle` [**(src)**](https://github.com/joshspicer/jarvis-apple-watch/blob/main/Jarvis%20WatchKit%20Extension/UserCertificate.swift#L16-L35).

```swift
extension Bundle {
    var userCertificate: UserCertificate? {
        guard let filePath = Bundle.main.path(forResource: VARIABLE_INFO_FILE_PATH, ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: filePath),
              let certName = plist.object(forKey: CERTIFICATE_NAME) as? String,
              let certPassword = plist.object(forKey: CERTIFICATE_PASSWORD) as? String

        else {
            fatalError("Missing client certificate password in '\(VARIABLE_INFO_FILE_PATH)'")
        }
        
        guard let path = Bundle.main.path(forResource: certName, ofType: "p12"),
              let p12Data = try? Data(contentsOf: URL(fileURLWithPath: path))
        else {
            fatalError("Missing client certificate.")
        }
        return (p12Data, certPassword)
    }
}
```

When sending an HTTPS request, a client certificate delegate is conditionally added depending on the request being sent [**(src)**](https://github.com/joshspicer/jarvis-apple-watch/blob/main/Jarvis%20WatchKit%20Extension/JarvisModel.swift#L178-L202).

```swift
    ...
    let session = URLSession(configuration: .default, delegate: certMode == CertMode.ClientCert ? URLSessionClientCertificateHandling() : nil, delegateQueue: nil)
    
    let task = session.dataTask(with: request) {(data, response, error) in
        if let httpResponse = response as? HTTPURLResponse {
            print(httpResponse.statusCode)
            
            if queryType == QueryType.StatusCode {
                res.wrappedValue = String(httpResponse.statusCode)
                return
            }
            
            if httpResponse.statusCode > 299 {
                res.wrappedValue = "ERR (\(httpResponse.statusCode))"
                return
            }
            
            let stringResponse = String(data: data!, encoding: String.Encoding.utf8)
            res.wrappedValue = stringResponse ?? "ERR"
            
        } else {
            res.wrappedValue = "ERR"
        }
    }

    task.resume()
}
```

### Browser setup

Manually installing the certiifcate is as easy as importing into an application's certificate store.  After importing in Firefox and navigating to a WAF-protected webpage, you'll be asked once if you'd like to identify yourself with that certificate. If you do so, the Cloudflare WAF will grant you access to the resource.

![1.png]({{site.url}}/assets/resources-client-cert-auth/1.png)
