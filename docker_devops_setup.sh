#!/bin/bash
# Docker & Docker Compose Setup Script for warehouse project

# 1. Install Docker and Docker Compose
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common git
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
sudo apt update
sudo apt install -y docker-ce
sudo usermod -aG docker $USER
sudo systemctl enable docker
sudo systemctl start docker

# Install docker-compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 2. Clone the warehouse repo (corrected URL)
cd /code
git clone -b system https://github.com/titanHE/warehouse.git
cd warehouse

# 3. Create Dockerfile for backend
cat <<'EOF' > Dockerfile
FROM python:3.8-slim
WORKDIR /app
COPY . /app
RUN pip install --no-cache-dir -r requirements.txt
CMD ["python", "app.py"]
EOF

# 4. Create dbfiles directory with proper permissions
mkdir -p /code/warehouse/dbfiles
chmod 777 /code/warehouse/dbfiles

# 5. Create docker-compose.yml
cat <<'EOF' > docker-compose.yml
version: '3.8'
services:
  warehouse:
    build: .
    container_name: warehouse
    ports:
      - "8000:8000"
    environment:
      - DB_HOST=database
      - DB_USER=warehouse_user
      - DB_PASSWORD=warehouse_pass
      - DB_NAME=warehouse_db
    depends_on:
      - database
  database:
    image: mysql:5.7
    container_name: database
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: warehouse_pass
      MYSQL_DATABASE: warehouse_db
      MYSQL_USER: warehouse_user
      MYSQL_PASSWORD: warehouse_pass
    volumes:
      - ./dbfiles:/var/lib/mysql
    ports:
      - "3306:3306"
EOF

# 6. Build and start containers
sudo docker-compose up -d --build
