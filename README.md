# OCSInventory/GLPI-Script
Install OCSInventory, GLPI, MariaDB and OCS/GLPI connector. <br />
<br />
This script must be run as **root**. It is also **hightly recommended** to use this script on a **fresh** installation.<br />
<br />
What can this scipt do ?<br />
* Install OCSInventory with MySQL.<br />
* Install GLPI with MySQL.<br />
* Install GLPI + OCSInventory with MySQL.<br />
* Choose Specific Version of OCS.<br />
* Choose Specific Version of GLPI.<br />
* Install OCSInventory, GLPI, MySQL individually.<br />
* Install Plugin to connect OCS with GLPI.<br />
<br />

# OS compatible :
| Operating System  | Version | Compatibility        | Recommended        | Notes                                |
| ----------------- | ------- | -------------------- | ------------------ | ------------------------------------ |
| Ubuntu            | 20.10   | :heavy_check_mark:   | :heavy_check_mark: |                                      |
|                   | 20.04   | :heavy_check_mark:   | :heavy_check_mark: |                                      |
|                   | 18.04   | :heavy_check_mark:   | :yellow_circle:    |                                      |
| Debian            | 10      | :heavy_check_mark:   | :heavy_check_mark: | Highly recommended                   |
| CentOS Linux      | 8       | May work but         | not recommended    | [Convert To CentOS Stream 8](https://www.centos.org/download/)|
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
