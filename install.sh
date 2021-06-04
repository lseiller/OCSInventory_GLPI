#!/bin/bash
OCSVERSION=2.9
GLPIVERSION=9.5.5

output(){
    echo '\e[36m'$1'\e[0m';
}

warn(){
    echo '\e[31m'$1'\e[0m'
}

info(){
    echo '\e[33m'$1'\e1'
}

notsupported(){
        output "Votre système n'est pas compatible"
        output ""
        output "OS Supporté :"
        output "Debian 10, 9"
        output "Ubuntu 20.10, 20.04, 19.10, 18.04"
        #output "CentOS Linux 8, 7"
        #output "CentOS Stream 8"
        #output "Fedora 33"
        exit 2
}

preinstall(){
    clear
    output "GITHUB : "
    output "https://github.com/Lowan-S/OCSInventory_GLPI"

    os_check

    if [ "$(id -u)" != "0" ]; then
        warn "Ce script a besoin d'être exécuté en root."
        exit 3
    fi

    if [ "$lsb_dist" = "debian" ]; then
        if [ "$dist_version" = "9" ]; then
            warn "Vous êtes sur Debian 9, cette version n'est pas recommandé.\nVoulez-vous quand même procéder ?\n[1]Oui.\n[2]Non."
            read choix
            case $choix in
                1 ) output "On continue !"
                    ;;
                2 ) output "Arrêt du script"
                    exit 7
                    ;;
            esac
        fi
        dpkg --configure -a
        apt update --fix-missing && apt upgrade -y
        apt-get -y install software-properties-common virt-what wget sudo
    elif [ "$lsb_dist" = "ubuntu" ]; then
        if [ "$dist_version" = "18.04" ] || [ "$dist_version" = "19.10" ]; then
            warn "Vous êtes sur Ubuntu ${dist_version}, cette version n'est pas recommandé.\nVoulez-vous quand même procéder ?\n[1]Oui.\n[2]Non."
            read choix
            case $choix in
                1 ) output "On continue !"
                    ;;
                2 ) output "Arrêt du script"
                    exit 7
                    ;;
            esac
        elif [ "$dist_version" = "19.10" ]; then
            sudo sed -i -e 's/archive.ubuntu.com\|security.ubuntu.com/old-releases.ubuntu.com/g' /etc/apt/sources.list || sed -i -e 's/archive.ubuntu.com\|security.ubuntu.com/old-releases.ubuntu.com/g' /etc/apt/sources.list
            grep -E 'archive.ubuntu.com|security.ubuntu.com' /etc/apt/sources.list.d/*
        fi
        dpkg --configure -a
        apt update --fix-missing && apt upgrade -y
        apt-get -y install software-properties-common virt-what wget
    fi

    virt_serv=$(echo $(virt-what))
    if [ "$virt_serv" = "" ]; then
        output "Votre environnement n'est pas virtualisé."
    else
        output "Votre environnement est '$virt_serv'.\nOCSInventory et GLPI peuvent s'exécuter dans un environnement virtuel."
    fi
    output "Voulez vous continuer ?\n[1] Oui.\n[2] Non."
    read choix
    case $choix in
        1)  output "Lancement....\n\n"
            ;;
        2)  output "Installation annulé."
            exit 8
            ;;
        *)  info "Aucune option choisie"
            exit 8
            ;;
    esac

}

os_check(){
    if [ -r /etc/os-release ]; then
        lsb_dist="$(. /etc/os-release && echo "$ID")"
        dist_version="$(. /etc/os-release && echo "$VERSION_ID")"
        info "Votre OS : ${lsb_dist} ${dist_version}"
    else
        warn "Erreur lors de la vérification de l'OS"
        exit 1
    fi

    if [ "$lsb_dist" = "debian" ]; then
        if [ "$dist_version" != "10" ] && [ "$dist_version" != "9" ]; then
            notsupported
        fi
    elif [ "$lsb_dist" = "ubuntu" ]; then
        if [ "$dist_version" != "20.10" ] && [ "$dist_version" != "20.04" ] && [ "$dist_version" != "19.10" ] && [ "$dist_version" != "18.04" ]; then
            notsupported
        fi
    #elif [ "$lsb_dist" = "centos" ]; then
    #    if [ "$dist_version" != "7" ] && [ "$dist_version" != "8" ]; then
    #        notsupported
    #    fi
    else
        notsupported
    fi
}

option_install(){
    output "Séléctionner l'option d'installation :"
    output "[1] Installer OCSInventory v${OCSVERSION}."
    output "[2] Installer GLPI v${GLPIVERSION}."
    output "[3] Installer GLPI v${GLPIVERSION} et OCSInventory v${OCSVERSION}."
    output "[4] Changer la version d'OCS"
    output "[5] Changer la version de GLPI"
    output "[6] Reset Password root of MySQL"
    read choix
    case $choix in
        1 ) optioninstall=1
            output "Vous avez choisie l'installation d'OCS uniquement."
            ;;
        2 ) optioninstall=2
            output "Vous avez choisie l'installation de GLPI uniquement."
            ;;
        3 ) optioninstall=3
            output "Vous avez choisie l'installation de GLPI et OCS."
            ;;
        4 ) output "Indiquez la version d'OCS que vous voulez installer :"
            read version
            OCSVERSION=$version
            option_install
            ;;
        5 ) output "Indiquez la version de GLPI que vous voulez installer :"
            read version
            GLPIVERSION=$version
            option_install
            ;;
        6 ) curl -sSL https://raw.githubusercontent.com/tommytran732/MariaDB-Root-Password-Reset/master/mariadb-104.sh | sudo bash
            ;;
        * ) info "Vous n'avez pas choisie d'option."
            option_install
            ;;
    esac
}

repositories_setup(){
    output "\nConfiguration des repo..."
    sleep 1
    if [ "$lsb_dist" = "ubuntu" ] || [ "$lsb_dist" = "debian" ]; then
        apt -y install curl
        apt -y install software-properties-common curl apt-transport-https ca-certificates gnupg
        curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash
        apt -y update
        apt -y upgrade
        apt -y autoremove
        apt -y autoclean
    fi
}

common_dependencies(){
    output "\nInstallation des dépendences..."
    sleep 1
    if [ "$lsb_dist" = "ubuntu" ] || [ "$lsb_dist" = "debian" ]; then
        apt -y install apache2 libapache2-mod-perl2
        apt -y install php php-curl php-gd php-json php-mbstring php-mysql php-xml php-intl php-cli php-ldap php-apcu php-xmlrpc
        apt install -y make sudo tar unzip build-essential
        apt -y install mariadb-server mariadb-client mariadb-common
    fi

    output "\nActivation des services..."
    sleep .5
    if [ "$lsb_dist" = "ubuntu" ] || [ "$lsb_dist" = "debian" ]; then
        systemctl enable apache2
        systemctl start apache2
    fi
    systemctl enable mariadb
    systemctl start mariadb
}

msyql_setup(){
    output "\nSetup de MySQL..."
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
    output "\nInstallation des dependences d'OCS"
    sleep .5
    if [ "$lsb_dist" = "ubuntu" ] || [ "$lsb_dist" = "debian" ]; then
        apt install -y php-zip php-soap libapache2-mod-php
        apt install -y perl6 libxml-simple-perl libdbi-perl libdbd-mysql-perl libapache-dbi-perl libnet-ip-perl libsoap-lite-perl libarchive-zip-perl
        if [ "$dist_version" = "9" ] || [ "$dist_version" = "18.04" ]; then
            cpan XML::Simple Compress::Zlib DBI DBD::mysql Apache::DBI Net::IP Mojolicious::Lite Plack::Handler Archive::Zip YAML XML::Entities Switch
        else
            cpan XML::Simple Compress::Zlib DBI DBD::mysql Apache::DBI Net::IP SOAP::Lite Mojolicious::Lite Plack::Handler Archive::Zip YAML XML::Entities Switch
        fi
    fi

}

glpi_dependencies(){
    output "\nInstallation des dependences de GLPI"
    sleep .5
    if [ "$lsb_dist" = "ubuntu" ] || [ "$lsb_dist" = "debian" ]; then
        apt install -y php-fileinfo php-simplexml php-cas php-bz2
    fi

}

ocs_install(){
    if [ "$lsb_dist" = "ubuntu" ] || [ "$lsb_dist" = "debian" ]; then
        sudo service apache2 restart #Load OCSInventory dependencies
        mkdir /opt/ocs
        wget https://github.com/OCSInventory-NG/OCSInventory-ocsreports/releases/download/${OCSVERSION}/OCSNG_UNIX_SERVER-${OCSVERSION}.tar.gz -P /opt/ocs
        tar -xf /opt/ocs/OCSNG_UNIX_SERVER-${OCSVERSION}.tar.gz
        rm /opt/ocs/OCSNG_UNIX_SERVER-${OCSVERSION}.tar.gz
        cp ./OCSNG_UNIX_SERVER-${OCSVERSION}/ /opt/ocs -r && rm ./OCSNG_UNIX_SERVER-${OCSVERSION}/ -R
        chmod +x /opt/ocs/OCSNG_UNIX_SERVER-${OCSVERSION}/setup.sh
        warn "\nDémarrage de l'installation OCS, vous allez indiquer les configurations d'ocs lors des étapes suivantes.${NC}"
        sleep 5
        cd /opt/ocs/OCSNG_UNIX_SERVER-${OCSVERSION}/
        sh setup.sh
    fi
}

glpi_install(){
    if [ "$lsb_dist" = "ubuntu" ] || [ "$lsb_dist" = "debian" ]; then
        mkdir /opt/glpi
        wget https://github.com/glpi-project/glpi/releases/download/${GLPIVERSION}/glpi-${GLPIVERSION}.tgz -P /opt/glpi
        tar -xf /opt/glpi/glpi-${GLPIVERSION}.tgz
        rm /opt/glpi/glpi-${GLPIVERSION}.tgz
        cp ./glpi/ /opt/ -r && rm ./glpi/ -R
        chmod 777 /opt/glpi/files/ -R
        chmod 777 /opt/glpi/config/ -R
        chmod 777 /opt/glpi/marketplace/ -R
    fi
}

ocs_webconfig(){
    if [ "$lsb_dist" = "ubuntu" ] || [ "$lsb_dist" = "debian" ]; then
        cp /etc/apache2/conf-available/ocsinventory-reports.conf /etc/apache2/sites-enabled/
        chmod 777 /var/lib/ocsinventory-reports/
        chmod 775 /usr/share/ocsinventory-reports/ocsreports/
        systemctl reload apache2
        cd /usr/share/ocsinventory-reports/ocsreports/files/
        mysql -f -hlocalhost -uroot -p$rootpassword ocsweb < ocsbase.sql >log.log
    fi
}

glpi_webconfig(){
    if [ "$lsb_dist" = "ubuntu" ] || [ "$lsb_dist" = "debian" ]; then
        glpiconf=/etc/apache2/conf-available/glpi.conf
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
    fi
}

ocs_mysql(){
    output "\nCréation de la base de donnée OCS..."
    ocs_password=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
    Q0="CREATE DATABASE IF NOT EXISTS ocsweb;"
    Q1="GRANT ALL ON ocsweb.* TO 'ocs'@'127.0.0.1' IDENTIFIED BY '$ocs_password';"
    Q2="FLUSH PRIVILEGES;"
    SQL="${Q0}${Q1}${Q2}"
    sudo mysql -u root -e "$SQL" -p$rootpassword
}

glpi_mysql(){
    output "\nCréation de la base de donnée GLPI..."
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
    output "Information sur MariaDB"
    output ""
    output "Votre mot de passe root MySQL est : $rootpassword"
    output ""
    output "###############################################################"
}

broadcast_ocs(){
    output "###############################################################"
    output "Base de donnée OCS :"
    output "Host: 127.0.0.1 || localhost"
    output "Port: 3306"
    output "User: ocs"
    output "Nom de la BDD: ocsweb"
    output "Password: $ocs_password"
    output ""
    output "Interface web d'OCS :"
    ip4=$(/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)
    output "http://${ip4}/ocsreports"
    output "Par défaut les identifiants sont :"
    output "User: admin"
    output "Password: admin"
    output "###############################################################"
}

broadcast_glpi(){
    output "###############################################################"
    output "Pour connecter GLPI à la base de donnée vous aurez besoin de ces informations :"
    output "Host: 127.0.0.1 || localhost"
    output "Port: 3306"
    output "User: glpi"
    output "Nom de la BDD: glpi"
    output "Password: $glpi_password"
    output ""
    output "Interface web de GLPI :"
    ip4=$(/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)
    output "http://${ip4}/glpi"
    output "Par défaut les identifiants sont :"
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
        sleep 5
        broadcast_glpi
        sleep 10
        broadcast_ocs
        ;;
esac
output "Fin du script d'installation."
