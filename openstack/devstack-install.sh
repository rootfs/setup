#!/bin/bash
DIR="/devstack"
useradd devstack
echo '%devstack    ALL=NOPASSWD: ALL' > /etc/sudoers.d/devstack

mkdir -p ${DIR}
cd ${DIR}

yum install -y -q git
git clone git://github.com/openstack-dev/devstack.git

cd devstack
cat >> local.conf <<EOF
[[local|localrc]]
FLOATING_RANGE=192.168.1.0/24
FIXED_RANGE=10.11.12.0/24
FIXED_NETWORK_SIZE=256
FLAT_INTERFACE=eth0
ADMIN_PASSWORD=devstack
MYSQL_PASSWORD=devstack
RABBIT_PASSWORD=devstack
SERVICE_PASSWORD=devstack
EOF

chown -R devstack ${DIR}
sudo -u devstack ./stack.sh
