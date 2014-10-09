if [ ! -f "pass.cfg" ]
then
    pass=`cat /dev/urandom | tr -dc _A-Z-a-z-0-9 | head -c${1:-8};echo`
    echo "password=${pass}" > pass.cfg
    echo "remote_pass=" >> pass.cfg
fi
source ./nodes.cfg
for i in ${nodes[@]}
do
echo $i
sshpass -p redhat ssh root@${i} "mkdir -p /tmp/bd"
for f in "init.sh" "setup.sh" "*.jar" "sshpass" "nodes.cfg" "pass.cfg"
do 
    sshpass -p ${remote_pass} scp $f root@${i}:/tmp/bd
done
sshpass -p ${remote_pass} ssh -t root@${i} "cd /tmp/bd; bash init.sh"
sshpass -p ${remote_pass} ssh -t root@${i} "rm -rf /tmp/bd"
done
