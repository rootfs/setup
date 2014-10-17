if [ ! -f "pass.cfg" ]
then
    pass=`cat /dev/urandom | tr -dc _A-Z-a-z-0-9 | head -c${1:-8};echo`
    echo "password=${pass}" > pass.cfg
fi
source ./nodes.cfg
for i in ${nodes[@]}
do
echo $i
ssh ubuntu@${i}.front.sepia.ceph.com "mkdir -p /tmp/bd"
scp init.sh ubuntu@${i}.front.sepia.ceph.com:/tmp/bd
scp setup.sh ubuntu@${i}.front.sepia.ceph.com:/tmp/bd
scp *.jar ubuntu@${i}.front.sepia.ceph.com:/tmp/bd
scp sshpass ubuntu@${i}.front.sepia.ceph.com:/tmp/bd
scp nodes.cfg ubuntu@${i}.front.sepia.ceph.com:/tmp/bd
scp pass.cfg ubuntu@${i}.front.sepia.ceph.com:/tmp/bd
ssh -t ubuntu@${i}.front.sepia.ceph.com "cd /tmp/bd; bash init.sh"
ssh -t ubuntu@${i}.front.sepia.ceph.com "rm -rf /tmp/bd"
done
