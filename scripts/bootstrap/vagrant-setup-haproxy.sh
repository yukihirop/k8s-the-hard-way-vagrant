#!/bin/bash

set -euo pipefail

apt-get update
apt-get install -y haproxy

grep -q -F 'net.ipv4.ip_nonlocal_bind=1' /etc/sysctl.conf || echo 'net.ipv4.ip_nonlocal_bind=1' >> /etc/sysctl.conf

cat >/etc/haproxy/haproxy.cfg <<EOF
global
  log /dev/log local0
  log /dev/log local1 notice
  chroot /var/lib/haproxy
  stats socket /run/haproxy/admin.sock mode 660 level admin
  stats timeout 30s
  user haproxy
  group haproxy
  daemon
  # Default SSL material localtions
  ca-base /etc/ssl/certs
  crt-base /etc/ssl/private
  # Default ciphers to use on SSL-enabled listening sockets.
  # For more information, see ciphers(1SSL). This list is from:
  #  https://hynek.me/articles/hardening-your-web-servers-ssl-ciphers/
  ssl-default-bind-ciphers ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:ECDH+3DES:DH+3DES:RSA+AESGCM:RSA+AES:RSA+3DES:!aNULL:!MD5:!DSS
  ssl-default-bind-options no-sslv3
defaults
  log global
  mode tcp
  option tcplog
  option dontlognull
  timeout connect 5000
  timeout client  50000
  timeout server  50000
  errorfile 400 /etc/haproxy/errors/400.http
  errorfile 403 /etc/haproxy/errors/403.http
  errorfile 408 /etc/haproxy/errors/408.http
  errorfile 500 /etc/haproxy/errors/500.http
  errorfile 502 /etc/haproxy/errors/502.http
  errorfile 503 /etc/haproxy/errors/503.http
  errorfile 504 /etc/haproxy/errors/504.http
frontend k8s
  # 外部公開用アドレスが10.240.0.40
  # EXTERNAL_IP
  # KUBERNETES_PUBLIC_ADDRESS
  # load balancerのIP
  bind 10.240.0.40:6443
  default_backend k8s_backend
backend k8s_backend
  balance roundrobin
  mode tcp
  server controller-0 10.240.0.10:6443 check inter 1000
  server controller-1 10.240.0.11:6443 check inter 1000
  server controller-2 10.240.0.12:6443 check inter 1000
EOF

# https://stackoverflow.com/questions/39609178/validate-haproxy-cfg
/usr/sbin/haproxy -c -V -f /etc/haproxy/haproxy.cfg

systemctl restart haproxy
