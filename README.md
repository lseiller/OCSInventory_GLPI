## This repo is not maintained, the script was made to automate a process I had to do during a high school internship.
I had done it to train myself in bash scripting, I was absolutely not competent enough in shell to write a script in an "optimal" way (i.e. readable, using intelligently the bash functionalities, managing several distributions and knowledge in each of them, etc).
I don't recommend using this script.

# OCSInventory/GLPI-Script
Install OCSInventory, GLPI, MariaDB and OCS/GLPI plugin. <br />
<br />
This script must be run as **root**. It is also **hightly recommended** to use this script on a **fresh** installation.<br />
<br />
What can this script do ?<br />
* Install OCSInventory (+ MySQL).<br />
* Install GLPI (+ MySQL).<br />
* Install GLPI + OCSInventory (+ MySQL).<br />
* Install MySQL for GLPI and/or OCS.<br />
* Choose a Specific Version of OCS.<br />
* Choose a Specific Version of GLPI.<br />
* Reset root password of MySQL.<br />
* Add the Plugin to connect OCS with GLPI.<br />

# Use :
```shell
bash install.sh
```

# Supported OS :
| Operating System  | Version | Compatibility        | Recommended        | Notes                                |
| ----------------- | ------- | -------------------- | ------------------ | ------------------------------------ |
| Ubuntu            | 21.04   | :heavy_check_mark:   | :heavy_check_mark: |                                      |
|                   | 20.04   | :heavy_check_mark:   | :heavy_check_mark: |                                      |
|                   | 18.04   | :heavy_check_mark:   | :yellow_circle:    |                                      |
| Debian            | 10      | :heavy_check_mark:   | :heavy_check_mark: | **Highly recommended**               |
| CentOS Linux      | 8       | :red_circle:         | :red_circle:       | https://www.centos.org/download/     |
|                   | 7       | :red_circle:         | :red_circle:       | All CentOS won't work, I will fix it |
| CentOS Stream     | 8       | :red_circle:         | :red_circle:       | later.                               |
| Fedora            | 34      | :yellow_circle:      | :heavy_check_mark: | OCS Install is working but not GLPI  |
| ----------------- | ------- | -------------------- | -----------------> | Tested under KVM, LXC & Bare Metal   |
