if [ "$(uname)" = "Linux" ]; then
    if [ "$(uname -m)" = "x86_64" ]; then
        TERRAFORM_SOURCE=https://releases.hashicorp.com/terraform/0.14.6/terraform_0.14.6_linux_amd64.zip
    else
        # just in case
        TERRAFORM_SOURCE=https://releases.hashicorp.com/terraform/0.14.6/terraform_0.14.6_linux_386.zip
    fi
else
    echo "--- suporting install only for Linux, and you running on $(uname)"
fi

wget $TERRAFORM_SOURCE
unzip $TERRAFORM_SOURCE

echo "--- moving terraform to /usr/local/bin"
sudo cp terraform /usr/local/bin/
