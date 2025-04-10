#!/bin/bash

# Update apt link sources
sudo apt-get update

# Install apache2 for server hosting
sudo apt-get -y install apache2

# Start apache2 to start hosting
sudo systemctl start apache2

# Write simple website to host
mkdir -p /var/www/html
echo "<h1>Hello from $1 web server</h1>" | sudo tee /var/www/html/index.html
