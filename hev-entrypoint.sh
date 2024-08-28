#!/bin/sh

TUN="${TUN:-tun0}"
MTU="${MTU:-9000}"
IPV4="${IPV4:-198.18.0.1}"
IPV6="${IPV6:-}"

MARK="${MARK:-438}"

SOCKS5_ADDR="${SOCKS5_ADDR:-172.17.0.1}"
SOCKS5_PORT="${SOCKS5_PORT:-1080}"
SOCKS5_USERNAME="${SOCKS5_USERNAME:-}"
SOCKS5_PASSWORD="${SOCKS5_PASSWORD:-}"
SOCKS5_UDP_MODE="${SOCKS5_UDP_MODE:-udp}"

LOG_LEVEL="${LOG_LEVEL:-warn}"

config_file() {
  cat > /hs5t.yml << EOF
misc:
  log-level: '${LOG_LEVEL}'
tunnel:
  name: '${TUN}'
  mtu: ${MTU}
  ipv4: '${IPV4}'
  ipv6: '${IPV6}'
  post-up-script: '/route.sh'
socks5:
  address: '${SOCKS5_ADDR}'
  port: ${SOCKS5_PORT}
  udp: '${SOCKS5_UDP_MODE}'
  mark: ${MARK}
EOF

  if [ -n "${SOCKS5_USERNAME}" ]; then
      echo "  username: '${SOCKS5_USERNAME}'" >> /hs5t.yml
  fi

  if [ -n "${SOCKS5_PASSWORD}" ]; then
      echo "  password: '${SOCKS5_PASSWORD}'" >> /hs5t.yml
  fi
}

config_route() {
  echo "#!/bin/sh" > /route.sh
  chmod +x /route.sh

  echo "ip route del default" >> /route.sh
  echo "ip route add default via ${IPV4} dev ${TUN} metric 1" >> /route.sh
  echo "ip route add default via $(ip -o -f inet address show eth0 | awk '/scope global/ {print $4}' | cut -d/ -f1) dev eth0 metric 10" >> /route.sh
}

run() {
  config_file
  config_route
  echo "echo 1 > /success" >> /route.sh
  hev-socks5-tunnel /hs5t.yml
}

run || exit 1
