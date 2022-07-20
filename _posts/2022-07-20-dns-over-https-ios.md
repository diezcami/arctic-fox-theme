---
layout: post
title: "DNS over HTTPS in iOS"
date: 2022-07-20
permalink: dns-over-https-ios
---

I recently discovered [Paul Miller's](https://paulmillr.com/posts/encrypted-dns/) blog post and [repo](https://github.com/paulmillr/encrypted-dns) sharing how to craft iOS configuration profiles that instruct iOS (or macOS/tvOS/watchOS/etc) to use a provided DNS over HTTPS (DoH) or DNS over TLS (DoT) server for encrypted DNS requests.  This method doesn't require any app or background VPN to forward requests.

To try it yourself, either directly download the pre-crafted profiles from Paul's GitHub repo above, or use the configuration below as a template.  To apply to your phone create a `dns.mobileconfig` file from the configuration and airdrop it to your iPhone!

When on my local network I prefer to use my local network's DNS resolver, so I have an exception below to not activate the profile on `$YOUR_WIFI_NETWORK`.  Replace that with your network's SSID.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
	<dict>
		<key>PayloadDisplayName</key>
		<string>Cloudflare DNS over HTTPS</string>
		<key>PayloadOrganization</key>
		<string>com.joshspicer.encrypted-dns</string>
		<key>PayloadDescription</key>
		<string>This profile enables Cloudflare (1.1.1.1) DNS over HTTPS on all networks.</string>
		<key>ConsentText</key>
		<dict>
			<key>default</key>
			<string>Privacy policy:
https://developers.cloudflare.com/1.1.1.1/privacy/public-dns-resolver</string>
		</dict>
		<key>PayloadIdentifier</key>
		<string>5d6101a6-c75b-40b6-9a37-50db99bff334</string>
		<key>PayloadScope</key>
		<string>User</string>
		<key>PayloadType</key>
		<string>Configuration</string>
		<key>PayloadUUID</key>
		<string>c403fe38-50b5-4984-8d2d-419c2781e826</string>
		<key>PayloadVersion</key>
		<integer>1</integer>
		<key>PayloadContent</key>
		<array>
			<dict>
				<key>DNSSettings</key>
				<dict>
					<key>DNSProtocol</key>
					<string>HTTPS</string>
					<key>ServerAddresses</key>
					<array>
						<string>1.1.1.1</string>
						<string>2606:4700:4700::1111</string>
						<string>1.0.0.1</string>
						<string>2606:4700:4700::1001</string>
					</array>
					<key>ServerURL</key>
					<string>https://cloudflare-dns.com/dns-query</string>
				</dict>
				<key>PayloadType</key>
				<string>com.apple.dnsSettings.managed</string>
				<key>PayloadIdentifier</key>
				<string>18cbf057-085f-4e94-bf2d-0b107f828f1e</string>
				<key>PayloadUUID</key>
				<string>437e0b2d-6636-4c75-9e92-ecd1fc5444e5</string>
				<key>PayloadDisplayName</key>
				<string>Cloudflare (1.1.1.1) DNS over HTTPS</string>
				<key>PayloadVersion</key>
				<integer>1</integer>
			</dict>
		</array>
		<key>OnDemandRules</key>
		<array>
			<dict>
				<key>Action</key>
				<string>Connect</string>
				<key>InterfaceTypeMatch</key>
				<string>Cellular</string>
			</dict>
			<dict>
				<key>Action</key>
				<string>Disconnect</string>
				<key>SSIDMatch</key>
				<array>
					<string>$YOUR_WIFI_NETWORK</string>
				</array>
			</dict>
			<dict>
				<key>Action</key>
				<string>Connect</string>
				<key>URLStringProbe</key>
				<string>http://captive.apple.com/hotspot-detect.html</string>
			</dict>
		</array>
	</dict>
</plist>
```

All these properties and more are explained in [Apple's documentation](https://developer.apple.com/documentation/devicemanagement/dnssettings).
