# Homelab

Scripts and files to automate the configuration of my personal homelab.

Uses RHEL 9.1 as the host OS and Fedora CoreOS 37 as the guest OS for the Kubernetes nodes.

## Usage

Ensure whichever user you're running as is a member of the "libvirt" group!

Clone the repository:
```bash
git clone https://github.com/WadeMason/homelab.git
```
Install ansible and the required collections:
```bash
sudo dnf install -y ansible-core
ansible-galaxy collection install -r requirements.yml
```
After that, just run:
```bash
ansible-playbook main.yml -K
```

## Notes

Systems are configured with the following resources:
| Name | Role | vCPU | RAM |
|--|--|--|--|
| kube-control | control-plane | 8 | 8GB |
| kube-worker1 | worker | 8 | 16GB |
| kube-worker2 | worker | 8 | 16GB |