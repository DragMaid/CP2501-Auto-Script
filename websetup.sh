jcu_id=""

# Install node manager (nvm) from web using curl
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# Source the new modified bashrc file after installation
source "$HOME/.bashrc"
source "$HOME/.nvm/nvm.sh"

# Install the latest version of nodejs using nvm
nvm install --lts

# Update apt link sources
sudo apt update

# Install apache2 for server hosting
sudo apt -y install apache2

# Install nodejs and npm
# sudo apt -y install nodejs npm

# Install production process manager for nodejs (pm2)
npm install pm2@latest -g

# Enable apache2 server proxy
sudo a2enmod proxy proxy_http

# Copy pre-configured file to apache config file
echo "
<VirtualHost *:80> 
    ServerAdmin admin@site.com 
    ServerName site.com 
    ServerAlias www.site.com 
    ProxyRequests off 
    <Proxy *> 
        Order deny,allow 
        Allow from all 
    </Proxy>
    <Location /> 
        ProxyPass http://localhost:3000/ 
        ProxyPassReverse http://localhost:3000/ 
    </Location>
</VirtualHost>
" | sudo tee /etc/apache2/sites-available/000-default.conf

# Restart apache2 for the changes to take effect
sudo systemctl restart apache2

# Clone the web server code from github
git clone https://github.com/DragMaid/astro-dog.git

# Change directory and switch the branch to deploy
cd astro-dog
git checkout origin/deploy -b deploy

# Edit main menu and add in JCU ID
sed -i "54s/>/ value="$jcu_id">/" ~/astro-dog/public/index.html

# Run the web application (using pm2 installed above)
pm2 start ~/astro-dog/server-dev.js
