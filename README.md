# Homelab

Scripts and files to automate the configuration of my personal homelab.

Uses RHEL 9.1 as the host OS and Fedora CoreOS as the guest OS for the Kubernetes nodes.

## Usage

1. Run the install script
```bash
$ bash install.sh
```

2. Run terraform apply
```bash
$ cd terraform/control
$ terraform apply
```
```bash
$ cd terraform/workers
$ terraform apply
```