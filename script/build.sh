#!/bin/bash

set -o errexit -o pipefail -o nounset
GLOBIGNORE=".:.."

ssh-keyscan -v -t rsa aur.archlinux.org >>~/.ssh/known_hosts

echo "$SSH_PRIVATE_KEY" >~/.ssh/aur
chmod -vR 600 ~/.ssh/aur*
ssh-keygen -vy -f ~/.ssh/aur >~/.ssh/aur.pub

sha512sum ~/.ssh/aur ~/.ssh/aur.pub

git config --global user.name "$COMMIT_USERNAME"
git config --global user.email "$COMMIT_EMAIL"

echo $COMMIT_USERNAME $COMMIT_EMAIL

aur_path='/aurpush/aur'
aur_git_path='/aurpush/aur-git'
cd $aur_path
for pkgbase in *; do
  git clone -v "ssh://aur@aur.archlinux.org/${pkgbase}.git" $aur_git_path/$pkgbase
  cd $aur_git_path/$pkgbase
  _pkgrel=`sed -n '/^pkgrel=/{s/pkgrel=\([0-9]*\).*/\1/p}' PKGBUILD`
  cp -ar $aur_path/$pkgbase/* $aur_git_path/$pkgbase
  updpkgsums
  makepkg -s --noconfirm
  makepkg --printsrcinfo > .SRCINFO

  if [ -n "$(git diff)" ];
  then
    aur_commit_message=$COMMIT_MESSAGE
    if [ -n "$(git diff | grep -E '\-pkgver|\+pkgver')" ];
    then
      _pkgname=`sed -n '/^pkgname=/p' PKGBUILD | sed 's/^pkgname=//'| sed 's/\"//g'`
      aur_commit_message=$_pkgname' Auto update to '$(git diff | grep -E '\+pkgver' | sed 's/+pkgver=//')
    else
      _pkgrel=$((_pkgrel + 1))
      sed -i "s/^pkgrel=\([0-9]\+\)/pkgrel=${_pkgrel}/g" PKGBUILD
    fi

    git add --all
    git diff-index --quiet HEAD || git commit -m "$aur_commit_message"
    if [ $AUR_PUSH==true ]
    then
      git push origin master
    else
      echo "Only push when submitting the master branch!"
    fi
  fi
done
