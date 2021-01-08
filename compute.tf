# lookup SSH public keys by name
data "ibm_is_ssh_key" "ssh_pub_key" {
  name = var.ssh_key_name
}

# lookup compute profile by name
data "ibm_is_instance_profile" "instance_profile" {
  name = var.instance_profile
}

# create a random password if we need it
resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

# lookup image name for a custom image in region if we need it
data "ibm_is_image" "tmos_custom_image" {
  name = var.tmos_image_name
}

locals {
  # use the public image if the name is found
  public_image_map = {
    bigip-14-1-2-6-0-0-2-all-1slot = {
      "us-south" = "r006-f0a8cba9-1e9e-4771-87ba-20b7fd33b16a"
      "us-east"  = "r014-eccb5c62-82d9-438c-b81e-716f3506700f"
      "eu-gb"    = "r018-72ee97b8-ffeb-4427-bd2a-fc60e4d2b6b5"
      "eu-de"    = "r010-cf56a548-d5ca-4833-b0a6-bde256140d93"
      "jp-tok"   = "r022-44656c7d-427c-4e06-9253-3224cd1df827"
    }
    bigip-14-1-2-6-0-0-2-ltm-1slot = {
      "us-south" = "r006-1ca34358-b1f0-44b1-bf9a-a8bd9837a672"
      "us-east"  = "r014-3c86e0bf-1026-4400-91f6-b4256d972ed5"
      "eu-gb"    = "r018-e717281f-5bd7-4e08-8d54-7b45ddfb12c7"
      "eu-de"    = "r010-e8022107-fea9-471b-ba6c-8b8f8e130ab9"
      "jp-tok"   = "r022-c7377896-c997-495a-88f7-033f827d6d8b"
    }
    bigip-15-1-0-4-0-0-6-all-1slot = {
      "us-south" = "r006-654bca9e-8e4d-46c2-980b-c52fdd2237f4"
      "us-east"  = "r014-d73926e1-3b82-413f-aecc-36710b59cf4b"
      "eu-gb"    = "r018-e02a17f1-90bc-494b-ab66-4f3e03c08b7d"
      "eu-de"    = "r010-3a06e044-56e8-4d45-a5c2-535a7b673a94"
      "jp-tok"   = "r022-a65002eb-ad05-4d56-bcb8-2d3fa14f9834"
    }
    bigip-15-1-0-4-0-0-6-ltm-1slot = {
      "us-south" = "r006-c176a319-39e3-4f24-82a1-6dd4f2fa58dc"
      "us-east"  = "r014-e2a4cc82-d935-4f3f-9042-21f64d18232c"
      "eu-gb"    = "r018-859e47fb-40db-4d72-9da7-2de4fc78d64c"
      "eu-de"    = "r010-cd996cda-53ce-4783-9e3a-03a18b9162ff"
      "jp-tok"   = "r022-36b57097-deba-49c2-bffb-f37c61c8e713"
    }
  }
}

locals {
  # custom image takes priority over public image
  image_id = data.ibm_is_image.tmos_custom_image.id == null ? lookup(local.public_image_map[var.tmos_image_name], var.region) : data.ibm_is_image.tmos_custom_image.id
  # public image takes priority over custom image
  # image_id = lookup(lookup(local.public_image_map, var.tmos_image_name, {}), var.region, data.ibm_is_image.tmos_custom_image.id)
  template_file = file("${path.module}/user_data.yaml")
  # user admin_password if supplied, else set a random password
  admin_password = var.tmos_admin_password == "" ? random_password.password.result : var.tmos_admin_password
  # set user_data YAML values or else set them to null for templating
  do_declaration_url      = var.do_declaration_url == "" ? "null" : var.do_declaration_url
  as3_declaration_url     = var.as3_declaration_url == "" ? "null" : var.as3_declaration_url
  ts_declaration_url      = var.ts_declaration_url == "" ? "null" : var.ts_declaration_url
  phone_home_url          = var.phone_home_url == "" ? "null" : var.phone_home_url
  # default_route_interface
  default_route_interface = var.default_route_interface == "" ? "1.${length(local.secondary_subnets)}" : var.default_route_interface
}

# discovery the 1st address on the default route subnet because IBM does not
# supply the DHCPv4 routers option correctly on non-primary interfaces. This
# is a bug in IBM they need to fix.
data "ibm_is_subnet" "default_route_subnet" {
  identifier = element(local.secondary_subnets, length(local.secondary_subnets) - 1)
}
# IBM does not tell you what the default gateway address for each subnet should
# be, but by undocumented convention we will use the 1st host address in the subnet
locals {
  default_gateway_ipv4_address = cidrhost(data.ibm_is_subnet.default_route_subnet.ipv4_cidr_block, 1)
}

data "template_file" "user_data" {
  template = local.template_file
  vars = {
    tmos_admin_password     = local.admin_password
    configsync_interface    = "1.1"
    default_route_interface = local.default_route_interface
    default_route_gateway   = local.default_gateway_ipv4_address
    do_declaration_url      = local.do_declaration_url
    as3_declaration_url     = local.as3_declaration_url
    ts_declaration_url      = local.ts_declaration_url
    phone_home_url          = local.phone_home_url
    template_source         = var.template_source
    template_version        = var.template_version
    zone                    = data.ibm_is_subnet.f5_managment_subnet.zone
    vpc                     = data.ibm_is_subnet.f5_managment_subnet.vpc
    app_id                  = var.app_id
  }
}

# create compute instance
resource "ibm_is_instance" "f5_ve_instance" {
  name    = var.instance_name
  resource_group = data.ibm_resource_group.group.id
  image   = local.image_id
  profile = data.ibm_is_instance_profile.instance_profile.id
  primary_network_interface {
    name            = "management"
    subnet          = data.ibm_is_subnet.f5_managment_subnet.id
    security_groups = [ibm_is_security_group.f5_open_sg.id]
  }
  dynamic "network_interfaces" {
    for_each = local.secondary_subnets
    content {
      name              = format("data-1-%d", (network_interfaces.key + 1))
      subnet            = network_interfaces.value
      security_groups   = [ibm_is_security_group.f5_open_sg.id]
      allow_ip_spoofing = true
    }
  }
  vpc        = data.ibm_is_subnet.f5_managment_subnet.vpc
  zone       = data.ibm_is_subnet.f5_managment_subnet.zone
  keys       = [data.ibm_is_ssh_key.ssh_pub_key.id]
  user_data  = data.template_file.user_data.rendered
  depends_on = [ibm_is_security_group_rule.f5_allow_outbound]
  timeouts {
    create = "60m"
    delete = "120m"
  }
}

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

locals {
  vs_interface_index = length(ibm_is_instance.f5_ve_instance.network_interfaces) - 1
  snat_interface_index = length(ibm_is_instance.f5_ve_instance.network_interfaces) < 3 ? 0 : 2
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
