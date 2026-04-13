#!/bin/sh
# from https://docs.cloud.google.com/sdk/docs/install-sdk#deb

sudo apt-get -qq update
sudo apt-get -qq install apt-transport-https ca-certificates gnupg curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor --yes -o /usr/share/keyrings/cloud.google.gpg
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list > /dev/null
sudo apt-get -qq update && sudo apt-get -qq install google-cloud-cli