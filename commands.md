# 🚀 DevOps Шпаргалка: Terraform -  Ansible -  Kubernetes

## Terraform

```bash
# Перейти в директорию с конфигурацией
cd /mnt/c/Users/rlyst/GIT/cloud-providers/terraform

# Инициализировать Terraform
terraform init

# Применить инфраструктуру
terraform apply -auto-approve

# Удалить инфраструктуру
terraform destroy -auto-approve
```

***

## Ansible

```bash
# Перейти в директорию с плейбуками
cd /mnt/c/Users/rlyst/Netology/kubernetes/ansible

# Установка MicroK8s
ansible-playbook -i inventories/hosts.yml install-MicroK8S.yml

# Установка master-узла Kubernetes
ansible-playbook -i inventories/hosts.yml install-master.yml

# Установка worker-узлов Kubernetes
ansible-playbook -i inventories/hosts.yml install-node.yml
```

***

## MicroK8s и kubectl

```bash
# Включить Dashboard
microk8s enable dashboard

# Применить YAML-манифест
microk8s kubectl apply -f <файл.yaml>

# Получить список Pod-ов
microk8s kubectl get pods

# Мониторить Pod в реальном времени
microk8s kubectl get pods <имя-pod> --watch

# Удалить Pod
microk8s kubectl delete pod <pod-name>

# Масштабировать Deployment
microk8s kubectl scale deployment/<deployment-name> --replicas=<число>

# Открыть shell внутри Pod
microk8s kubectl exec -it <pod-name> -- /bin/sh

# Пробросить порт
microk8s kubectl port-forward service/<service-name> <локальный-порт>:<порт-сервиса>
```

***

## Тестирование и отладка

```bash
# Создать тестовый Pod с multitool для проверки сети
kubectl run test-pod --image=wbitt/network-multitool --rm -it -- sh

# Проверить доступность сервиса из Pod или локально
curl <service-name>:<порт>
curl http://localhost:8080
curl http://62.84.116.85/
curl http://62.84.116.85/api
```

***

## Ingress

```bash
# Включить Ingress-контроллер
microk8s enable ingress

# Посмотреть Ingress-объекты
microk8s kubectl get ingress

# Проверить Pods Ingress-контроллера
microk8s kubectl get pods -n ingress
```

***

## Kubernetes (kubeadm)

```bash
# Сгенерировать конфигурацию для containerd
sudo containerd config default > /etc/containerd/config.toml

# Удалить старый сокет containerd
sudo rm -rf /var/run/containerd/containerd.sock

# Сбросить существующий кластер
sudo kubeadm reset

# Инициализировать master-узел
sudo kubeadm init \
  --apiserver-advertise-address=10.0.2.18 \
  --pod-network-cidr=10.244.0.0/16 \
  --apiserver-cert-extra-sans=51.250.92.109,178.154.234.213 \
  --control-plane-endpoint=10.0.2.18

# Экспортировать kubeconfig в переменную окружения
export KUBECONFIG=/etc/kubernetes/admin.conf

# Включить IP forwarding
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Проверить статус нод и подов
kubectl get nodes
kubectl get pods -A

# Применить Flannel CNI
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# Присоединить worker-узлы через Ansible
ansible-playbook -i inventories/hosts.yml install-node.yml \
  --extra-vars "kube_join_command='kubeadm join k8s-master:6443 --token ... --discovery-token-ca-cert-hash sha256:...'"
```

***

## SSH через Jump Host

```bash
# Подключение к внутреннему IP через jump host
ssh -J ubuntu@51.250.68.72 ubuntu@192.168.20.10
ssh -J ubuntu@51.250.68.72 ubuntu@192.168.10.10
ssh -J ubuntu@51.250.68.72 ubuntu@192.168.10.254
```

***

## Очистка known_hosts

```bash
# Убрать старую запись
ssh-keygen -f ~/.ssh/known_hosts -R 192.168.10.10
```