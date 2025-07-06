variable "ssh_authorized_keys" {
  description = "SSH public key for instances. For example: ssh-rsa AAEAAAA....3R ssh-key-2024-09-03"
  type        = string
}

variable "compartment_id" {
  description = "The OCID of the compartment. Find it: Profile → Tenancy: youruser → Tenancy information → OCID https://cloud.oracle.com/tenancy"
  type        = string
}

variable "source_image_id" {
  description = "Source Ubuntu 22.04 image OCID. Find the right one for your region: https://docs.oracle.com/en-us/iaas/images/image/128dbc42-65a9-4ed0-a2db-be7aa584c726/index.htm"
  type        = string
}

variable "availability_domain_main" {
  description = "Availability domain for homedock-main instance. Find it Core Infrastructure → Compute → Instances → Availability domain (left menu). For example: WBJv:EU-FRANKFURT-1-AD-1"
  type        = string
}

variable "instance_shape" {
  description = "The shape of the instance. VM.Standard.A1.Flex is free tier eligible."
  type        = string
  default     = "VM.Standard.A1.Flex" # OCI Free
}

variable "memory_in_gbs" {
  description = "Memory in GBs for instance shape config. OCI Free Tier provides 24 GB RAM total across all VM.Standard.A1.Flex instances. You can allocate this however you like - e.g., one big instance with all 24 GB, or multiple VMs like 2×(12 GB), 3×(8 GB), 4×(6 GB each), etc. - as long as the sum across all A1 Flex instances stays within 24 GB RAM."
  type        = string
  default     = "24" # OCI Free
}

variable "ocpus" {
  description = "OCPUs for instance shape config. OCI Free Tier provides 4 OCPUs total across all VM.Standard.A1.Flex instances. You can allocate this however you like - e.g., one big instance with all 4 OCPUs, or multiple VMs like 2×(2 OCPUs), 3×(1+1+2), 4×(1 OCPU each), etc. - as long as the sum across all A1 Flex instances stays within 4 OCPUs."
  type        = string
  default     = "4" # OCI Free
}
