#!/bin/bash

# Global Vars
DOWNLOAD_PATH=$HOME/Downloads/tmp
OS_VERSION=24.04 LTS
BC_VERSION=0.5.15

# Fetch all the named args
while [ $# -gt 0 ]; do

   if [[ $1 == *"--"* ]]; then
        v="${1/--/}"
        declare $v="$2"
   fi

  shift
done

clear

echo "----------------------------------------------------"
echo "Welcome to bunnychow $OS_VERSION (v$BC_VERSION)"
if [ -n "$debs" ]; then
  echo "=> The following will be installed:"
  echo " -> debs: $debs"
fi
if [ -n "$flatpaks" ]; then
  echo "=> the following flatpaks will be installed"
  echo " -> $flatpaks"
fi
if [ -n "$snaps" ]; then
  echo "=> the following snaps will be installed"
  echo " -> $snaps"
fi
if [ -n "$apt_install" ]; then
  echo "=> the following apt install(s) will be invoked"
  echo " -> $apt_install"
fi
if [ -n "$apt_remove" ]; then
  echo "=> the following apt remove(s) will be invoked"
  echo " -> $apt_remove"
fi
if [[ $dark_theme == "yes" ]]; then
  echo "=> dark theme will be set"
fi
if [[ $install_drivers == "yes" ]]; then
  echo "=> missing drivers will be installed (ubuntu-drivers)"
fi
if [ -n "$git_username" ]; then
  echo "=> git user.name set to $git_username"
fi
if [ -n "$git_useremail" ]; then
  echo "=> git user.email set to $git_useremail"
fi
if [[ $gen_ssh == "yes" ]]; then
  echo "=> ssh key will be generated for $USER"
fi
if [[ $neaten == "yes" ]]; then
  echo "=> plasmashell will be neated and reloaded"
fi
echo "----------------------------------------------------"

mkdir -p $DOWNLOAD_PATH

if [[ $gen_ssh == "yes" ]]; then
  ssh-keygen -f $HOME/.ssh/id_rsa -N ""
fi

if [ -n "$git_username" ]; then
  sudo apt-get install -yq git
  git config --global user.name "$git_username"
fi

if [ -n "$git_useremail" ]; then
  sudo apt-get install -yq git
  git config --global user.email "$git_useremail"
fi

echo "=> APT UPDATE AND UPGRADE"
sudo apt-get update
sudo apt-get upgrade -yq
sudo snap refresh

if [[ $install_drivers == "yes" ]]; then
  sudo ubuntu-driver install
fi

if [ -n "$apt_remove" ]; then
  echo "=> APT REMOVES"
  IFS=',' read -ra app_list <<< "$apt_remove"
  for app in "${app_list[@]}"; do
     echo "=> removing $app"
     sudo apt-get remove -yq $app
  done
fi

if [ -n "$apt_install" ]; then
  echo "=> APT INSTALLS"
  IFS=',' read -ra app_list <<< "$apt_install"
  for app in "${app_list[@]}"; do
     echo "=> installing $app"
     sudo apt-get install -yq $app
  done
fi

if [ -n "$snaps" ]; then
  echo "=> INSTALLING SNAPS"
  sudo apt-get install -yq snapd
  IFS=',' read -ra app_list <<< "$snaps"
  for app in "${app_list[@]}"; do
     echo "-> installing snap $app"
     sudo snap install $app
  done
fi

# INSTALL: VS CODE
if [[ $debs =~ "vscode" ]]; then
  echo "=> INSATLLING VSCODE"
  echo "code code/add-microsoft-repo boolean true" | sudo debconf-set-selections
  sudo apt-get install -yq wget gpg
  wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
  sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
  echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
  rm -f packages.microsoft.gpg
  sudo apt-get install -yq apt-transport-https
  sudo apt update
  sudo apt-get install -yq code
fi

# INSTALL: BRAVE
if [[ $debs =~ "brave" ]]; then
  echo "=> INSATLLING BRAVE BROWSER"
  curl -fsS https://dl.brave.com/install.sh | sh
fi

# INSTALL: Chrome
if [[ $debs =~ "chrome" ]]; then
  echo "=> INSATLLING CHROME"
  wget -c https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O $DOWNLOAD_PATH/chrome.deb
  sudo apt-get install -yq $DOWNLOAD_PATH/chrome.deb
fi

# INSTALL: dbeaver
if [[ $debs =~ "dbeaver" ]]; then
  wget -c https://dbeaver.io/files/dbeaver-ce_latest_amd64.deb -O $DOWNLOAD_PATH/dbeaver.deb
  sudo apt-get install -yq $DOWNLOAD_PATH/dbeaver.deb
fi

# INSTALL: docker
if [[ $debs =~ "docker" ]]; then
  echo "=> INSATLLING DOCKER"
  for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done
  sudo apt-get update
  sudo apt-get install -yq ca-certificates curl
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  sudo apt-get update
  sudo apt-get -yq install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo usermod -aG docker $USER
fi

if [ -n "$debs" ]; then
  echo "=> run fixes if needed"
  sudo apt-get install -f
fi

if [ -n "$flatpaks" ]; then
  echo "=> INSATLLING flatpak, flathub and flatpak apps"
  sudo apt-get install -yq flatpak kde-config-flatpak
  sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

  IFS=',' read -ra app_list <<< "$flatpaks"
  for app in "${app_list[@]}"; do
      sudo flatpak install --noninteractive -y $app
  done
fi

if [[ $dark_theme == "yes" ]]; then
  plasma-apply-lookandfeel -a org.kde.breezedark.desktop --resetLayout
  flatpak install --noninteractive -y org.gtk.Gtk3theme.Adwaita-dark
  sudo flatpak override --env=GTK_THEME=Adwaita-dark
  wget -c https://raw.githubusercontent.com/howzitcal/bunnychow/refs/heads/main/24.04/wallpaper.jpg -O ~/Pictures/wallpaper.jpg
  plasma-apply-wallpaperimage ~/Pictures/wallpaper.jpg
  sudo tee /etc/sddm.conf <<EOF
[Theme]
Current=breeze
EOF
fi

if [[ $neaten == "yes" ]]; then
  sed -i '/plugin=org.kde.plasma.icontasks/{
s/.*/plugin=org.kde.plasma.icontasks/;
a\
[Containments][25][Applets][28][Configuration][General];
a\
launchers=
}' ~/.config/plasma-org.kde.plasma.desktop-appletsrc
  killall plasmashell && kstart5 plasmashell &
fi

echo "=> CLEAN UP"
sudo apt autoremove -yq
rm -rf $DOWNLOAD_PATH

# clear

echo "*****************************************************"
echo "Complete, please logout/reboot to see flatpaks"
echo "*****************************************************"