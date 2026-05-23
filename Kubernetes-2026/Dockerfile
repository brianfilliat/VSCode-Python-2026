FROM registry.access.redhat.com/ubi9/ubi:latest

LABEL maintainer="Your Name <your.email@example.com>"

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
