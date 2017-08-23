#This template is a monolithic template provisioning 2 web servers in a front end subnet, 2 db server in a backend subnet and a bastion servr with ansible in a bastion subnet
#Bastion subnet is the only available through ssh. Only http/s is available on front end subnet and no external access is allowed on backend subnet
#a custom script extension install ansible on bastion host