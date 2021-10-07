output "resource_name" {
  value = ibm_is_instance.f5_ve_instance.name
}

output "resource_status" {
  value = ibm_is_instance.f5_ve_instance.status
}

output "VPC" {
  value = ibm_is_instance.f5_ve_instance.vpc
}

output "image_id" {
  value = local.image_id
}

output "instance_id" {
  value = ibm_is_instance.f5_ve_instance.id
}

output "profile_id" {
  value = data.ibm_is_instance_profile.instance_profile.id
}

output "f5_management_ip" {
  value = ibm_is_instance.f5_ve_instance.primary_network_interface.0.primary_ipv4_address
}

output "f5_cluster_ip" {
  value = var.cluster_subnet_id == "" ? "" : ibm_is_instance.f5_ve_instance.network_interfaces.0.primary_ipv4_address
}

output "f5_internal_ip" {
  value = var.internal_subnet_id == "" ? "" : element(ibm_is_instance.f5_ve_instance.network_interfaces, local.snat_interface_index).primary_ipv4_address
}

output "f5_external_ip" {
  value = var.external_subnet_id == "" ? "" : element(ibm_is_instance.f5_ve_instance.network_interfaces, local.vs_interface_index).primary_ipv4_address
}

output "default_gateway" {
  value = local.default_gateway_ipv4_address
}

output "virtual_service_next_hop_address" {
  value = element(ibm_is_instance.f5_ve_instance.network_interfaces, local.vs_interface_index).primary_ipv4_address
}

output "snat_next_hop_address" {
  value = element(ibm_is_instance.f5_ve_instance.network_interfaces, local.snat_interface_index).primary_ipv4_address
}

output "f5_management_floating_ip" {
  value = var.bigip_management_floating_ip ? ibm_is_floating_ip.f5_management_floating_ip[0].address : ""
}

output "f5_external_floating_ip" {
  value = local.external_floating_ip ? ibm_is_floating_ip.f5_external_floating_ip[0].address : ""
}
