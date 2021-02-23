# Azure HPC On-Demand Platform, your deployment to be HPC-Ready! 

Azure HPC On-Demand Platform, provides the end-2-end deployment mechanism for a base HPC infrastructure on Azure. Industry standard tools like Terraform, Ansible and Packer are used to provision and configure this environment containing :
- An OpenOn Demand Portal for all user access, remote shell access, remote visualization access, job submission, file access and more,
- An Active Directory for user authentication and domain control,
- A PBS Job Scheduler,
- Cycle Cloud 8.1 to handle autoscaling of PBS Nodes thru PBS integration,
- A Jumpbox to provide admin access,
- Azure Netapp Files for home directory and data storage,
- CVMFS over blobs mounted to access the application library,
- A Grafana dashboard to monitor your cluster

# Toolchain setup
The toolchain can be setup either from a docker container or locally. See below for instructions regarding the installation.

## Clone the repo
- Option 1
```
git clone --recursive https://github.com/Azure/az-hop.git
```
 
- Option 2
```
git clone https://github.com/Azure/az-hop.git 
git submodule init
git submodule update
```

## HPC Rover - Setup the toolchain from a container

The `HPC Rover` is a docker container acting as a sandbox toolchain development environemnt to avoid impacting the local machine configuration. It is the same container if you are using Windows, Linux or macOS, you only need Visual Studio Code.

<img src="https://code.visualstudio.com/assets/docs/remote/containers/architecture-containers.png" width="75%">

You can learn more about the Visual Studio Code Remote on this [link](https://code.visualstudio.com/docs/remote/remote-overview).

To start the container in VS Code, simply open the cloned repository directory (from the **File** menu or by using `code .` from the cloned directory in a separate WSL instance) and click on **Reopen in Container** in the pop-up notification in the bottom right corner.

### Pre-requisites

The Visual Studio Code system requirements describe the steps to follow to get your development environment ready -> [link](https://code.visualstudio.com/docs/remote/containers#_system-requirements)

* **Windows**: Docker Desktop 2.0+ on Windows 10 Pro/Enterprise with Linux Container mode
* **macOS**: Docker Desktop 2.0+
* **Linux**: Docker CE/EE 18.06+ and Docker Compose 1.24+

The `HPC Rover` is a Ubuntu 18.04 base image and is hosted on the Docker Hub [Link](https://hub.docker.com/r/xpillons/hpcrover/tags?page=1&ordering=last_updated)

Install
* Visual Studio Code version 1.41+ - [link](https://code.visualstudio.com/Download)
* Install Visual Studio Code Extension - Remote Development - [link](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack)

## Setup on Ubuntu (e.g. WSL2)

```
# install terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform

# install ansible
sudo apt-get install ansible
# These are needed for AD
ansible-galaxy collection install ansible.windows
ansible-galaxy collection install community.windows
# These are needed for OpenOnDemand
ansible-galaxy collection install ansible.posix
ansible-galaxy collection install community.general

# install python packages
sudo apt-get install python3-pip
pip3 install pypsrp
pip3 install pysocks

# install yq
VERSION=v4.2.0
BINARY=yq_linux_amd64
sudo wget https://github.com/mikefarah/yq/releases/download/${VERSION}/${BINARY} -O /usr/bin/yq && sudo chmod +x /usr/bin/yq
```

## Deploying

```bash
# Login to Azure
az login

# Review the current subscription
az account show

# Change your default subscription if needed
az account set -s <subid>

# Use the **config.tpl.yml** as a template to create the **config.yml** file.

# Build the whole infrastructure
./build.sh -f ./tf -a apply

# Create users passwords for all users defined in the config.yml file
./create_passwords.sh

# install
./install.sh
```

### Accessing the CycleCloud portal
You need to create an ssh tunnel. From the outside of the container if you run the toolchain from inside a container.

```bash
./bin/connect cyclecloud
```

Browse to the cycle UI https://localhost:9443

Connect to Cycle with the **hpcadmin** user, read the secret stored in the key vault by running the **get_secret** helper command.
```bash
./bin/get_secret hpcadmin
```

### Accessing the az-hop Portal
In the inventory file, locate the **ondemand_fqdn** variable

```bash
grep ondemand_fqdn playbooks/group_vars/all.yml
```
Browse to this URI

Connect with your the user account defined in the config.yml and it's password stored in key vault.

```bash
./bin/get_secret <user>
```

From the portal, select the menu **Clusters/_my_cluster Shell Access** to open a shell window, and the submit a simple test job.


```bash
qsub -l select=1:slot_type=hb60rs -- /usr/bin/bash -c 'sleep 60'
qstat
```
### Accessing the Grafana dashboard
To access the grafana dashboard, browse to **https://<ondemand_fqdn>/rnode/jumpbox/3000/**
On the grafana page, to view the default dashboard, in the left menu select dashboard/manage and then select _Telegraf: system dashboard_



# Delete all
```bash 
./build.sh -f ./tf -a destroy
```

## Persisting Terraform state in blobs
Terraform can persist it's deployment state into blobs. For this the storage account need to be created before running the `terraform init` command.
The `backend.sh` script will create a random storage account, and create the `./tf/backend.tf` file with all the values needed to keep the state there. The `build.sh` script will set the ARM_ACCESS_KEY used by Terraform to access the storage account.

Before running the `build.sh` script, run the `backend.sh` script.
```
./backend.sh
```

## Using Service Principal Name to build

Create a contributor SPN, give it a name you want
```
az ad sp create-for-rbac --name terraform_spn

# Keep the output safe as it contains a secret that will be displayed only once and needed later

# Assign the role "User Access Administrator" in order to create managed identity for CycleCloud

az role assignment create --assignee "http://terraform_spn" --role "User Access Administrator"


```
In order to use your SPN with packer to buid images you have to store it's secret in a keyvault and grant a read access policy to this 

> Note: You can also have a look on how to configure a [devops environment](./devops/readme.md).

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft 
trademarks or logos is subject to and must follow 
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.

