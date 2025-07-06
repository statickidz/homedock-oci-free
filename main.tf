# Main instance
resource "oci_core_instance" "homedock_main" {
  display_name        = "homedock-main-${random_string.resource_code.result}"
  compartment_id      = var.compartment_id
  availability_domain = var.availability_domain_main

  is_pv_encryption_in_transit_enabled = local.instance_config.is_pv_encryption_in_transit_enabled
  shape                               = local.instance_config.shape

  metadata = {
    ssh_authorized_keys = local.instance_config.ssh_authorized_keys
    user_data           = base64encode(file("./bin/homedock-main.sh"))
  }

  create_vnic_details {
    display_name              = "homedock-main-${random_string.resource_code.result}"
    subnet_id                 = oci_core_subnet.homedock_subnet.id
    assign_ipv6ip             = false
    assign_private_dns_record = true
    assign_public_ip          = true
  }

  availability_config {
    recovery_action = local.instance_config.availability_config.recovery_action
  }

  instance_options {
    are_legacy_imds_endpoints_disabled = local.instance_config.instance_options.are_legacy_imds_endpoints_disabled
  }

  shape_config {
    memory_in_gbs = local.instance_config.shape_config.memory_in_gbs
    ocpus         = local.instance_config.shape_config.ocpus
  }

  source_details {
    source_id   = local.instance_config.source_details.source_id
    source_type = local.instance_config.source_details.source_type
  }

  agent_config {
    is_management_disabled = "false"
    is_monitoring_disabled = "false"
    plugins_config {
      desired_state = "DISABLED"
      name          = "Vulnerability Scanning"
    }
    plugins_config {
      desired_state = "DISABLED"
      name          = "Management Agent"
    }
    plugins_config {
      desired_state = "ENABLED"
      name          = "Custom Logs Monitoring"
    }
    plugins_config {
      desired_state = "DISABLED"
      name          = "Compute RDMA GPU Monitoring"
    }
    plugins_config {
      desired_state = "ENABLED"
      name          = "Compute Instance Monitoring"
    }
    plugins_config {
      desired_state = "DISABLED"
      name          = "Compute HPC RDMA Auto-Configuration"
    }
    plugins_config {
      desired_state = "DISABLED"
      name          = "Compute HPC RDMA Authentication"
    }
    plugins_config {
      desired_state = "ENABLED"
      name          = "Cloud Guard Workload Protection"
    }
    plugins_config {
      desired_state = "DISABLED"
      name          = "Block Volume Management"
    }
    plugins_config {
      desired_state = "DISABLED"
      name          = "Bastion"
    }
  }
}
