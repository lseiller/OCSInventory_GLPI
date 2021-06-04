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
        output "Debian 10"
        output "Debian 9"
        output "Ubuntu 20.10"
        output "Ubuntu 20.04"
        output "Ubuntu 19.10"
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

    output "\nC'est partit !"

    if [ "$lsb_dist" = "debian" ]; then
        dpkg --configure -a
        apt update --fix-missing && apt upgrade -y
        apt-get -y install software-properties-common virt-what wget sudo
    elif [ "$lsb_dist" = "ubuntu" ]; then
        if [ "$dist_version" = "19.10" ]; then
            sudo sed -i -e 's/archive.ubuntu.com\|security.ubuntu.com/old-releases.ubuntu.com/g' /etc/apt/sources.list || sed -i -e 's/archive.ubuntu.com\|security.ubuntu.com/old-releases.ubuntu.com/g' /etc/apt/sources.list
            grep -E 'archive.ubuntu.com|security.ubuntu.com' /etc/apt/sources.list.d/*
            sudo apt-get update -y || apt-get update -y
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
            exit 7
            ;;
        *)  info "Aucune option choisie"
            exit 7
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
    else
        notsupported
    fi
}

option_install(){
    output "Séléctionner l'option d'installation :"
    output "[1] Installer OCSInventory v${OCSVERSION}."
    output "[2] Installer GLPI v${GLPIVERSION}."
    output "[3] Installer GLPI v${GLPIVERSION} et OCSInventory v${OCSVERSION}."
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
        * ) info "Vous n'avez pas choisie d'option."
            option_install
            ;;
    esac
}

repositories_setup(){
    output "\nConfiguration des repo..."
    sleep 1
    if [ "$lsb_dist" = "ubuntu" ] || [ "$lsb_dist" = "debian" ]; then
        apt-get -y install curl
        apt-get -y install software-properties-common curl apt-transport-https ca-certificates gnupg
        curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash
        if [ "$lsb_dist" = "ubuntu" ]; then
            LC_ALL=C.UTF-8
        fi
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
        apt -y install php php-zip php-gd php-curl php-mbstring php-soap php-xml php-mysql libapache2-mod-php php-json php-intl php-cli php-ldap php-xmlrpc php-apcu
        apt install -y make sudo tar unzip build-essential
        apt -y install mariadb-server mariadb-client mariadb-common
    fi

    output "\nActivation des services..."
    sleep .5
    if [ "$lsb_dist" = "ubuntu" ] || [ "$lsb_dist" = "debian" ]; then
        systemctl start apache2
        systemctl enable mariadb
        systemctl start mariadb
    fi
}

ocs_dependencies(){
    output "\nInstallation de perl"
    sleep .5
    if [ "$lsb_dist" = "ubuntu" ] || [ "$lsb_dist" = "debian" ]; then
        if [ "$dist_version" = "9" ] || [ "$lsb_version" = "18.04" ]; then
            apt-get source apache2
        fi
        apt install -y perl6 libxml-simple-perl libdbi-perl libdbd-mysql-perl libapache-dbi-perl libnet-ip-perl libsoap-lite-perl libarchive-zip-perl
        cpan XML::Simple Compress::Zlib DBI DBD::mysql Apache::DBI Net::IP SOAP::Lite Mojolicious::Lite Plack::Handler Archive::Zip YAML XML::Entities Switch
    fi

}

ocs_install(){
    if [ "$lsb_dist" = "ubuntu" ] || [ "$lsb_dist" = "debian" ]; then
        mkdir /opt/ocs
        wget https://github.com/OCSInventory-NG/OCSInventory-ocsreports/releases/download/${OCSVERSION}/OCSNG_UNIX_SERVER-${OCSVERSION}.tar.gz -P /opt/ocs
        tar -xf /opt/ocs/OCSNG_UNIX_SERVER-${OCSVERSION}.tar.gz
        cp ./OCSNG_UNIX_SERVER-${OCSVERSION}/ /opt/ocs -r && rm ./OCSNG_UNIX_SERVER-${OCSVERSION}/ -R
        chmod +x /opt/ocs/OCSNG_UNIX_SERVER-${OCSVERSION}/setup.sh
        warn "\nDémarrage de l'installation OCS, vous allez indiquer les configurations d'ocs lors des étapes suivantes.${NC}"
        sleep 5
        cd /opt/ocs/OCSNG_UNIX_SERVER-${OCSVERSION}/
        sh setup.sh
    fi
}

ocs_webconfig(){
    if [ "$lsb_dist" = "ubuntu" ] || [ "$lsb_dist" = "debian" ]; then
        cp /etc/apache2/conf-available/ocsinventory-reports.conf /etc/apache2/sites-enabled/
        chmod 755 /usr/share/ocsinventory-reports/ocsreports/logs/
        systemctl reload apache2
    fi
}

ocs_mysql(){
    output "\nCréation du mot de passe pour la base de donnée..."
    ocs_password=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
    rootpassword=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
    Q0="DROP DATABASE IF EXISTS test;"
    Q1="CREATE DATABASE IF NOT EXISTS ocsweb;"
    Q2="SET old_passwords=0;"
    Q3="GRANT ALL ON ocsweb.* TO 'ocs'@'127.0.0.1' IDENTIFIED BY '$ocs_password';"
    Q4="SET PASSWORD FOR 'root'@'localhost' = PASSWORD('$rootpassword');"
    Q5="DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
    Q6="DELETE FROM mysql.user WHERE User='';"
    Q7="DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%';"
    Q8="FLUSH PRIVILEGES;"
    SQL="${Q0}${Q1}${Q2}${Q3}${Q4}${Q5}${Q6}${Q7}${Q8}"
    sudo mysql -u root -e "$SQL"
}

ocs_setup(){
    ocs_dependencies
    ocs_install
    ocs_webconfig
    ocs_mysql
}

broadcast_ocs(){
    output "###############################################################"
    output "Information sur la base de donnée MariaDB"
    output ""
    output "Votre mot de passe root de MySQL est : $rootpassword"
    output ""
    output "Pour connecter OCS à la base de donnée vous aurez besoin de ces informations :"
    output "Host: 127.0.0.1 || localhost"
    output "Port: 3306"
    output "User: ocs"
    output "Nom de la BDD: ocsweb"
    output "Password: $ocs_password"
    output ""
    output "Interface web d'OCS :"
    ip4=$(/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)
    output "http://${ip4}/ocsreports"
    output "Par défaut les identifiants :"
    output "User: admin"
    output "Password: admin"
    output "###############################################################"
}

preinstall
option_install
case $optioninstall in
    1 ) repositories_setup
        common_dependencies
        ocs_setup
        broadcast_ocs
        ;;
    2 ) output "pour l'instant support uniquement ocs"
        #repositories_setup
        ;;
    3 ) output "pour l'instant support uniquement ocs"
        #repositories_setup
        ;;
esac
output "Fin du script d'installation."