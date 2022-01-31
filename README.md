This is an automated installation for [Microshift](https://github.com/redhat-et/microshift) Kubernetes platform.

### Installation Pre-Requisites

- Requires Fedora (tested on Fedora 35)
- Internet connectivity

### Installation

- Run the following:

```shell
curl -sfL https://raw.githubusercontent.com/nerdalert/microshift-installer/main/microshift-install.sh |  sh -s -
```

- Alternatively, pull the repo and run the script:

```shell
git clone https://github.com/nerdalert/microshift-installer.git
cd microshift-installer
./microshift-install.sh
```

### Validate the Installation

- Depending on the resources of the node, it may take a few minutes for the pods to initialize

View the running pods:

```shell
$ export KUBECONFIG=~/.kube/config

$ kubectl get pods --all-namespaces -o wide
NAMESPACE                       NAME                                  READY   STATUS    RESTARTS   AGE    IP             NODE        NOMINATED NODE   READINESS GATES
kube-system                     kube-flannel-ds-lsfdz                 1/1     Running   0          161m   192.168.1.72   cluster-a   <none>           <none>
kubevirt-hostpath-provisioner   kubevirt-hostpath-provisioner-79k7v   1/1     Running   0          160m   10.42.0.2      cluster-a   <none>           <none>
openshift-dns                   dns-default-7xgc7                     2/2     Running   0          161m   10.42.0.4      cluster-a   <none>           <none>
openshift-dns                   node-resolver-8vjf4                   1/1     Running   0          161m   192.168.1.72   cluster-a   <none>           <none>
openshift-ingress               router-default-6c96f6bc66-r7msl       1/1     Running   0          161m   192.168.1.72   cluster-a   <none>           <none>
openshift-service-ca            service-ca-7bffb6f6bf-4jpcf           1/1     Running   0          161m   10.42.0.3      cluster-a   <none>           <none>
```
- Once the pods are all in a running status, you can run the following deployment lets you test connectivity from a new pod

```shell
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: "test"
spec:
  containers:
  - name: samplepod
    command: ['sh', '-c', 'echo test container is running ; sleep 3600']
    image: busybox
    securityContext:
      privileged: true
EOF

kubectl exec --stdin --tty test -- /bin/sh
```

- For more details on the installation see the [Microshift Documentation](https://microshift.io/docs/getting-started/)

