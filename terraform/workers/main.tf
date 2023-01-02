variable "domain" { default = "wademason.net" }
variable "os_image_name" { default = "fedora-coreos.qcow2" }

variable "libvirt_network" { default = "default" }
variable "libvirt_pool" { default = "default" }

variable "worker_count" { default = 2 }
variable "hostname" { default = "kube-worker" }
variable "memory" { default = 16 }
variable "cpu" { default = 8 }
variable "disk_size" { default = 20 }

# Terraform configuration
terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.7.1"
    }
    ignition = {
      source  = "community-terraform-providers/ignition"
      version = "2.1.3"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

# Ignition configuration
data "ignition_file" "file_hostname" {
  count     = var.worker_count
  path      = "/etc/hostname"
  overwrite = true
  content {
    content = "${var.hostname}${count.index + 1}"
  }
}

data "ignition_file" "file_module" {
  path      = "/etc/dnf/modules.d/cri-o.module"
  overwrite = true
  content {
    content = "[cri-o]\nname=cri-o\nstream=1.17\nprofiles=\nstate=enabled"
  }
}

data "ignition_file" "file_yum_repo" {
  path      = "/etc/yum.repos.d/kubernetes.repo"
  overwrite = true
  content {
    content = "[kubernetes]\nname=Kubernetes\nbaseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg\n  https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg"
  }
}

data "ignition_file" "file_br_netfilter" {
  path      = "/etc/modules-load.d/br_netfilter.conf"
  overwrite = true
  content {
    content = "br_netfilter"
  }
}

data "ignition_file" "file_sysctl" {
  path      = "/etc/sysctl.d/kubernetes.conf"
  overwrite = true
  content {
    content = "net.bridge.bridge-nf-call-iptables=1\nnet.ipv4.ip_forward=1"
  }
}

data "ignition_user" "core" {
  name = "core"
  ssh_authorized_keys = [
    file(pathexpand("~/.ssh/id_rsa.pub"))
  ]
}

data "ignition_config" "kubernetes" {
  count = var.worker_count
  files = [
    data.ignition_file.file_hostname[count.index].rendered,
    data.ignition_file.file_module.rendered,
    data.ignition_file.file_yum_repo.rendered,
    data.ignition_file.file_br_netfilter.rendered,
    data.ignition_file.file_sysctl.rendered,
  ]
  users = [
    data.ignition_user.core.rendered,
  ]
}

resource "libvirt_ignition" "ignition" {
  count   = var.worker_count
  name    = "${var.hostname}${count.index + 1}-ignition"
  content = data.ignition_config.kubernetes[count.index].rendered
}

# Operating system image
resource "libvirt_volume" "os_image" {
  count  = var.worker_count
  name   = "${var.hostname}${count.index + 1}-os_image"
  source = "/tmp/${var.os_image_name}"
  pool   = var.libvirt_pool
  format = "qcow2"
}

# Libvirt configuration
resource "libvirt_volume" "disk" {
  count          = var.worker_count
  name           = "${var.hostname}${count.index + 1}"
  pool           = var.libvirt_pool
  base_volume_id = libvirt_volume.os_image[count.index].id
  size           = var.disk_size * 1073741824
}

resource "libvirt_domain" "kube-workers" {
  count     = var.worker_count
  autostart = true
  name      = "${var.hostname}${count.index + 1}"
  memory    = var.memory * 1024
  vcpu      = var.cpu

  coreos_ignition = libvirt_ignition.ignition[count.index].id

  disk {
    volume_id = libvirt_volume.disk[count.index].id
  }

  network_interface {
    network_name = var.libvirt_network
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  graphics {
    type        = "vnc"
    listen_type = "address"
    autoport    = "true"
  }
}

output "ignition_config" {
  value = libvirt_ignition.ignition.*.content
}
