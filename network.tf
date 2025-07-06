# VCN configuration
resource "oci_core_vcn" "homedock_vcn" {
  cidr_block     = "10.0.0.0/16"
  compartment_id = var.compartment_id
  display_name   = "network-homedock-${random_string.resource_code.result}"
  dns_label      = "vcn${random_string.resource_code.result}"
}

# Subnet configuration
resource "oci_core_subnet" "homedock_subnet" {
  cidr_block     = "10.0.0.0/24"
  compartment_id = var.compartment_id
  display_name   = "subnet-homedock-${random_string.resource_code.result}"
  dns_label      = "subnet${random_string.resource_code.result}"
  route_table_id = oci_core_vcn.homedock_vcn.default_route_table_id
  vcn_id         = oci_core_vcn.homedock_vcn.id

  # Attach the security list
  security_list_ids = [oci_core_security_list.homedock_security_list.id]
}

# Internet Gateway configuration
resource "oci_core_internet_gateway" "homedock_internet_gateway" {
  compartment_id = var.compartment_id
  display_name   = "Internet Gateway network-homedock"
  enabled        = true
  vcn_id         = oci_core_vcn.homedock_vcn.id
}

# Default Route Table
resource "oci_core_default_route_table" "homedock_default_route_table" {
  manage_default_resource_id = oci_core_vcn.homedock_vcn.default_route_table_id

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.homedock_internet_gateway.id
  }
}

# Security List for HomeDock
resource "oci_core_security_list" "homedock_security_list" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.homedock_vcn.id
  display_name   = "HomeDock Security List"

  # Allow all ingress traffic
  ingress_security_rules {
    protocol    = "all"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    description = "Allow all ingress traffic"
  }

  # Egress Rule (allow all outbound traffic)
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
    description = "Allow all egress traffic"
  }
}
