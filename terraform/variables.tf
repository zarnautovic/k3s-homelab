
variable "proxmox_token_id" {
  description = "Proxmox login token id"
  type        = string
}
variable "proxmox_token_secret" {
  description = "Proxmox API token secret"
  type        = string
  sensitive   = true
}
variable "proxmox_host" {
  description = "Proxmox API host URL (e.g. https://192.168.1.0:8006/api2/json)"
}
variable "ssh_key_file" {
  description = "Path to your SSH public key file"
  default     = "/home/zlaya/.ssh/id_rsa.pub"
}
variable "storage_name" {
  description = "Promox storage where VM will be created"
  type        = string
  default     = "local-zfs"
}
variable "bridge" {
  description = "Bridge name"
  type        = string
  default     = "vmbr0"
}
variable "cores" {
  description = "Number of cpu cores for VM"
  type        = number
  default     = 2
}
variable "memory" {
  description = "RAM memory size for VM"
  type        = number
  default     = 4096 # MB
}
variable "disk_size" {
  description = "Disk size for VM"
  type        = string
  default     = "25G"
}
variable "ci_user" {
  description = "Ubuntu username"
  type        = string
  default     = "ubuntu"
}
