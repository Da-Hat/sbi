# sed -i works differently on mac and linux
if [ "$(uname)" == "Darwin" ]; then
	SED_CMD="sed -i ''"
else
	SED_CMD="sed -i''"
fi

ACTION=$1
CLUSTER_NAME=$2
CLUSTER_NUMBER=$(echo "$CLUSTER_NAME" | sed 's/[^0-9]*//g')
CLUSTER_SIZE=$3

WORK_DIR=$(pwd)

case $ACTION in
    setup)
        echo "--- setuping"
        bash ./install_terraform.sh
        ;;
    create)
        [[ "${CLUSTER_NAME%"$CLUSTER_NUMBER"}" != "cluster_" ]] && echo "--- please use cluster_\${cluster_number} patern for cluster name - exiting" && exit
        [[ "$CLUSTER_SIZE" == "" ]] && echo "--- please enter number of web servers in the cluster - exiting" && exit
                
        echo "--- providing cluster configuration to main.tf"
        mkdir $CLUSTER_NAME
        TERRAFORM_CONFIG_FILE=main_$CLUSTER_NAME.tf
        cp $WORK_DIR/main.tf.tmpl $WORK_DIR/$CLUSTER_NAME/$TERRAFORM_CONFIG_FILE
        ${SED_CMD} "s/\${cluster_size}/$CLUSTER_SIZE/g" $WORK_DIR/$CLUSTER_NAME/$TERRAFORM_CONFIG_FILE; rm $WORK_DIR/$CLUSTER_NAME/$TERRAFORM_CONFIG_FILE\'\'
        ${SED_CMD} "s/\${cluster_name}/$CLUSTER_NAME/g" $WORK_DIR/$CLUSTER_NAME/$TERRAFORM_CONFIG_FILE; rm $WORK_DIR/$CLUSTER_NAME/$TERRAFORM_CONFIG_FILE\'\'
        ${SED_CMD} "s/\${cluster_number}/$CLUSTER_NUMBER/g" $WORK_DIR/$CLUSTER_NAME/$TERRAFORM_CONFIG_FILE; rm $WORK_DIR/$CLUSTER_NAME/$TERRAFORM_CONFIG_FILE\'\'
        ${SED_CMD} "s/\${work_dir}/$(echo $WORK_DIR | sed 's_/_\\/_g')/g" $WORK_DIR/$CLUSTER_NAME/$TERRAFORM_CONFIG_FILE; rm $WORK_DIR/$CLUSTER_NAME/$TERRAFORM_CONFIG_FILE\'\'
        
        # echo "--- providing cluster configuration to load balancer"
        # mkdir $WORK_DIR/$CLUSTER_NAME/nginx_lb-$CLUSTER_NUMBER
        # cp -r $WORK_DIR/nginx_lb.tmpl/ $WORK_DIR/$CLUSTER_NAME/nginx_lb-$CLUSTER_NUMBER
        # ${SED_CMD} "s/\${cluster_number}/$CLUSTER_NUMBER/g" $WORK_DIR/$CLUSTER_NAME/nginx_lb-$CLUSTER_NUMBER/index.html; rm $WORK_DIR/$CLUSTER_NAME/nginx_lb-$CLUSTER_NUMBER/index.html\'\'    
        # ${SED_CMD} "s/\${cluster_number}/$CLUSTER_NUMBER/g" $WORK_DIR/$CLUSTER_NAME/nginx_lb-$CLUSTER_NUMBER/nginx.conf; rm $WORK_DIR/$CLUSTER_NAME/nginx_lb-$CLUSTER_NUMBER/nginx.conf\'\'
        # ${SED_CMD} "s/\${list_of_servers}/'$LIST_OF_SERVERS'/g" $WORK_DIR/$CLUSTER_NAME/nginx_lb-$CLUSTER_NUMBER/nginx.conf; rm $WORK_DIR/$CLUSTER_NAME/nginx_lb-$CLUSTER_NUMBER/nginx.conf\'\'    

        echo "--- configuring $CLUSTER_SIZE web-servers on $CLUSTER_NAME"
        COUNTER=0
        until [ $COUNTER == $CLUSTER_SIZE ]; do
            let COUNTER=$COUNTER+1
            cp -r $WORK_DIR/www.tmpl $WORK_DIR/$CLUSTER_NAME/www_$CLUSTER_NAME\_$COUNTER
            mv $WORK_DIR/$CLUSTER_NAME/www_$CLUSTER_NAME\_$COUNTER/index.html.tmpl $WORK_DIR/$CLUSTER_NAME/www_$CLUSTER_NAME\_$COUNTER/index.html
            ${SED_CMD} "s/\${server_number}/$COUNTER/g" $WORK_DIR/$CLUSTER_NAME/www_$CLUSTER_NAME\_$COUNTER/index.html; rm $WORK_DIR/$CLUSTER_NAME/www_$CLUSTER_NAME\_$COUNTER/index.html\'\'
            ${SED_CMD} "s/\${cluster_name}/$CLUSTER_NAME/g" $WORK_DIR/$CLUSTER_NAME/www_$CLUSTER_NAME\_$COUNTER/index.html; rm $WORK_DIR/$CLUSTER_NAME/www_$CLUSTER_NAME\_$COUNTER/index.html\'\'
        done

        echo "--- create docker network and building docker loadbalancer"
        # docker network create --ip-range=172.$CLUSTER_NUMBER\0.0.0/$CLUSTER_SIZE --subnet=172.$CLUSTER_NUMBER\0.3.0/$CLUSTER_SIZE --gateway=172.$CLUSTER_NUMBER\0.0.254 sbi-nginx-$CLUSTER_NUMBER
        # cd $WORK_DIR/nginx_lb; docker build -t sbi-nginx-lb-$CLUSTER_NUMBER .; cd $WORK_DIR
        
        cd $WORK_DIR/$CLUSTER_NAME
        terraform init
        terraform plan
        terraform apply -auto-approve
        # terraform apply 

        echo "--- started containers:"
        docker ps -f "name=$CLUSTER_NAME"
        ;;
    status)
        if [ "${CLUSTER_NAME%"$CLUSTER_NUMBER"}" == "cluster_" ]; then
            echo "--- status of $CLUSTER_NAME:"
            docker ps -f "name=$CLUSTER_NAME"
        else
            echo "--- existing clusters:"
            ls | grep "cluster_"
        fi
        ;;
    destroy)
        [[ "${CLUSTER_NAME%"$CLUSTER_NUMBER"}" != "cluster_" ]] && echo "--- use cluster_\${cluster_number} for cluster name - exiting" && exit
        echo "--- destroing $CLUSTER_NAME"
        if [ -d $CLUSTER_NAME ]; then
            echo "--- $CLUSTER_NAME existing - deleting"
            cd $WORK_DIR/$CLUSTER_NAME
            # docker run -i -t hashicorp/terraform:light terraform destroy -auto-approve
            terraform destroy -auto-approve
            # terraform destroy
            cd $WORK_DIR/
            rm -rf $WORK_DIR/$CLUSTER_NAME
            docker network rm sbi-nginx-$CLUSTER_NUMBER
        else
            echo "--- $CLUSTER_NAME doesn't exist curent clusters are:"
            ls | grep "cluster_"
        fi
        ;;
    *)
        echo "first argument should be - setup\\create\\status\\destroy, exiting"; exit
        ;;
esac




# terraform plan -out config.tfplan
# terraform apply
