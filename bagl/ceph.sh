#!/bin/sh
source ./nodes.cfg
source ./pass.cfg

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

# choose the last node as mds
mds=$i

#on admin node, deploy ceph on all nodes  
if [ `hostname` == ${mds} ] 
then
    yum install -y ceph-deploy  
    ceph-deploy install ${cluster}
    #create ceph cluster  
    ceph-deploy new ${mds}  
    ceph-deploy mon create ${mds}
    ceph-deploy gatherkeys ${mds}  
    ceph-deploy admin ${cluster}

#create ceph osd  
    for i in ${nodes[@]}
    do
        ceph-deploy disk zap ${i}:sd{c,d,e,f,g,h,i,j,k,l,m}
        ceph-deploy osd create ${i}:sd{c,d,e,f,g,h,i,j,k,l,m}
    done
    
#start ceph on all nodes  
    for i in ${nodes[@]}
    do
        echo $i
        ssh root@${i} service ceph start
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
#mount ceph fs  
    yum install -y ceph-fuse  
    mkdir -p /mnt/ceph && ceph-fuse -m ${mds}:6789 /mnt/ceph  
    
#should see cephfs mounted  
    mount  
fi # if mds