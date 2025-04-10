#!/bin/bash

# Update apt link sources
sudo apt-get update

# Install apache2 for server hosting
sudo apt-get -y install httpd

# Start apache2 to start hosting
sudo systemctl start httpd

# Write simple website to host
echo "Hello from $1 web server" | sudo tee /var/www/html/index.html
