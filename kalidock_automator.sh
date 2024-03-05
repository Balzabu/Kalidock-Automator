#!/bin/bash
#===================================================================
# HEADER
#===================================================================
#  DESCRIPTION
#     This script makes it easy to set up Docker and Portainer on Kali Linux,
#     allowing you to manage containers effortlessly. Docker simplifies the
#     deployment of applications in lightweight containers, while Portainer
#     provides a user-friendly web interface for monitoring and managing
#     Docker environments. With this script, you can quickly get started
#     with containerization without needing advanced technical knowledge.
#     Other Debian-based OS should be supported too.
#===================================================================
#  IMPLEMENTATION
#     Author          Balzabu
#     Copyright       Copyright (c) https://balzabu.io
#     License         MIT
#     Github          https://github.com/balzabu
#===================================================================
# END_OF_HEADER
#===================================================================

# ==================================================================
# Useful ANSI codes 
# ==================================================================
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
MAGENTA="\e[35m"
WHITE="\e[97m"
ENDCOLOR="\e[0m"

# ==================================================================
# Check if script is running as root
# ==================================================================
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: this script must be run as root; exiting.${ENDCOLOR}"
    exit 1
fi

# ==================================================================
# List of conflicting packages
# ==================================================================
conflicting_packages=("docker.io" "docker-doc" "docker-compose" "docker-compose-v2" "podman-docker" "containerd" "runc")

# ==================================================================
# Uninstall conflicting packages
# ==================================================================
for pkg in "${conflicting_packages[@]}"; do
    echo -e "${YELLOW}Removing $pkg...${ENDCOLOR}"
    if sudo apt-get remove -y "$pkg"; then
        echo -e "${GREEN}Successfully removed $pkg.${ENDCOLOR}"
    else
        echo -e "${RED}Failed to remove $pkg. Check if it's installed or try again later.${ENDCOLOR}"
    fi
done

# ==================================================================
# Install required dependencies
# ==================================================================
echo -e "${YELLOW}Installing required dependencies...${ENDCOLOR}"

# Update package lists and install dependencies
if ! sudo apt-get update; then
    echo -e "${RED}Failed to update package lists. Exiting.${ENDCOLOR}"
    exit 1
fi

if ! sudo apt-get install -y ca-certificates curl; then
    echo -e "${RED}Failed to install required dependencies. Exiting.${ENDCOLOR}"
    exit 1
fi

echo -e "${GREEN}Required dependencies installed successfully.${ENDCOLOR}"

# ==================================================================
# Add Docker's official GPG key
# ==================================================================
echo -e "${YELLOW}Adding Docker's official GPG key...${ENDCOLOR}"

# Create the directory for keyrings
if ! sudo install -m 0755 -d /etc/apt/keyrings; then
    echo -e "${RED}Failed to create the directory for Docker's GPG key. Exiting.${ENDCOLOR}"
    exit 1
fi

# Download Docker's GPG key
if ! sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc; then
    echo -e "${RED}Failed to download Docker's GPG key. Exiting.${ENDCOLOR}"
    exit 1
fi

# Set appropriate permissions for the key file
if ! sudo chmod a+r /etc/apt/keyrings/docker.asc; then
    echo -e "${RED}Failed to set permissions for Docker's GPG key file. Exiting.${ENDCOLOR}"
    exit 1
fi

echo -e "${GREEN}Docker's official GPG key added successfully.${ENDCOLOR}"

# ==================================================================
# Determine OS and adjust repository accordingly
# ==================================================================
if grep -qiE "kali" /etc/os-release; then
    echo -e "${YELLOW}Configuring Docker repository for Kali Linux...${ENDCOLOR}"
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian  bullseye stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
else
    echo -e "${YELLOW}Configuring Docker repository...${ENDCOLOR}"
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
fi

# ==================================================================
# Update Apt sources
# ==================================================================
echo -e "${YELLOW}Updating Apt sources...${ENDCOLOR}"
sudo apt-get update

# ==================================================================
# Install Docker
# ==================================================================
echo -e "${YELLOW}Installing Docker...${ENDCOLOR}"

# Install Docker CE, Docker CE CLI, containerd.io, Docker Buildx plugin, and Docker Compose plugin
if ! sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
    echo -e "${RED}Failed to install Docker and its components. Exiting.${ENDCOLOR}"
    exit 1
fi

echo -e "${GREEN}Docker installed successfully.${ENDCOLOR}"

# ==================================================================
# Install Portainer CE
# ==================================================================
echo -e "${YELLOW}Installing Portainer CE...${ENDCOLOR}"
sudo docker volume create portainer_data
sudo docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest

# ==================================================================
# Print a message on screen
# ==================================================================
echo -e "${GREEN}Docker and Portainer CE have been successfully installed and configured.${ENDCOLOR}"
