# OCSInventory/GLPI-Script
Installation de OCSInventory, GLPI et MariaDB. <br />
<br />
Ce script doit être lancé avec l'utilisateur root, il est préférable qu'il soit utilisé sur une nouvelle installation.<br />
<br />
Ce que peut faire ce script :<br />
* Install OCSInventory with MySQL.<br />
* Install GLPI with MySQL.<br />
* Install GLPI + OCSInventory with MySQL.<br />
* Choose Specific Version of OCS.<br />
* Choose Specific Version of GLPI.<br />
* Install OCSInventory, GLPI, MySQL individually.<br />
<br />
Si vous rencontrez un problème ou que vous avez une suggestion ou que vous voulez modifier ce script libre à vous de me contacter.<br />
<br />

# OS compatible :
| Operating System  | Version | Compatibilité        | Recommandé         | Notes                                |
| ----------------- | ------- | -------------------- | ------------------ | ------------------------------------ |
| Ubuntu            | 20.10   | :heavy_check_mark:   | :heavy_check_mark: |                                      |
|                   | 20.04   | :heavy_check_mark:   | :heavy_check_mark: |                                      |
|                   | 18.04   | :heavy_check_mark:   | :yellow_circle:    |                                      |
| Debian            | 10      | :heavy_check_mark:   | :heavy_check_mark: | Highly recommended                   |
| CentOS Linux      | 8       |                      |                    | [Convert To CentOS Stream 8](https://www.centos.org/download/)|
|                   | 7       | :heavy_check_mark:   | :heavy_check_mark: |                                      |
| CentOS Stream     | 8       | :question:           |                    | Not tested                           |
| Fedora            | 33      | :red_circle:         |                    | ToDO                                 |

> Tested under HyperV, LXC and Bare Metal<br />

*If your system is not available don't hesited to ask me to add it*

# Download and use :
```shell
wget https://raw.githubusercontent.com/Lowan-S/OCSInventory_GLPI/main/install.sh
bash install.sh
```
