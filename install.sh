#!/bin/bash
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
#   You should have received a copy of the MIT License
#   along with this program.  If not, see <https://raw.githubusercontent.com/Loowan/OCSInventory_GLPI/main/LICENSE>.
#

#Define version and IP
OCSVERSION=2.9
GLPIVERSION=9.5.5
PLUGINVERSION=1.7.3
ip4=$(/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1) #Will not work if the interface is named as ens* or eno* (I will update this later).

output(){
    echo -e '\e[36m'$1'\e[0m';
}
warn(){
    echo -e '\e[31m'$1'\e[0m';
}
info(){
    echo -e '\e[33m'$1'\e[0m';
}


notsupported(){
        output "################################"
        warn "# Your system is not supported "
        info "# Supported Operating system : "
        info "# - Debian 10"
        info "# - Ubuntu 21.04, 20.04, 18.04"
        info "# - CentOS Linux 7, 8"
        info "# - CentOS Stream 8"
        info "# - Fedora 34"
        output "################################"
        exit 3
}

preinstall(){
    clear
    output "###############################################"
    output "# Check out the repo of this script on GitHub #"
    output "# https://github.com/Loowan/OCSInventory_GLPI #"
    output "###############################################"
    output "# This script will help you to setup GLPI/OCS #"
    output "###############################################"

    #Check if this script is executed with the root user. If not the script will fail in some step.
    if [ "$(id -u)" != "0" ]; then
        warn "This script must be run as root user."
        info "Use 'su -' or 'sudo -i' command."
        exit 1
    fi

    os_check

    if [ "$lsb_dist" = "debian" ] || [ "$lsb_dist" = "ubuntu" ]; then
        apt update && apt upgrade -y
        apt -y install virt-what sudo
    elif [ "$lsb_dist" = "centos" ] || [ "$lsb_dist" = "fedora" ]; then
        yum -y update
        yum -y install virt-what sudo
    fi

    virt_serv=$(echo $(virt-what))
    if [ "$virt_serv" = "" ]; then
        output "Your environment is not virtualized."
    else
        output "Your environment is '$virt_serv'.\nOCSInventory and GLPI can run in a virtual environment."
    fi
    output "Do you want to continue ?\n[1] Yes.\n[2] No."
    read choix
    case $choix in
        1)  output "Starting....\n\n"
            ;;
        2)  info "Installation cancelled."
            exit 4
            ;;
    esac

}

os_check(){
    if [ -r /etc/os-release ]; then
        lsb_dist="$(. /etc/os-release && echo "$ID")"
        dist_version="$(. /etc/os-release && echo "$VERSION_ID")"
        info "Your OS : ${lsb_dist} ${dist_version}"
    else
        warn "Error while checking the operating system version."
        exit 2
    fi

    if [ "$lsb_dist" = "debian" ]; then
        if [ "$dist_version" != "10" ]; then
            notsupported
        fi
    elif [ "$lsb_dist" = "ubuntu" ]; then
        if [ "$dist_version" != "21.04" ] && [ "$dist_version" != "20.04" ] && [ "$dist_version" != "18.04" ]; then
            notsupported
        fi
    elif [ "$lsb_dist" = "centos" ]; then
        if [ "$dist_version" != "7" ] && [ "$dist_version" != "8" ]; then
            notsupported
        fi
    elif [ "$lsb_dist" = "fedora" ]; then
        if [ "$dist_version" != "34" ]; then
            notsupported
        fi
    else
        notsupported
    fi
}

option_install(){
    output "Select what you want to install :"
    output "[1] Install OCSInventory v${OCSVERSION} (+ MySQL)."
    output "[2] Install GLPI v${GLPIVERSION} (+ MySQL)."
    output "[3] Install GLPI v${GLPIVERSION} + OCSInventory v${OCSVERSION} (+ MySQL)."
    output "[4] Install MySQL for GLPI and/or OCS." 
    info "[4] GLPI and OCS will not be installed."
    output "[5] Choose a Specific Version of OCS"
    output "[6] Choose a Specific Version of GLPI"
    output "[7] Reset root password of MySQL"
    output "[8] Add the Plugin v${PLUGINVERSION} to connect OCS to GLPI"
    read choix
    case $choix in
        1 ) optioninstall=1
            ;;
        2 ) optioninstall=2
            ;;
        3 ) optioninstall=3
            ;;
        4 ) optioninstall=4
            ;;
        5 ) output "Type the version of OCS you want to install :"
            read version
            OCSVERSION=$version
            option_install
            ;;
        6 ) output "Type the version of GLPI you want to install :"
            read version
            GLPIVERSION=$version
            option_install
            ;;
        7 ) curl -sSL https://raw.githubusercontent.com/tommytran732/MariaDB-Root-Password-Reset/master/mariadb-104.sh | sudo bash
            ;;
        8 ) optioninstall=5
            ;;
        * ) info "Please specify an option. (Ctrl + C to exit)"
            option_install
            ;;
    esac
}

repositories_setup(){
    output "\nSetting Up Repository..."
    if [ "$lsb_dist" = "ubuntu" ] || [ "$lsb_dist" = "debian" ]; then
        apt -y install software-properties-common curl apt-transport-https ca-certificates gnupg
        curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash
        apt -y update
        apt -y upgrade
    elif [ "$lsb_dist" = "fedora" ]; then
        dnf -y install https://rpm.ocsinventory-ng.org/ocsinventory-release-latest.fc31.ocs.noarch.rpm
    fi
}

common_dependencies(){
    output "\nInstall dependencies..."
    if [ "$lsb_dist" = "ubuntu" ] || [ "$lsb_dist" = "debian" ]; then
        apt -y install apache2 libapache2-mod-php
        apt -y install php php-curl php-gd php-json php-mbstring php-mysql php-xml php-intl php-cli php-ldap php-apcu php-xmlrpc php-zip
        apt -y install make unzip build-essential
        apt -y install mariadb-server
        systemctl enable apache2
        systemctl start apache2
    elif [ "$lsb_dist" = "centos" ] || [ "$lsb_dist" = "fedora" ]; then
        yum -y install httpd
        yum -y install php php-fpm php-gd php-mbstring php-mysql php-xml php-intl php-ldap php-apcu php-xmlrpc php-zip php-opcache php-sodium
        yum -y install make unzip
        yum -y install mariadb-server
        systemctl enable httpd
        systemctl enable php-fpm
    fi
    systemctl enable mariadb
    systemctl start mariadb
}

msyql_setup(){
    output "\nSeting up MySQL..."
    rootpassword=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
    Q0="DROP DATABASE IF EXISTS test;"
    Q1="SET old_passwords=0;"
    Q2="SET PASSWORD FOR 'root'@'localhost' = PASSWORD('$rootpassword');"
    Q3="DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
    Q4="DELETE FROM mysql.user WHERE User='';"
    Q5="DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%';"
    Q6="FLUSH PRIVILEGES;"
    SQL="${Q0}${Q1}${Q2}${Q3}${Q4}${Q5}${Q6}"
    sudo mysql -u root -e "$SQL"
}

ocs_dependencies(){
    output "\nInstall dependencies of OCS"
    sleep .5
    if [ "$lsb_dist" = "ubuntu" ] || [ "$lsb_dist" = "debian" ]; then
        apt install -y php-soap libapache2-mod-perl2 perl6 libxml-simple-perl libdbi-perl libdbd-mysql-perl libapache-dbi-perl libnet-ip-perl libsoap-lite-perl libarchive-zip-perl
##cpan XML::Simple Compress::Zlib DBI DBD::mysql Apache::DBI Net::IP SOAP::Lite Mojolicious::Lite Plack::Handler Archive::Zip YAML XML::Entities Switch
        cpan Compress::Zlib Mojolicious::Lite Plack::Handler YAML XML::Entities Switch
        sudo service apache2 restart
    elif [ "$lsb_dist" = "centos" ] || [ "$lsb_dist" = "fedora" ]; then
        yum -y install php-soap perl-DBD-MySQL perl-XML-Simple perl-Apache-DBI perl-XML-Entities perl-Apache2-SOAP perl-Mojolicious perl-Plack
        dnf -y install cpan
        cpan Compress::Zlib Net::IP Archive::Zip YAML XML::Entities Switch
        if [ "$lsb_dist" = "fedora" ]; then
            dnf -y install https://rpm.ocsinventory-ng.org/ocsinventory-release-latest.fc34.ocs.noarch.rpm
        elif [ "$dist_version" = "7" ]; then
            wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
            wget https://rpms.remirepo.net/enterprise/remi-release-7.rpm
            wget https://rpm.ocsinventory-ng.org/ocsinventory-release-latest.el7.ocs.noarch.rpm
            yum -y install ocsinventory-release-latest.el7.ocs.noarch.rpm epel-release-latest-7.noarch.rpm remi-release-7.rpm
        else
            wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
            wget https://rpms.remirepo.net/enterprise/remi-release-8.rpm
            wget https://rpm.ocsinventory-ng.org/ocsinventory-release-latest.el8.ocs.noarch.rpm
            dnf -y install ocsinventory-release-latest.el8.ocs.noarch.rpm epel-release-latest-8.noarch.rpm remi-release-8.rpm
        fi
        sudo service httpd restart
    fi

}

glpi_dependencies(){
    output "\nInstallation des dependences de GLPI"
    if [ "$lsb_dist" = "ubuntu" ] || [ "$lsb_dist" = "debian" ]; then
        apt install -y php-fileinfo php-simplexml php-cas php-bz2
    elif [ "$lsb_dist" = "centos" ] || [ "$lsb_dist" = "fedora" ]; then
        yum -y install php-pear-CAS
    fi

}

ocs_install(){
    if [ "$lsb_dist" = "ubuntu" ] || [ "$lsb_dist" = "debian" ];then
        mkdir /opt/ocs
        wget https://github.com/OCSInventory-NG/OCSInventory-ocsreports/releases/download/${OCSVERSION}/OCSNG_UNIX_SERVER-${OCSVERSION}.tar.gz -P /opt/ocs
        tar -xf /opt/ocs/OCSNG_UNIX_SERVER-${OCSVERSION}.tar.gz
        rm /opt/ocs/OCSNG_UNIX_SERVER-${OCSVERSION}.tar.gz -f
        cp ./OCSNG_UNIX_SERVER-${OCSVERSION}/ /opt/ocs -r && rm ./OCSNG_UNIX_SERVER-${OCSVERSION}/ -R -f
        chmod +x /opt/ocs/OCSNG_UNIX_SERVER-${OCSVERSION}/setup.sh
        info "\nStarting OCS setup ! This setup will ask you some question about your configuration.\nIf you don't know just press enter."
        sleep 5
        cd /opt/ocs/OCSNG_UNIX_SERVER-${OCSVERSION}/
        sh setup.sh
    elif [ "$lsb_dist" = "centos" ] || [ "$lsb_dist" = "fedora" ]; then
        if [ "$lsb_dist" = "fedora" ]; then
            dnf -y install ocsinventory ocsinventory-server ocsinventory-reports
        elif [ "$dist_version" = "7" ]; then
            yum -y install yum-utils
            yum-config-manager --enable remi
            yum-config-manager --enable remi-php73
            yum -y install ocsinventory ocsinventory-server ocsinventory-reports
        else
            dnf -y install yum-utils
            yum-config-manager --enable remi
            dnf -y module reset php
            dnf -y module install php:remi-7.3
            dnf -y install --enablerepo=PowerTools ocsinventory ocsinventory-server ocsinventory-reports
        fi
    fi
}

glpi_install(){
    mkdir /opt/glpi
    wget https://github.com/glpi-project/glpi/releases/download/${GLPIVERSION}/glpi-${GLPIVERSION}.tgz -P /opt/glpi
    tar -xf /opt/glpi/glpi-${GLPIVERSION}.tgz
    rm /opt/glpi/glpi-${GLPIVERSION}.tgz -f
    cp ./glpi/ /opt/ -r && rm ./glpi/ -R -f
    chmod 777 /opt/glpi/files/ -R
    chmod 777 /opt/glpi/config/ -R
    chmod 777 /opt/glpi/marketplace/ -R
}

ocs_webconfig(){
    if [ "$lsb_dist" = "ubuntu" ] || [ "$lsb_dist" = "debian" ]; then
        cp /etc/apache2/conf-available/ocsinventory-reports.conf /etc/apache2/sites-enabled/
        chmod 777 /var/lib/ocsinventory-reports/
        chmod 775 /usr/share/ocsinventory-reports/ocsreports/
        systemctl restart apache2
        #cd /usr/share/ocsinventory-reports/ocsreports/files/
        #mysql -f -hlocalhost -uroot -p$rootpassword ocsweb < ocsbase.sql >log.log
    elif [ "$lsb_dist" = "centos" ] || [ "$lsb_dist" = "fedora" ]; then
##cp /etc/httpd/conf.d/z-ocsinventory-server.conf /etc/httpd/conf/
##chmod 777 /var/lib/ocsinventory-reports/
##chmod 775 /usr/share/ocsinventory-reports/ocsreports/
        systemctl restart httpd
        systemctl restart php-fpm
        sudo firewall-cmd --add-service=http --add-service=https --permanent
        sudo firewall-cmd --permanent --add-port=3306/tcp
        sudo firewall-cmd --reload

    fi
}

glpi_webconfig(){
    if [ "$lsb_dist" = "ubuntu" ] || [ "$lsb_dist" = "debian" ]; then
        glpiconf=/etc/apache2/conf-available/glpi.conf
    elif [ "$lsb_dist" = "centos" ] || [ "$lsb_dist" = "fedora" ]; then
        glpiconf=/etc/httpd/conf/glpi.conf
    fi
    cat << EOF > $glpiconf
Alias /glpi /opt/glpi

    <Directory /opt/glpi>
     DirectoryIndex index.php
     Options FollowSymLinks
     AllowOverride Limit Options FileInfo
     Require all granted
    </Directory>
EOF
    if [ "$lsb_dist" = "ubuntu" ] || [ "$lsb_dist" = "debian" ]; then
        cp /etc/apache2/conf-available/glpi.conf /etc/apache2/sites-enabled/
        service apache2 restart
    elif [ "$lsb_dist" = "centos" ] || [ "$lsb_dist" = "fedora" ]; then
        service httpd restart
    fi
}

ocs_mysql(){
    output "\nMaking DataBase for OCS..."
    ocs_password=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1`
    Q0="CREATE DATABASE IF NOT EXISTS ocsweb;"
    Q1="CREATE USER 'ocs'@'localhost';"
    Q2="ALTER USER 'ocs'@'localhost' IDENTIFIED BY '$ocs_password';"
    Q3="GRANT ALL PRIVILEGES ON ocsweb.* TO 'ocs'@'localhost';"
    Q4="FLUSH PRIVILEGES;"
    SQL="${Q0}${Q1}${Q2}${Q3}${Q4}"
    sudo mysql -u root -e "$SQL" -p$rootpassword
}

glpi_mysql(){
    output "\nMaking DataBase for GLPI..."
    glpi_password=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
    Q0="CREATE DATABASE IF NOT EXISTS glpi;"
    Q1="GRANT ALL ON glpi.* TO 'glpi'@'127.0.0.1' IDENTIFIED BY '$glpi_password';"
    Q2="FLUSH PRIVILEGES;"
    SQL="${Q0}${Q1}${Q2}"
    sudo mysql -u root -e "$SQL" -p$rootpassword
}

ocs_setup(){
    ocs_dependencies
    ocs_install
    ocs_mysql
    ocs_webconfig
}

glpi_setup(){
    glpi_dependencies
    glpi_install
    glpi_webconfig
    glpi_mysql
}

broadcast_sql(){
    output "###############################################################"
    output "Information on MariaDB"
    output ""
    info "Your root password for MySQL is : $rootpassword"
    output ""
    output "###############################################################"
}

broadcast_ocs(){
    output "###############################################################"
    output "OCS DataBase :"
    output "Host: localhost"
    output "Port: 3306"
    output "User: ocs"
    output "Name: ocsweb"
    output "Password: $ocs_password"
    output ""
    output "Web Interface of OCS :"
    output "http://${ip4}/ocsreports"
    output "By default admin account use :"
    output "User: admin"
    output "Password: admin"
    output "###############################################################"
}

broadcast_glpi(){
    output "###############################################################"
    output "GLPI DataBase :"
    output "Host: 127.0.0.1"
    output "Port: 3306"
    output "User: glpi"
    output "Name: glpi"
    output "Password: $glpi_password"
    output ""
    output "Web Interface of GLPI :"
    output "http://${ip4}/glpi"
    output "By default admin account use :"
    output "User: glpi"
    output "Password: glpi"
    output "###############################################################"
}

preinstall
option_install
case $optioninstall in
    1 ) repositories_setup
        common_dependencies
        msyql_setup
        ocs_setup
        broadcast_sql
        broadcast_ocs
        ;;
    2 ) repositories_setup
        common_dependencies
        msyql_setup
        glpi_setup
        broadcast_sql
        broadcast_glpi
        ;;
    3 ) repositories_setup
        common_dependencies
        msyql_setup
        ocs_setup
        glpi_setup
        broadcast_sql
        broadcast_glpi
        broadcast_ocs
        ;;
    4 ) repositories_setup
        output "Que voulez-vous installer ?\n[1]OCSInventory.\n[2]GLPI.\n[3]MySQL."
        read choix
        case $choix in
            1 ) common_dependencies
                ocs_dependencies
                ocs_install
                ocs_webconfig
                broadcast_ocs
                info "N'oubliez pas de changer les configurations d'OCS pour la base de donnée"
                ;;
            2 ) common_dependencies
                glpi_dependencies
                glpi_install
                glpi_webconfig
                broadcast_glpi
                ;;
            3 ) output "Avez-vous déjà un serveur MySQL installé ?\n[1]Oui.\n[2]Non."
                read choix
                case $choix in
                    1 ) output "Indiquez le password root de MySQL :"
                        read rootpassword
                        ocs_mysql
                        glpi_mysql
                        output "Quels est l'adresse IP de votre Machine GLPI ?"
                        read ipglpi
                        output "Quelle est l'adresse IP de votre Machine OCS ?"
                        read ipocs
                        Q0="GRANT ALL ON ocsweb.* to 'ocs'@'$ipocs' IDENTIFIED BY '$ocs_password';"
                        Q1="GRANT ALL ON glpi.* to 'glpi'@'$ipglpi' IDENTIFIED BY '$glpi_password';"
                        Q2="FLUSH PRIVILEGES;"
                        SQL="${Q0}${Q1}${Q2}"
                        sudo mysql -u root -e "$SQL" -p$rootpassword
                        broadcast_glpi
                        broadcast_ocs
                        ;;
                    2 ) if [ "$lsb_dist" = "ubuntu" ] || [ "$lsb_dist" = "debian" ]; then
                            apt -y install mariadb-server mariadb-client mariadb-common
                            apt -y install sudo build-essential
                        elif [ "$lsb_dist" = "centos" ] || [ "$lsb_dist" = "fedora" ]; then
                            yum -y install mariadb-server sudo
                        fi
                        msyql_setup
                        ocs_mysql
                        glpi_mysql
                        output "Quelle est l'adresse IP de votre Machine GLPI ?"
                        read ipglpi
                        output "Quelle est l'adresse IP de votre Machine OCS ?"
                        read ipocs
                        Q0="GRANT ALL ON ocsweb.* to 'ocs'@'$ipocs' IDENTIFIED BY '$ocs_password';"
                        Q1="GRANT ALL ON glpi.* to 'glpi'@'$ipglpi' IDENTIFIED BY '$glpi_password';"
                        Q2="FLUSH PRIVILEGES;"
                        SQL="${Q0}${Q1}${Q2}"
                        sudo mysql -u root -e "$SQL" -p$rootpassword
                        broadcast_glpi
                        broadcast_ocs
                        ;;
                esac
                ;;
        esac
        ;;
    5 ) output "Téléchargement..."
        cd /tmp
        wget https://github.com/pluginsGLPI/ocsinventoryng/releases/download/${PLUGINVERSION}/glpi-ocsinventoryng-${PLUGINVERSION}.tar.gz
        tar -xsf glpi-ocsinventoryng-${PLUGINVERSION}.tar.gz
        mv -t ocsinventoryng/ /opt/glpi/plugins -f
        output "Plugin téléchargé et installé"
        ;;
esac
output "Fin du script."
