# sky_box_interview
Deploy of X static, single paged web servers with Terraform, Nginx and Docker

####### setup #######
bash ./run_terraform.sh setup - run install_terraform.sh, which should install terraform if running on Linux VM

####### create #######
bash ./run_terraform.sh create ${cluster_name} ${cluster_size} :
1. creating ${cluster_name} folder in root directory with nested folders for each web-server
2. providing cluster configuration to main.tf, from main.tf.tmpl
3. providing web-server html pages content to ${cluster_name}/www*/index.html, from index.html.tmpl
4. creating ${cluster_size} web-servers according to generated ${cluster_name}/main.tf
5. load balancing not enabled
6. health endpoint not imlemented
7. support for setting different versions for the web-server and load-balancer not implemented

####### destroy #######
bash ./run_terraform.sh destroy ${cluster_name} - destroying with terraform ${cluster_name} instance and deleting ${cluster_name} folder

####### status #######
bash ./run_terraform.sh status - shows existing clusters
bash ./run_terraform.sh status ${cluster_name} - shows running nginx containers related to this cluster



