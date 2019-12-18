#!/bin/bash

set -e

kubelet_unit_path="/usr/lib/systemd/system/kubelet.service"
kubelet_conf_path="/etc/kubernetes/kubelet"

kubelet_unit='[Unit]
Description=kubelet

[Service]
Environment=QCLOUD_NORM_URL=
EnvironmentFile=-/etc/kubernetes/kubelet
ExecStart=/usr/bin/kubelet ${MAX_PODS} ${CLOUD_CONFIG} ${NON_MASQUERADE_CIDR} ${KUBECONFIG} ${EVICTION_HARD} ${KUBE_RESERVED} ${FAIL_SWAP_ON} ${CLIENT_CA_FILE} ${CLUSTER_DNS} ${CLUSTER_DOMAIN} ${NETWORK_PLUGIN} ${ALLOW_PRIVILEGED} ${HOSTNAME_OVERRIDE} ${V} ${POD_INFRA_CONTAINER_IMAGE} ${AUTHENTICATION_TOKEN_WEBHOOK} ${IMAGE_PULL_PROGRESS_DEADLINE} ${CLOUD_PROVIDER} ${CNI_BIN_DIR} ${REGISTER_SCHEDULABLE} ${ANONYMOUS_AUTH} ${AUTHORIZATION_MODE} ${SYSTEM_RESERVED} ${EVENT_STORAGE_EVENT_LIMIT} ${EVENT_STORAGE_AGE_LIMIT} ${ENABLE_DEBUGGING_HANDLERS} ${ALSOLOGTOSTDERR} ${LOGTOSTDERR} ${LOG_DIR} ${ENABLE_SERVER} ${EXPERIMENTAL_BOOTSTRAP_KUBECONFIG} ${CPU_MANAGER_POLICY} ${ROOT_DIR}
ExecStartPost=-/bin/bash /etc/kubernetes/deny-tcp-port-10250.sh
Restart=always
RestartSec=10
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target'

declare -A kubelet_paras=(
  ["ROOT_DIR"]="--root-dir=/media/disk1/kcs_node/k8s/data"
  ["LOG_DIR"]="--log-dir=/var/log/kubernetes"
  ["LOGTOSTDERR"]="--logtostderr=false"
  ["ALSOLOGTOSTDERR"]="--alsologtostderr=true"
  ["CLUSTER_DOMAIN"]="--cluster-domain=kcs.tx1.yz"
  ["CPU_MANAGER_POLICY"]="--cpu-manager-policy=static"
  ["ENABLE_DEBUGGING_HANDLERS"]="--enable-debugging-handlers=true"
  ["ENABLE_SERVER"]="--enable-server=true"
  ["EXPERIMENTAL_BOOTSTRAP_KUBECONFIG"]="--experimental-bootstrap-kubeconfig=/etc/kubernetes/bootstrap.kubeconfig"
  ["EVICTION_HARD"]="--eviction-hard=memory.available<2Gi"
  ["EVENT_STORAGE_AGE_LIMIT"]="--event-storage-age-limit=default=2h"
  ["EVENT_STORAGE_EVENT_LIMIT"]="--event-storage-event-limit=default=1000"
  ["KUBE_RESERVED"]="--kube-reserved=cpu=500m,memory=4Gi,ephemeral-storage=8Gi"
  ["SYSTEM_RESERVED"]="--system-reserved=cpu=500m,memory=4Gi,ephemeral-storage=8Gi"
)

update_kubelet_unit(){
	cat <<EOF > ${kubelet_unit_path}
${kubelet_unit}
EOF
}

update_kubelet_conf(){
	for key in ${!kubelet_paras[@]}; do
	    if grep -q -w ${key} ${kubelet_conf_path} ; then
	        sed -i "/\<${key}\>/ d" $kubelet_conf_path
	    fi
	    echo "${key}=${kubelet_paras[${key}]}" >> $kubelet_conf_path
	done
}


mkdir -p /var/log/kubernetes
update_kubelet_conf
update_kubelet_unit
systemctl daemon-reload
systemctl restart kubelet.service


host_init(){
    node_ips=(`ip addr show | grep inet | egrep  'eth|bond' | grep -v inet6 |   grep  -v docker | grep brd | awk '{print $2}' | cut -f1 -d '/'`)
    host_name=$(hostname)
    if [[ `cat  /etc/sysconfig/network | grep HOSTNAME` != '' ]];then
        sed -i "s#^HOSTNAME=.*#HOSTNAME=$host_name#g" /etc/sysconfig/network
    else 
        echo "HOSTNAME=$host_name"   >> /etc/sysconfig/network
    fi    
    
    echo "127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4" > /etc/hosts
    echo "::1         localhost localhost.localdomain localhost6 localhost6.localdomain6" >> /etc/hosts
    echo  "$node_ips    $host_name" >> /etc/hosts
}

host_init


if [[ -d /data_bak ]]
then
 rm -rf /data_bak
fi 

file="/etc/resolv.conf"
chattr -i $file
echo -e "nameserver 10.72.1.2\nnameserver 10.72.1.7\noptions timeout:1\noptions attempts:1" > /etc/resolv.conf

rsync -avz /root/fordata /media/disk1/fordata
rm -rf  /data
ln -s  /media/disk1/fordata /data
chown -R web_server:web_server /data


echo "mv kuaishou.repo to /etc/yum.repo.d/"
cp /etc/kuaishou.yum.d/Kuaishou_CentOS.repo /etc/yum.repos.d/Kuaishou_CentOS.repo

echo "run control.sh"
su - ksp -c "cd /home/pcs-plugins/infra-rpcmonitor-agent/latest && nohup bash bin/control.sh start > /tmp/rpc.log  2>&1 &"

echo "Disable root login"
rsync  -avz   /root/sshd_config  /etc/ssh/sshd_config
systemctl   restart sshd.service

curl -o /tmp/init_dns_rms.py  http://download.corp.kuaishou.com/opbin/init_dns_rms.py
cd /tmp/ && python init_dns_rms.py --idc_room 205 --node public.private_clouds.kcs-cluster.node.kcs-txyun-hb --user zhangjian

sudo systemctl stop ntpd.service
sudo systemctl disable ntpd.service
sudo systemctl restart chronyd.service


echo "net.ipv4.ip_local_reserved_ports = 1991,1992,1999,2222,6600-6620,20000-21000" >> /etc/sysctl.conf
sysctl -p

#public-bj3-kcs-node{R:501}.txyz.hb1.kwaidc.com
#public-bj3-kcs-node501.txyz.hb1.kwaidc.com
# /media/disk1
# /media/disk1/docker 
#PRODENV=HOSTENVTYPE 
#RS=HOSTMODELTYPE
#RS2=HOSTMODELTYPE
#TXYZ==USER_LABEL_VALUE