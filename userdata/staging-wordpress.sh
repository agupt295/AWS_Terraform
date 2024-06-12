#!/bin/bash

DOMAIN_NAME=wordpress-iac.demo.com

mkdir -p /var/www/html/
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${efs_id}.efs.${region}.amazonaws.com:/ /var/www/html/
yum install -y amazon-efs-utils
echo '${efs_id}.efs.${region}.amazonaws.com:/ /var/www/html/ efs defaults,_netdev 0 0' >>/etc/fstab
yum install -y httpd
systemctl start httpd
systemctl enable httpd
yum clean metadata
yum install -y php php-cli php-pdo php-fpm php-json php-mysqlnd php-dom
sed -i "/<Directory \/>/,/<\/Directory>/c\
<Directory \/>\n\
    Options FollowSymLinks\n\
    AllowOverride All\n\
<\/Directory>" /etc/httpd/conf/httpd.conf
sed -i "s/AllowOverride None/AllowOverride All/g" /etc/httpd/conf/httpd.conf
yum install -y mod_ssl
sed -i "s/localhost.crt/server.crt/g" /etc/httpd/conf.d/ssl.conf
sed -i "s/localhost.key/server.key/g" /etc/httpd/conf.d/ssl.conf

# Create self signed key
openssl req -x509 -newkey rsa:4096 \
  -sha256 -days 3650 \
  -nodes \
  -keyout /etc/pki/tls/private/server.key \
  -out /etc/pki/tls/certs/server.crt \
  -subj "/C=USA/ST=CA/L=San Diego/O=Amazon Web Services/OU=WWPS ProServe/CN=$DOMAIN_NAME"

aws s3 cp s3://${s3_bucket}/server.key /etc/pki/tls/private/server.key
aws s3 cp s3://${s3_bucket}/server.crt /etc/pki/tls/certs/server.crt

systemctl restart httpd
