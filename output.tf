output "homedock_dashboard_url" {
  value = "http://${oci_core_instance.homedock_main.public_ip}"
}

output "homedock_credentials" {
  value = "Username: user | Password: passwd (change it after first login)"
}

output "homedock_note" {
  value = "Note: Wait 5-10 minutes for HomeDock installation to complete before accessing."
}
