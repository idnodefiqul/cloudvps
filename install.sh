#!/bin/bash
git clone --quiet https://github.com/KangQull/cloudsinstaller.git
#remove
mv cloudsinstaller/menuclouds ~/
mv cloudsinstaller/removenextcloud ~/
mv cloudsinstaller/removeowncloud ~/
mv cloudsinstaller/uploadsetting ~/
rm -rf cloudsinstaller
chmod +x menuclouds
chmod +x removenextcloud
chmod +x removeowncloud
chmod +x uploadsetting
mv menuclouds /usr/local/bin
cat <<EOF >> ~/.bashrc
menuclouds
EOF
mv removenextcloud /usr/local/bin
mv removeowncloud /usr/local/bin
mv uploadsetting /usr/local/bin
#memulai install
menuclouds
