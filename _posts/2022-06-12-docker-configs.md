---
layout: post
title: "Home Docker Config(s)"
date: 2022-06-12
permalink: docker-configs
---

<!-- ![1.png]({{site.url}}/assets/resources-docker-config/1.png) -->

## Pi-hole & Cloudflared (DoH)

My network's DNS traffic gets routed through a local Pi-Hole instance with its upstream DNS server proxied by [cloudflared](https://github.com/cloudflare/cloudflared) to several public DNS over HTTP services.

This config is inspired by [this blog post](http://mroach.com/2020/08/pi-hole-and-cloudflared-with-docker).

```yaml
version: "3"

services:
  cloudflared:
    container_name: cloudflared
    image: cloudflare/cloudflared
    command: proxy-dns
    environment:
      - "TUNNEL_DNS_UPSTREAM=https://1.1.1.1/dns-query,https://1.0.0.1/dns-query,https://9.9.9.9/dns-query,https://149.112.112.9/dns-query"
      - "TUNNEL_DNS_PORT=5053"
      - "TUNNEL_DNS_ADDRESS=0.0.0.0"
    restart: unless-stopped
    networks:
      pihole_net:
        ipv4_address: 10.0.0.2

  pi-hole:
    container_name: pi-hole
    image: pihole/pihole
    restart: unless-stopped
    ports:
      - "8053:80/tcp"
      - "53:53/tcp"
      - "53:53/udp"
    environment:
      - ServerIP=10.0.0.3
      - DNS1=10.0.0.2#5053
      - DNS2='no'
      - IPv6=false
      - TZ=America/New_York
      - DNSMASQ_LISTENING=all
    networks:
      pihole_net:
        ipv4_address: 10.0.0.3
    dns:
      - 127.0.0.1
      - 1.1.1.1
    volumes:
      - "/etc/app-data/pihole-cloudflared/config:/etc/pihole/"
      - "/mnt/app-data/pihole-cloudflared/dnsmasq:/etc/dnsmasq.d/"
    cap_add:
      - NET_ADMIN

networks:
  pihole_net:
    driver: bridge
    ipam:
      config:
        - subnet: 10.0.0.0/29
```

## Unifi Controller

I run my Unifi controller in a docker container.

I get my compose file from [jacobalberty/unifi-docker](https://github.com/jacobalberty/unifi-docker).

```yaml
version: "2.3"
services:
  mongo:
    image: mongo:3.6
    container_name: ${COMPOSE_PROJECT_NAME}_mongo
    networks:
      - unifi
    restart: always
    volumes:
      - db:/data/db
      - dbcfg:/data/configdb
  controller:
    image: "jacobalberty/unifi:${TAG:-latest}"
    container_name: ${COMPOSE_PROJECT_NAME}_controller
    depends_on:
      - mongo
    init: true
    networks:
      - unifi
    restart: always
    volumes:
      - dir:/unifi
      - data:/unifi/data
      - log:/unifi/log
      - cert:/unifi/cert
      - init:/unifi/init.d
      - run:/var/run/unifi
      # Mount local folder for backups and autobackups
      - ./backup:/unifi/data/backup
    user: unifi
    sysctls:
      net.ipv4.ip_unprivileged_port_start: 0
    environment:
      DB_URI: mongodb://mongo/unifi
      STATDB_URI: mongodb://mongo/unifi_stat
      DB_NAME: unifi
    ports:
      - "3478:3478/udp" # STUN
      - "6789:6789/tcp" # Speed test
      - "8080:8080/tcp" # Device/ controller comm.
      - "8443:8443/tcp" # Controller GUI/API as seen in a web browser
      - "8880:8880/tcp" # HTTP portal redirection
      - "8843:8843/tcp" # HTTPS portal redirection
      - "10001:10001/udp" # AP discovery
  logs:
    image: bash
    container_name: ${COMPOSE_PROJECT_NAME}_logs
    depends_on:
      - controller
    command: bash -c 'tail -F /unifi/log/*.log'
    restart: always
    volumes:
      - log:/unifi/log

volumes:
  db:
  dbcfg:
  data:
  log:
  cert:
  init:
  dir:
  run:

networks:
  unifi:
```
