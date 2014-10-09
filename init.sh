source pass.cfg
source nodes.cfg
#echo -n "password "
#echo $password
sudo yum install -y -q java-1.6.0-openjdk-devel.x86_64 wget
sudo groupadd hadoop
sudo useradd -c "hadoop" -d /home/hadoop -m -s /bin/bash hadoop -N -G hadoop
# if hadoop already exists, ensure env is as expected
sudo usermod -s /bin/bash -d /home/hadoop hadoop
echo "hadoop:${password}" |sudo chpasswd
sudo -u hadoop rm -rf /home/hadoop/.ssh
sudo -u hadoop ssh-keygen -f /home/hadoop/.ssh/id_rsa -t rsa -N ''
chmod 666 *jar
sudo -u hadoop cp *jar ~hadoop/
if [ ${USE_HDFS} -eq 0  ]
then
  #FIXME: remove this
  sudo chmod 644 /etc/ceph/ceph.client.admin.keyring
fi
sudo -i -u hadoop bash /tmp/bd/setup.sh
