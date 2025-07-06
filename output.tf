output "homedock_dashboard" {
  value = <<-EOT
    HomeDock Dashboard URL: http://${oci_core_instance.homedock_main.public_ip}/
    Username: user
    Password: passwd

    Note: Wait 3-5 minutes for HomeDock installation to complete before accessing.
  EOT
}
