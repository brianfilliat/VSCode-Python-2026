# Packaging Nginx RHEL 9 Application Code and Dependencies into a Docker Image

This guide demonstrates how to package an Nginx application, along with its RHEL 9 dependencies, into a Docker image using Red Hat Universal Base Image (UBI) 9. UBI images are freely redistributable and provide a solid foundation for building containerized applications on RHEL-based systems.

## 1. Prerequisites

To follow this guide, you will need:

*   **Docker or Podman:** A containerization platform installed on your system. Docker is widely used, but Podman is a daemonless alternative that is fully compatible with Docker images and commands.

## 2. Project Structure

We will organize our project with the following file structure:

```
.
├── Dockerfile
├── nginx.conf
└── html/
    └── index.html
```

### `Dockerfile`

This file contains the instructions for building our Docker image:

```dockerfile
FROM registry.access.redhat.com/ubi9/ubi:latest

LABEL maintainer="Brian Filliat <BrianFillliat@Gmail.com>"

# Install Nginx and its dependencies
RUN dnf update -y && \
    dnf install -y nginx && \
    dnf clean all

# Copy custom Nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Copy application code (e.g., static HTML files)
COPY html/ /usr/share/nginx/html/

# Expose port 80
EXPOSE 80

# Start Nginx when the container launches
CMD ["nginx", "-g", "daemon off;"]
```

**Explanation of `Dockerfile` commands:**

*   `FROM registry.access.redhat.com/ubi9/ubi:latest`: Specifies the base image. We are using the latest Red Hat Universal Base Image 9, which provides a minimal RHEL environment.
*   `LABEL maintainer="Your Name <your.email@example.com>"`: Adds metadata to the image, indicating the maintainer.
*   `RUN dnf update -y && dnf install -y nginx && dnf clean all`: Updates the package manager (`dnf`), installs Nginx, and then cleans up the `dnf` cache to reduce image size.
*   `COPY nginx.conf /etc/nginx/nginx.conf`: Copies our custom Nginx configuration file into the container.
*   `COPY html/ /usr/share/nginx/html/`: Copies our static HTML content into the default Nginx web root directory.
*   `EXPOSE 80`: Informs Docker that the container listens on port 80 at runtime. This is purely informational.
*   `CMD ["nginx", "-g", "daemon off;"]`: Defines the command to run when the container starts. `nginx -g 'daemon off;'` runs Nginx in the foreground, which is essential for Docker containers.

### `nginx.conf`

This is a standard Nginx configuration file. For this example, it's configured to serve static content from `/usr/share/nginx/html/` on port 80.

```nginx
user  nginx;
worker_processes  auto;

error_log  /var/log/nginx/error.log notice;
pid        /var/run/nginx.pid;

events {
    worker_connections  1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;

    keepalive_timeout  65;

    include /etc/nginx/conf.d/*.conf;

    server {
        listen       80;
        server_name  localhost;

        location / {
            root   /usr/share/nginx/html;
            index  index.html index.htm;
        }

        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   /usr/share/nginx/html;
        }
    }
}
```

### `html/index.html`

A simple HTML file that will be served by Nginx:

```html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to Nginx on RHEL 9!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to Nginx on RHEL 9!</h1>
<p>This is a sample Nginx page served from a Docker container built on Red Hat Universal Base Image 9.</p>
<p>For more information, please visit <a href="https://www.nginx.com/">nginx.com</a>.</p>
</body>
</html>
```

## 3. Building the Docker Image

Navigate to the directory containing your `Dockerfile`, `nginx.conf`, and `html` folder. Then, execute the following command to build your Docker image. Replace `my-nginx-rhel9` with your desired image name and tag:

```bash
docker build -t my-nginx-rhel9 .
```

*   `-t my-nginx-rhel9`: Tags the image with the name `my-nginx-rhel9`.
*   `.`: Specifies the build context, which is the current directory.

## 4. Running the Docker Container

Once the image is built, you can run a container from it. The `-p` flag maps a port on your host machine to a port inside the container (host_port:container_port). Here, we map host port 8080 to container port 80.

```bash
docker run -d -p 8080:80 --name my-nginx-app my-nginx-rhel9
```

*   `-d`: Runs the container in detached mode (in the background).
*   `-p 8080:80`: Maps port 8080 on your host to port 80 in the container.
*   `--name my-nginx-app`: Assigns a name to your running container for easier management.
*   `my-nginx-rhel9`: The name of the image to run.

## 5. Verifying the Application

Open your web browser and navigate to `http://localhost:8080`. You should see the 
 "Welcome to Nginx on RHEL 9!" page.

## 6. Managing the Container

*   **List running containers:**
    ```bash
docker ps
    ```

*   **Stop the container:**
    ```bash
docker stop my-nginx-app
    ```

*   **Start the container:**
    ```bash
docker start my-nginx-app
    ```

*   **Remove the container:**
    ```bash
docker rm my-nginx-app
    ```

*   **Remove the image:**
    ```bash
docker rmi my-nginx-rhel9
    ```

This guide provides a comprehensive overview of how to containerize an Nginx application on RHEL 9 using Docker and UBI. This approach ensures consistency, portability, and efficient deployment of your applications.
