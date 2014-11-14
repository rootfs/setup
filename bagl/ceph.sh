#!/bin/sh
source ./nodes.cfg
source ./pass.cfg
install_opt="--dev giant"
public_net_opt="public network = 172.18.40.0/24"
cluster_net_opt="cluster network = 172.18.40.0/24"


rm -rf ~/.ssh/
ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ''
cat > ~/.ssh/config <<EOF
Host *
   StrictHostKeyChecking no
   UserKnownHostsFile=/dev/null
EOF

# on each node, install required rpms. This is a problem with ceph-deploy. Need to resolve dependencies.  
rpm -Uvh http://ceph.com/rpm/rhel7/noarch/ceph-release-1-0.el7.noarch.rpm  
rpm -Uvh http://ceph.com/rpm/rhel7/noarch/python-itsdangerous-0.23-1.el7.noarch.rpm  
rpm -Uvh http://ceph.com/rpm/rhel7/noarch/python-werkzeug-0.9.1-1.el7.noarch.rpm  
yum install python-jinja2 -y  
rpm -Uvh http://ceph.com/rpm/rhel7/noarch/python-flask-0.10.1-3.el7.noarch.rpm  

 #on admin node, create ssh key and deploy on all nodes  
cluster=""
for i in ${nodes[@]}
do
    echo $i
    cluster=`echo -n $i $cluster`
    ./sshpass -p ${password} ssh-copy-id $i  
done

# clean up ceph installation first
for i in ${nodes[@]}
do
    ssh root@${i} /etc/init.d/ceph killall
done

ceph-deploy purge ${cluster}
ceph-deploy forgetkeys
for i in ${nodes[@]}
do
    ssh root@${i} "/etc/init.d/ceph killall; umount /var/lib/ceph/osd/ceph-*; rm -rf /var/lib/ceph; rm -rf /var/run/ceph"
done


# choose the last node as mds
mds=$i

#on admin node, deploy ceph on all nodes  
if [ `hostname` == ${mds} ] 
then
    yum install -y ceph-deploy  
    ceph-deploy install ${install_opt} ${cluster}
    #create ceph cluster  
    ceph-deploy new ${mds}  
    ceph-deploy  --overwrite-conf mon create-initial ${mds}
    ceph-deploy  --overwrite-conf mon create ${mds}
    ceph-deploy gatherkeys ${mds}  
    ceph-deploy --overwrite-conf admin ${cluster}

#create ceph osd  
    for i in ${nodes[@]}
    do
        ceph-deploy disk zap ${i}:sd{c,d,e,f,g,h,i,j,k,l,m}
        ceph-deploy osd create ${i}:sd{c,d,e,f,g,h,i,j}:sd{k,l,m}
    done
    
#start ceph on all nodes  
    for i in ${nodes[@]}
    do
        echo $i
        ssh root@${i} "echo ${public_net_opt} >> /etc/ceph/ceph.conf"
        ssh root@${i} "echo ${cluster_net_opt} >> /etc/ceph/ceph.conf"
        ssh root@${i} service ceph restart
    done
    
#see if we are ready to go  
#osd tree should show all osd are up  
    ceph osd tree  
#ceph health should be clean+ok  
    ceph health  
    
#create ceph mds  
    ceph-deploy mds create ${mds}
#create pool called bd  
    ceph osd pool create bd 1600  
#see if the pool is ok  
    rados -p bd ls  
#create a file in the pool  
#rados -p bd put group /etc/group  
#see if the file is created  
#rados -p bd ls  

    # install jni
    for i in ${nodes[@]}
    do
        echo $i
        ssh root@${i} yum install -y libcephfs_jni1
    done

    ceph osd pool create cephfs_data 4096
    ceph osd pool create cephfs_metadata 4096
    ceph fs new cephfs cephfs_metadata cephfs_data

#mount ceph fs  
    yum install -y ceph-fuse  
    mkdir -p /mnt/ceph 
    umount /mnt/ceph 
    pkill -9 ceph-fuse
    timeout 60s ceph-fuse -m ${mds}:6789 /mnt/ceph  
    ret=$?
    echo "mount status " ${ret}
#should see cephfs mounted  
    mount  

fi # if mds