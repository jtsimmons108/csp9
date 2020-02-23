#Find security group ID and Allow inbound traffic on port 80 for EC2 Instance
group_id=`aws ec2 describe-security-groups --filter Name=group-name,Values=aws-cloud9* --query "SecurityGroups[*].{ID:GroupId}" --output text | head -n 1`
aws ec2 authorize-security-group-ingress --group-id $group_id --port 80 --protocol tcp --cidr 0.0.0.0/0

#Replace httpd.conf so that server knows to look in csp9 folder
sudo usermod -aG apache ec2-user
sudo cp httpd.conf /etc/httpd/conf/httpd.conf
sudo service httpd start
sudo service mysqld start


#Ask for a username now since vocstartsoft is $C9_USER for all c9 instances
read -p "Enter your username for MySQL: " user

#Create new user in MySQL and grant privileges
mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO '$user'@'localhost';"
mysql -u root -e "FLUSH PRIVILEGES;"

# Change SQL password
echo "You will need to set a password for MySQL."
echo "In a secure location, write down a new secure password (8+ chars) for MySQL."

#Initialize pwd and pwd2 so that while executes at least once
pwd=""
pwd2="A"
while [ "$pwd" != "$pwd2" ]
do
  read -s  -p "Enter the new password for MySQL: " pwd
  echo
  read -s  -p "Confirm the new password for MySQL: " pwd2
  echo
  if [ $pwd != $pwd2 ];
  then
    echo "Passwords don't match. Try again."
  else  
    if [ ${#pwd} -le 7 ]; # length(pwd)<=7
    then
      echo "Password is too short. Try again."
      pwd="."$pwd2 # force while loop by concatenating period and pwd2
      # Troubleshooting:
      echo "debug:" $pwd $pwd2
    else
      echo
      echo "Changing MySQL password..."
      mysql -u root -e "SET PASSWORD FOR '$user'@'localhost' = PASSWORD('$pwd');"

      mysql -u root -e "FLUSH PRIVILEGES;"
      echo "MySQL password changed. Use this password for MySQL and for PHPMyAdmin."
      
      
      #####
      # Create .login.php
      #####
      echo "<?php" > login.php
      echo '$host = "localhost";' >> login.php
      echo '$dbname ="artgallery";' >> login.php
      echo '$username = "'$user'";' >>login.php
      echo '$password = "'$pwd'";' >> login.php
      echo '?>' >> login.php
      
      #####
      # Create and populate SQL for Activity 2.2.2
      ####
      # This step not required because setup.sql creates the database now.
      # mysql -u $C9_USER -p$pwd -e "CREATE DATABASE artgallery"
      # Create and populate the database.
      mysql -u $user -p$pwd < setup.sql
      
      #####
      # Create database for Activity 2.2.3
      ####
      mysql -u $user -p$pwd -e "CREATE DATABASE shoes;"
    
    fi
  fi
done
echo "Welcome to the web $user" > index.html

public_dns=`curl -s http://169.254.169.254/latest/meta-data/public-hostname`
echo -e "\nYou can access your site from: "  $public_dns
