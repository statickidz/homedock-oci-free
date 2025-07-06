output "homedock_dashboard" {
  value = "http://${oci_core_instance.homedock_main.public_ip}:3000/ (wait 3-5 minutes to finish HomeDock installation)"
}

output "homedock_worker_ips" {
  value = [for instance in oci_core_instance.homedock_worker : "${instance.public_ip} (use it to add the server in HomeDock Dashboard)"]
}
