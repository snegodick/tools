#!/bin/bash
apt update; apt upgrade -y; apt install htop docker docker-compose curl -y; mkdir openvpn-docker && cd openvpn-docker;
cat >> ./docker-compose.yml <<-EOF
version: '3.8'

services:
  openvpn:
    image: kylemanna/openvpn:2.4
    container_name: openvpn-server
    ports:
      - "1194:1194/udp"
    cap_add:
      - NET_ADMIN
    volumes:
      - ./openvpn-data:/etc/openvpn
    environment:
      - "OVPN_SERVER_PORT=1194"
      - "OVPN_PROTO=udp"
    command: ovpn_run
    restart: unless-stopped
volumes:
  openvpn-data:
EOF

export ip=`curl -s -4 ifconfig.me`;
docker-compose run --rm openvpn ovpn_genconfig -u udp://$ip:1194 && \
docker-compose run --rm -e EASYRSA_BATCH=1 openvpn ovpn_initpki nopass && \
docker-compose up -d && \
docker-compose run --rm openvpn easyrsa build-client-full CLIENT1 nopass && \
docker-compose run --rm openvpn ovpn_getclient CLIENT1 > CLIENT1.ovpn;
echo "duplicate-cn" >> /root/openvpn-docker/openvpn-data/openvpn.conf && docker restart openvpn-server;
echo '### CLIENT CONFIG ################################################################'
cat CLIENT1.ovpn
