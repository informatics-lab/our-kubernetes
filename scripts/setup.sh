## Waaaaaaay smash it
# Install helm
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get | bash

# Install aswcli
pip3 install awscli --upgrade

# Install eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/download/latest_release/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# Install jq
sudo apt-get install jq

# Done!
echo "we done, boi!"
