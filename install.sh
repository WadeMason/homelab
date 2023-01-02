echo 'Install required packages ...'
dnf config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
dnf install -y terraform ansible-core libvirt tmux

echo 'Configuring tmux to run on new bash sessions ...'
if ! grep -q '[ -n "$PS1" -a -z "$TMUX" ] && exec tmux' /etc/bashrc ; then
    echo '[ -n "$PS1" -a -z "$TMUX" ] && exec tmux' >> /etc/bashrc
fi

#echo 'Intalling playbook requirements ...'
#ansible-galaxy install -r requirements.yml

read -p "Do you want to generate an ssh keypair now? (y/n) " -n 1 -r
echo 
if [[ $REPLY =~ ^[Yy]$ ]]
then
    ssh-keygen
fi