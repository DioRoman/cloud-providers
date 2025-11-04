### Terraform

- Перейти в директорию с конфигурацией:  
  ```bash
  cd /mnt/c/Users/rlyst/GIT/cloud-providers/terraform
  ```
- Инициализировать Terraform:  
  ```bash
  terraform init
  ```
- Применить инфраструктуру:  
  ```bash
  terraform apply -auto-approve
  ```
- Удалить инфраструктуру:  
  ```bash
  terraform destroy -auto-approve
  ```

***

### Ansible

- Перейти в директорию с плейбуками:  
  ```bash
  cd /mnt/c/Users/rlyst/Netology/kubernetes/ansible
  ```
- Запустить установку MicroK8s:  
  ```bash
  ansible-playbook -i inventories/hosts.yml install-MicroK8S.yml
  ```
- Установить master-узел Kubernetes:  
  ```bash
  ansible-playbook -i inventories/hosts.yml install-master.yml
  ```
- Установить worker-узлы Kubernetes:  
  ```bash
  ansible-playbook -i inventories/hosts.yml install-node.yml
  ```

***

### MicroK8s и kubectl

- Включить Dashboard:  
  ```bash
  microk8s enable dashboard
  ```
- Применить YAML-манифест:  
  ```bash
  microk8s kubectl apply -f <файл.yaml>
  ```
- Получить список Pod-ов:  
  ```bash
  microk8s kubectl get pods
  ```
- Мониторить Pod в реальном времени:  
  ```bash
  microk8s kubectl get pods <имя-pod> --watch
  ```
- Удалить Pod:  
  ```bash
  microk8s kubectl delete pod <pod-name>
  ```
- Масштабировать Deployment:  
  ```bash
  microk8s kubectl scale deployment/<deployment-name> --replicas=<число>
  ```
- Открыть shell внутри Pod:  
  ```bash
  microk8s kubectl exec -it <pod-name> -- /bin/sh
  ```
- Пробросить порт:  
  ```bash
  microk8s kubectl port-forward service/<service-name> <локальный-порт>:<порт-сервиса>
  ```

***

### Тестирование и отладка

- Создать тестовый Pod с multitool для проверки сети:  
  ```bash
  kubectl run test-pod --image=wbitt/network-multitool --rm -it -- sh
  ```
- Проверить доступность сервиса из Pod или локально:  
  ```bash
  curl <service-name>:<порт>
  curl http://localhost:8080
  curl http://62.84.116.85/
  curl http://62.84.116.85/api
  ```

***

### Ingress

- Включить Ingress-контроллер:  
  ```bash
  microk8s enable ingress
  ```
- Посмотреть Ingress-объекты:  
  ```bash
  microk8s kubectl get ingress
  ```
- Проверить Pods Ingress контроллера:  
  ```bash
  microk8s kubectl get pods -n ingress
  ```

***

### Kubernetes (kubeadm)

- Сгенерировать конфигурацию для containerd:  
  ```bash
  sudo containerd config default > /etc/containerd/config.toml
  ```
- Удалить старый сокет containerd:  
  ```bash
  sudo rm -rf /var/run/containerd/containerd.sock
  ```
- Сбросить существующий кластер:  
  ```bash
  sudo kubeadm reset
  ```
- Инициализировать master-узел (пример с IP и дополнительными SAN):  
  ```bash
  sudo kubeadm init --apiserver-advertise-address=10.0.2.18 --pod-network-cidr=10.244.0.0/16 --apiserver-cert-extra-sans=51.250.92.109,178.154.234.213 --control-plane-endpoint=10.0.2.18
  ```
- Экспортировать kubeconfig в переменную окружения:  
  ```bash
  export KUBECONFIG=/etc/kubernetes/admin.conf
  ```
- Включить IP forwarding:  
  ```bash
  echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
  sudo sysctl -p
  ```
- Проверить статус нод и подов:  
  ```bash
  kubectl get nodes
  kubectl get pods -A
  ```
- Применить Flannel CNI:  
  ```bash
  kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
  ```
- Присоединить worker-узлы (через Ansible с передачей команды join):  
  ```bash
  ansible-playbook -i inventories/hosts.yml install-node.yml --extra-vars "kube_join_command='kubeadm join k8s-master:6443 --token ... --discovery-token-ca-cert-hash sha256:...'"
  ```

***

### SSH подключение через jump host

- Подключение к внутреннему IP через jump host:  
  ```bash
  ssh -J ubuntu@51.250.68.72 ubuntu@192.168.20.10
  ssh -J ubuntu@51.250.68.72 ubuntu@192.168.10.10
  ssh -J ubuntu@51.250.68.72 ubuntu@192.168.10.254
  ```

### Очистка known_hosts для IP (убрать старую запись)

```bash
ssh-keygen -f ~/.ssh/known_hosts -R 192.168.10.10
```

***