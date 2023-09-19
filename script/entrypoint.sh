#!/bin/bash

set -o errexit -o pipefail -o nounset

echo '::group::Creating aurpush user'
useradd --create-home --shell /bin/bash aurpush
passwd --delete aurpush
mkdir -p /etc/sudoers.d/
echo "aurpush  ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/aurpush
echo '::endgroup::'

echo '::group::Initializing SSH directory'
mkdir -pv /home/aurpush/.ssh
touch /home/aurpush/.ssh/known_hosts
cp -v /aurpush/ssh_config /home/aurpush/.ssh/config
chown -vR aurpush:aurpush /home/aurpush
chmod -vR 600 /home/aurpush/.ssh/*
chown -vR aurpush:aurpush /aurpush > /dev/null
echo '::endgroup::'

exec runuser aurpush --command 'bash -l -c /aurpush/build.sh'
