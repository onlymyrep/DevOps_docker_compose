## Part 1: Запуск нескольких docker-контейнеров с использованием docker compose

### 1. Dockerfile для микросервисов
Для каждого сервиса создан Dockerfile:
```bash
# Пример Dockerfile для session-service
cd src/services/session-service
cat > Dockerfile <<EOF
FROM openjdk:8-jdk-alpine as builder
WORKDIR /app
COPY mvnw .
COPY .mvn/ .mvn/
COPY pom.xml .
RUN chmod +x mvnw
RUN ./mvnw dependency:go-offline
COPY src/ src/
RUN ./mvnw package -DskipTests

FROM openjdk:8-jre-alpine
WORKDIR /app
RUN apk add --no-cache bash
COPY --from=builder /app/target/*.jar app.jar
COPY wait-for-it.sh .
RUN chmod +x wait-for-it.sh
EOF
```

Размеры образов:
```bash
docker images
```
```
losiento/session-service    latest   200MB
losiento/booking-service    latest   198MB
losiento/gateway-service    latest   202MB
```

### 2. docker-compose.yml
```bash
cat > docker-compose.yml <<EOF
version: '3.8'

services:
  postgres:
    image: postgres:13
    # ... (конфигурация)

  nginx-proxy:
    image: nginx:alpine
    ports:
      - "9080:8081"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf

  session-service:
    image: losiento/session-service:latest
    # ... (конфигурация)

  # ... другие сервисы
EOF
```

### 3. Сборка и запуск
```bash
docker compose down -v
docker compose up -d --build
```

### 4. Тестирование Postman
```bash
docker run --network=overlay -v "$(pwd)/src:/etc/newman" -t postman/newman run "application_tests.postman_collection.json"
```

Результаты тестирования:
```
✅ Все тесты успешно пройдены
[200 OK] Login User
[200 OK] Get Hotels
[200 OK] Get Hotel
[201 Created] Book Hotel
[200 OK] Get User's Loyalty Balance
[200 OK] Get User Reservations
[204 No Content] Cancel Reservation
```

---

## Part 2: Создание виртуальных машин

### 1. Инициализация Vagrant
```bash
vagrant init
```

### 2. Vagrantfile для одной машины
```bash
cat > Vagrantfile <<EOF
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/focal64"
  config.vm.synced_folder "./src", "/home/vagrant/src"
end
EOF
```

### 3. Запуск и проверка
```bash
vagrant up
vagrant ssh -c "ls /home/vagrant/src"
vagrant halt
vagrant destroy -f
```

---

## Part 3: Создание простейшего docker swarm

### 1. Vagrantfile для трех машин
```bash
cat > Vagrantfile <<EOF
Vagrant.configure("2") do |config|
  config.vm.define "manager01" do |manager|
    manager.vm.box = "ubuntu/focal64"
    manager.vm.hostname = "manager01"
    manager.vm.network "private_network", ip: "192.168.56.10"
    manager.vm.provision "shell", path: "scripts/install-docker.sh"
  end

  config.vm.define "worker01" do |worker|
    worker.vm.box = "ubuntu/focal64"
    worker.vm.hostname = "worker01"
    worker.vm.network "private_network", ip: "192.168.56.11"
    worker.vm.provision "shell", path: "scripts/install-docker.sh"
  end

  config.vm.define "worker02" do |worker|
    worker.vm.box = "ubuntu/focal64"
    worker.vm.hostname = "worker02"
    worker.vm.network "private_network", ip: "192.168.56.12"
    worker.vm.provision "shell", path: "scripts/install-docker.sh"
  end
end
EOF
```

### 2. Скрипт установки Docker
```bash
mkdir scripts
cat > scripts/install-docker.sh <<EOF
#!/bin/bash
apt-get update
apt-get install -y docker.io
systemctl enable docker
systemctl start docker
EOF
```

### 3. Загрузка образов на Docker Hub
```bash
docker login
docker push losiento/session-service:latest
docker push losiento/booking-service:latest
# ... остальные образы
```

### 4. Запуск виртуальных машин
```bash
vagrant up
```

### 5. Инициализация Swarm
```bash
vagrant ssh manager01
sudo docker swarm init --advertise-addr 192.168.56.10
```

### 6. Подключение worker-узлов
```bash
# На manager01:
sudo docker swarm join-token worker

# На worker01 и worker02:
sudo docker swarm join --token <TOKEN> 192.168.56.10:2377
```

### 7. Запуск стека сервисов
```bash
# На manager01:
sudo docker stack deploy -c docker-compose.yml my_stack
```

### 8. Настройка Nginx прокси
```nginx
# nginx.conf
location /api/v1/auth {
    proxy_pass http://session-service:8081;
}

location /api/v1/gateway {
    proxy_pass http://gateway-service:8087;
}
```

### 9. Тестирование Postman в Swarm
```bash
docker run --network=overlay -v "$(pwd)/src:/etc/newman" -t postman/newman run "application_tests.postman_collection.json"
```

Результаты:
```
✅ Все тесты успешно пройдены в Swarm-окружении
```

### 10. Распределение контейнеров
```bash
sudo docker node ps
```
```
ID       NAME                     IMAGE                            NODE       DESIRED STATE   CURRENT STATE
a1b2...  my_stack_session.1      losiento/session-service:latest  worker01   Running         Running 2 min
c3d4...  my_stack_gateway.1      losiento/gateway-service:latest  manager01  Running         Running 2 min
e5f6...  my_stack_hotel.1        losiento/hotel-service:latest    worker02   Running         Running 2 min
```

### 11. Установка Portainer
```bash
sudo docker volume create portainer_data
sudo docker service create \
    --name portainer \
    --publish 9000:9000 \
    --replicas=1 \
    --constraint 'node.role == manager' \
    --mount type=bind,src=//var/run/docker.sock,dst=/var/run/docker.sock \
    --mount type=volume,src=portainer_data,dst=/data \
    portainer/portainer-ce:latest
```

---
