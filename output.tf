output "homedock_dashboard" {
  value = "http://${oci_core_instance.homedock_main.public_ip}"
}

output "homedock_auth" {
  value = "Username: user | Password: passwd"
}

output "homedock_note" {
  value = "Note: Wait 5-10 minutes for HomeDock installation to complete before accessing."
}
