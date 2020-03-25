#!/usr/bin/env bash

DOMAIN=consul
HOST=$(hostname)

set -x

# kill vault
killall vault &>/dev/null

sleep 5

# Create vault configuration
mkdir -p /etc/vault.d
mkdir -p /opt
# create vault user
sudo useradd --system --home /etc/vault.d --shell /bin/false vault
# /opt must be owned by vault user 
sudo chown vault:vault /opt

sudo tee /etc/vault.d/config.hcl > /dev/null << EOF
listener "tcp" {
  address          = "0.0.0.0:8200"
  cluster_address  = "172.31.16.41:8201"
  tls_disable      = "true"
}

storage "consul" {
  address = "172.31.16.31:8500"
  path    = "vault/"
}

ui = true
api_addr = "http://172.31.16.41:8200"
EOF

sudo tee /etc/vault.d/vault.hcl > /dev/null << EOF
path "sys/mounts/*" {
  capabilities = [ "create", "read", "update", "delete", "list" ]
}

# List enabled secrets engine
path "sys/mounts" {
  capabilities = [ "read", "list" ]
}

# Work with pki secrets engine
path "pki*" {
  capabilities = [ "create", "read", "update", "delete", "list", "sudo" ]
}
EOF

# setup .bashrc
grep VAULT_ADDR ~/.bashrc || {
  echo export VAULT_ADDR=http://127.0.0.1:8200 | sudo tee -a ~/.bashrc
}

source ~/.bashrc
##################
# starting vault #
##################
vault -autocomplete-install
complete -C /usr/local/bin/vault vault
sudo setcap cap_ipc_lock=+ep /usr/local/bin/vault

# Create a Vault service file at /etc/systemd/system/vault.service
sudo cat << EOF >/etc/systemd/system/vault.service
[Unit]
Description="HashiCorp Vault - A tool for managing secrets"
Documentation=https://www.vaultproject.io/docs/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/vault.d/config.hcl

[Service]
User=vault
Group=vault
ProtectSystem=full
ProtectHome=read-only
PrivateTmp=yes
PrivateDevices=yes
SecureBits=keep-caps
AmbientCapabilities=CAP_IPC_LOCK
Capabilities=CAP_IPC_LOCK+ep
CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
NoNewPrivileges=yes
ExecStart=/usr/local/bin/vault server -config=/etc/vault.d/config.hcl 
ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
KillSignal=SIGINT
Restart=on-failure
RestartSec=5
TimeoutStopSec=30
StartLimitIntervalSec=60
StartLimitBurst=3

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl start vault
echo vault started

sleep 3 

# Initialize Vault
sudo mkdir -p /opt/token
VAULT_ADDR="http://127.0.0.1:8200" vault operator init -key-shares=1 -key-threshold=1 > /opt/token/keys.txt
VAULT_ADDR="http://127.0.0.1:8200" vault operator unseal $(cat /opt/token/keys.txt | grep "Unseal Key 1:" | cut -c15-)
# vault operator unseal $(cat /opt/token/keys.txt | grep "Unseal Key 2:" | cut -c15-)
# vault operator unseal $(cat /opt/token/keys.txt | grep "Unseal Key 3:" | cut -c15-)
VAULT_ADDR="http://127.0.0.1:8200" vault login $(cat /opt/token/keys.txt | grep "Initial Root Token:" | cut -c21-)

# enable secret KV version 1
VAULT_ADDR="http://127.0.0.1:8200" vault secrets enable -version=1 kv

# setup .bashrc
grep VAULT_TOKEN ~/.bashrc || {
  echo export VAULT_TOKEN=\`cat /home/ubuntu/.vault-token\` | sudo tee -a ~/.bashrc
}

# Sealing Vault 
VAULT_ADDR="http://127.0.0.1:8200" vault operator seal
set +x
echo -e "Unseal key: \n \n`cat /opt/token/keys.txt | grep "Unseal Key 1:" | cut -c15-` \n \nUse the following Token to login: \n \n`cat /opt/token/keys.txt | grep "Initial Root Token:" | cut -c21-`"
