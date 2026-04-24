# Informatica Installation and Configuration Guide

## Overview
This document provides a high-level guide for installing and configuring Informatica PowerCenter (and related Informatica components) on a supported server environment.

> Note: Informatica is enterprise software that requires a valid license and installation media from Informatica. This guide is intended as a standard process reference and may need to be adapted to your specific Informatica version and target environment.

## Supported Products
- Informatica PowerCenter Server and Client
- Informatica Domain and Repository Services
- Informatica Integration Service
- Informatica Administrator and PowerCenter Designer

## Prerequisites
1. Obtain the Informatica installation files and license key.
2. Supported operating system: Windows Server or Linux distribution certified for your Informatica version.
3. Supported database for PowerCenter repository:
   - Oracle
   - Microsoft SQL Server
   - IBM Db2
   - PostgreSQL (for later versions)
4. Java JDK installed if required by your Informatica version.
5. A dedicated database schema/user for the Informatica repository.
6. Administrator/root privileges on the installation host.

## Architecture Components
- **Informatica Domain**: Central management and security layer.
- **Repository Service**: Manages metadata for PowerCenter mappings and workflows.
- **Integration Service**: Executes workflows and sessions.
- **Repository Manager / Designer**: Client tools used for development.
- **Informatica Administrator**: Web-based management console.

## 1. Prepare the Environment
1. Create a host with the required OS and patch level.
2. Install required OS packages and libraries.
3. Ensure network connectivity between the Informatica host, database server, and client machines.
4. Configure DNS/hostname resolution for the Informatica server.
5. Disable or configure firewall rules for required Informatica ports.

## 2. Prepare the Repository Database
1. Create a repository database instance or schema.
2. Create a repository user and grant required privileges.
3. Verify connectivity from the Informatica host to the database.
4. Confirm the database meets Informatica prerequisites.

## 3. Install Informatica Server Components
1. Extract the Informatica installation media.
2. Run the installer as an administrator/root user.
3. Choose the installation type:
   - **Domain and Repository Service**
   - **Integration Service**
   - **Client tools**
4. Provide the install directory and services directory.
5. Install the Informatica Domain and PowerCenter Server components.

## 4. Configure the Informatica Domain
1. Use the Informatica Installer to create a new domain or join an existing domain.
2. Set the domain name and domain user credentials.
3. Define the domain node and node properties.
4. Configure the domain database connection if prompted.

## 5. Configure Repository and Integration Services
1. Open the Informatica Administrator web console:
   - `http://<hostname>:<port>/adminconsole`
2. Log in as the domain administrator.
3. Create a new repository service:
   - Attach it to the repository database.
   - Define the repository service properties.
4. Create a new integration service:
   - Associate it with the domain node.
   - Configure advanced properties such as memory, DTUs, and worker settings.
5. Start the repository and integration services from the Administrator console.

## 6. Install and Configure Client Tools
1. Install Informatica PowerCenter Client on developer workstations.
2. Install Designer, Repository Manager, Workflow Manager, and Workflow Monitor.
3. Configure the client to connect to the domain and repository.
4. Create a repository connection in Repository Manager.
5. Verify metadata access and folder permissions.

## 7. Validate the Installation
1. Login to Informatica Administrator and confirm services are running.
2. Use the Repository Manager to connect to the PowerCenter repository.
3. Create a test folder and validate access.
4. Create a simple mapping and workflow in Designer.
5. Execute the workflow using Workflow Monitor and confirm success.

## 8. Common Configuration Checklist
- Domain configuration completed
- Repository connection configured
- Integration Service configured and running
- Required services started after installation
- Port and firewall rules verified
- Client connectivity tested
- Backup and recovery plan documented

## 9. Troubleshooting
- If the domain does not start, verify hostname and database connectivity.
- If the repository service fails, check repository database permissions.
- Use Informatica logs under the installation directory to inspect errors.
- Confirm the correct Java version for your Informatica release.
- Validate that all required OS packages and dependencies are installed.

## 10. Additional Notes
- Informatica Cloud is a separate product and uses a different installation/configuration model.
- Always refer to the official Informatica Installation Guide for the exact version you are deploying.
- Use a dedicated server for the domain and repository to simplify support and scaling.
