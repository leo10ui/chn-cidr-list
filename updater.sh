#!/bin/bash
eval $(ssh-agent -s)
echo "$SSH_PRIVATE_KEY" | tr -d "\r" | ssh-add -
mkdir -p ~/.ssh
chmod 700 ~/.ssh
ssh-keyscan gitlab.com > ~/.ssh/known_hosts
git config --global user.email "$GIT_MAIL_ADDRESS"
git config --global user.name "fernvenue"
git clone git@gitlab.com:fernvenue/chn-cidr-list.git
cd "./chn-cidr-list"
curl "https://raw.githubusercontent.com/gaoyifan/china-operator-ip/ip-lists/china.txt" > bgp-ipv4.list
curl "https://raw.githubusercontent.com/gaoyifan/china-operator-ip/ip-lists/china6.txt" > bgp-ipv6.list
curl "http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest" | grep ipv4 | grep CN | awk -F\| '{ printf("%s/%d\n", $4, 32-log($5)/log(2)) }' > apnic-ipv4.list
curl "http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest" | grep '|CN|ipv6|' | cut -d'|' -f'4,5' | tr '|' '/' > apnic-ipv6.list
sed -i "s/[[:space:]]//g" ./*.list
chmod +x ./tools/cidr-merger
cat ./*ipv4.list | ./tools/cidr-merger -s > ./ipv4.txt
cat ./*ipv6.list | ./tools/cidr-merger -s > ./ipv6.txt
cp ./ipv4.txt ./ipv4.conf && cp ./ipv4.txt ./ipv4.yaml
cp ./ipv6.txt ./ipv6.conf && cp ./ipv6.txt ./ipv6.yaml
sed -i "s|^|IP-CIDR,|g" ./*.conf
sed -i "s|^|  - '&|g" ./*.yaml
sed -i "s|$|&'|g"  ./*.yaml
sed -i "1s|^|payload:\n|" ./*.yaml
cat ./ipv4.txt ./ipv6.txt > ./ip.txt
cat ./ipv4.conf ./ipv6.conf > ./ip.conf
cat ./ipv4.yaml ./ipv6.yaml > ./ip.yaml
rm ./*.mmdb
updated=`date --rfc-3339 sec`
sed -i "1i # GitHub: https://github.com/fernvenue/chn-cidr-list" ./ip*
sed -i "1i # GitLab: https://gitlab.com/fernvenue/chn-cidr-list" ./ip*
sed -i "1i # Updated: $updated" ./ip*
sed -i "1i # License: BSD-3-Clause License" ./ip*
sed -i "1i # CHN CIDR list" ./ip*
chmod +x ./tools/cidr2mmdb
./tools/cidr2mmdb -i ./ipv4.txt -o ./ipv4.mmdb
./tools/cidr2mmdb -i ./ipv6.txt -o ./ipv6.mmdb
./tools/cidr2mmdb -i ./ip.txt -o ./ip.mmdb
rm *.list
git init
git add .
git commit -m "$updated"
git push -u origin master
