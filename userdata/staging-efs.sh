#!/bin/bash

DOMAIN_NAME=wordpress-iac.demo.com

mkdir -p /var/www/html/
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${efs_id}.efs.${region}.amazonaws.com:/ /var/www/html/
yum install -y amazon-efs-utils
echo '${efs_id}.efs.${region}.amazonaws.com:/ /var/www/html/ efs defaults,_netdev 0 0' >> /etc/fstab
yum install -y httpd
systemctl start httpd
systemctl enable httpd
wget -O wordpress.tar.gz https://wordpress.org/wordpress-6.2.2.tar.gz
tar -xzf wordpress.tar.gz
cd wordpress
cp wp-config-sample.php wp-config.php
sed -i "s/database_name_here/${db_name}/g" wp-config.php
sed -i "s/username_here/${db_username}/g" wp-config.php
sed -i "s/password_here/${db_password}/g" wp-config.php
sed -i "s/localhost/${db_host}/g" wp-config.php
SALT=$(curl -L https://api.wordpress.org/secret-key/1.1/salt/)
STRING='put your unique phrase here'
printf '%s\n' "g/$STRING/d" a "$SALT" . w | ed -s wp-config.php
# echo 'define('FS_METHOD', 'direct');' >> wp-config.php
yum clean metadata
yum install -y php php-cli php-pdo php-fpm php-json php-mysqlnd php-dom
cd ..
cp -r wordpress/* /var/www/html/

# WP CLI Install
wget -O wp-cli.phar https://github.com/wp-cli/wp-cli/releases/download/v2.8.1/wp-cli-2.8.1.phar
php wp-cli.phar --info
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp
# Setup WP
wp --path=/var/www/html core install --allow-root --url="https://${DOMAIN_NAME}" --title="Introduction to Terraform on AWS" --admin_user="${demo_username}" --admin_password="${demo_password}" --admin_email="${demo_email}"
# Install and configure WP Plugins
# aws s3 cp s3://ab3-adfs-config-kdmck/miniorange-saml-20-single-sign-on.4.9.28.zip .
# aws s3 cp s3://ab3-adfs-config-kdmck/wp-debugging.2.11.14.zip .
# aws s3 cp s3://ab3-adfs-config-kdmck/wp-force-login.5.6.3.zip .
# wp plugin install miniorange-saml-20-single-sign-on.4.9.24.zip --path=/var/www/html --activate
# wp plugin install wp-debugging.2.11.13.zip --path=/var/www/html --activate
# wp plugin install wp-force-login.5.6.3.zip --path=/var/www/html --activate
# Give apache access
chown -R apache:apache /var/www/
systemctl restart httpd

yum install -y htop 
