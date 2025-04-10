#!/bin/bash

# Update apt link sources
sudo apt-get update

# Install apache2 for server hosting
sudo apt-get -y install httpd

# Start apache2 to start hosting
sudo systemctl start httpd

mkdir -p /var/www/html

# Write simple website to host
echo "<h1>Hello from $1 web server</h1>" | sudo tee /var/www/html/index.html
