### Terraform

- Перейти в каталог с конфигурацией:
  - `cd /mnt/c/Users/rlyst/Netology/kubernetes/terraform`
- Инициализировать Terraform:
  - `terraform init`
- Применить инфраструктуру (создать кластер):
  - `terraform apply -auto-approve`
- Удалить инфраструктуру:
  - `terraform destroy -auto-approve`

***

### Ansible

- Перейти в каталог с плейбуками:
  - `cd /mnt/c/Users/rlyst/Netology/kubernetes/ansible`
- Запустить установку MicroK8s:
  - `ansible-playbook -i inventories/hosts.yml install-MicroK8S.yml`
- Установить master-узел:
  - `ansible-playbook -i inventories/hosts.yml install-master.yml`
- Установить worker-узлы:
  - `ansible-playbook -i inventories/hosts.yml install-node.yml`

***

### MicroK8s и kubectl

- Включить Dashboard:
  - `microk8s enable dashboard`
- Применить YAML-манифест:
  - `microk8s kubectl apply -f <файл.yaml>`
- Получить список Pod-ов:
  - `microk8s kubectl get pods`
- Мониторить конкретный Pod:
  - `microk8s kubectl get pods <имя-pod> --watch`
- Удалить Pod:
  - `microk8s kubectl delete pod <pod-name>`
- Масштабировать deployment:
  - `microk8s kubectl scale deployment/<deployment-name> --replicas=<число>`
- Открыть shell в Pod:
  - `microk8s kubectl exec -it <pod-name> -- /bin/sh`
- Пробросить порт:
  - `microk8s kubectl port-forward service/<service-name> <локальный-порт>:<порт-сервиса>`

***

### Тестирование и отладка

- Создать тестовый Pod:
  - `kubectl run test-pod --image=wbitt/network-multitool --rm -it -- sh`
- Тестировать доступность сервисов (из Pod или локально):
  - `curl <service-name>:<порт>`
  - `curl http://localhost:8080`
  - `curl http://62.84.116.85/` и `curl http://62.84.116.85/api`

***

### Ingress

- Включить Ingress:
  - `microk8s enable ingress`
- Проверить объекты Ingress:
  - `microk8s kubectl get ingress`
- Проверить Pods Ingress контроллера:
  - `microk8s kubectl get pods -n ingress`

***

### Кластер Kubernetes (master/worker) через kubeadm

- Сгенерировать config для containerd:
  - `sudo containerd config default > /etc/containerd/config.toml`
- Удалить старый сокет containerd:
  - `sudo rm -rf /var/run/containerd/containerd.sock`
- Сбросить состояние кластера:
  - `sudo kubeadm reset`
- Инициализировать master-узел:
  - `sudo kubeadm init --apiserver-advertise-address=10.0.2.18 --pod-network-cidr=10.244.0.0/16 --apiserver-cert-extra-sans=51.250.92.109,178.154.234.213 --control-plane-endpoint=10.0.2.18`
- Экспортировать конфиг для kubectl:
  - `export KUBECONFIG=/etc/kubernetes/admin.conf`
- Включить IP forwarding:
  - `echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf`
  - `sysctl -p`
- Проверить статус кластера:
  - `kubectl get nodes`
  - `kubectl get pods -A`
- Применить Flannel:
  - `kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml`
- Присоединить worker (через Ansible):
  - `ansible-playbook -i inventories/hosts.yml install-node.yml --extra-vars "kube_join_command='kubeadm join k8s-master:6443 --token ... --discovery-token-ca-cert-hash sha256:...'"`
