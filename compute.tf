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
    bigip-14-1-3-1-0-0-8-all-1slot = {
      "us-south" = "r006-8720abba-4136-4779-a78e-e00e46f3b8f2"
      "us-east"  = "r014-293302bd-7dfa-4e56-9f82-589eb3f24a85"
      "eu-gb"    = "r018-a0410a8f-8241-440b-b96f-68a047f27831"
      "eu-de"    = "r010-fbf0aba2-59bf-4e86-bdee-131381cf392d"
      "jp-tok"   = "r022-22f5bfb3-e3ac-49b4-9cba-42f624891430"
      "au-syd"   = "r026-0b8d935e-3e26-49c7-93d2-b60fbd932cf0"
      "jp-osa"   = "r034-b068a948-8433-484f-9027-a304606c2dea"
    }
    bigip-14-1-3-1-0-0-8-ltm-1slot = {
      "us-south" = "r006-32b0ee63-b829-4ebe-891e-57152cfbd837"
      "us-east"  = "r014-798c713d-3bd1-44a9-a3e9-3803c989993f"
      "eu-gb"    = "r018-fbfba240-2265-4876-a17a-eeb48e52b04e"
      "eu-de"    = "r010-cd558f0a-ce44-44a3-940a-3c59fd5ab0e3"
      "jp-tok"   = "r022-c9fc7522-374e-4022-b888-03791ad6dba2"
      "au-syd"   = "r026-ba149ee1-6017-4424-b2ea-a13760b0ef08"
      "jp-osa"   = "r034-db9d9da3-385f-465a-98d8-3ac450703137"
    }
    bigip-15-1-2-0-0-9-all-1slot = {
      "us-south" = "r006-909f060a-151c-46dc-a7c9-8b590a8a557a"
      "us-east"  = "r014-ca6bafde-c07f-4ec8-8a7a-612ac7780381"
      "eu-gb"    = "r018-27ea929e-27e5-4f21-b399-86b229079945"
      "eu-de"    = "r010-416fe422-531a-4ba0-90ad-a7411f76f0d2"
      "jp-tok"   = "r022-6e54d1f4-140f-4e3a-b806-dda5a67f21dd"
      "au-syd"   = "r026-11959b79-eee1-4516-bb46-ce6a99c1844d"
      "jp-osa"   = "r034-39fb95e9-ca0a-46ec-b8b0-0c90f6bde6d0"
    }
    bigip-15-1-2-0-0-9-ltm-1slot = {
      "us-south" = "r006-954b3370-9758-4927-b1d0-34bc03ab32d7"
      "us-east"  = "r014-f42d01fe-7200-495c-8029-e4a883304af2"
      "eu-gb"    = "r018-f60082e9-27d5-46ef-982d-5df5601ae535"
      "eu-de"    = "r010-a640c1fa-0973-4885-bb8e-0e140a5d7c69"
      "jp-tok"   = "r022-b1f55cd8-793a-4584-b51c-02d65d905e5e"
      "au-syd"   = "r026-05ea0522-e099-4954-a91b-7067be45d4f9"
      "jp-osa"   = "r034-1468eddc-2f24-4a43-bb9e-949ce2fa6615"
    }
  }
}

locals {
  do_byol_license = <<EOD

    schemaVersion: 1.0.0
    class: Device
    async: true
    label: Cloudinit Onboarding
    Common:
      class: Tenant
      byoLicense:
        class: License
        licenseType: regKey
        regKey: ${var.byol_license_basekey}
EOD
  do_regekypool = <<EOD

    schemaVersion: 1.0.0
    class: Device
    async: true
    label: Cloudinit Onboarding
    Common:
      class: Tenant
      poolLicense:
        class: License
        licenseType: licensePool
        bigIqHost: ${var.license_host}
        bigIqUsername: ${var.license_username}
        bigIqPassword: ${var.license_password}
        licensePool: ${var.license_pool}
        reachable: false
        hypervisor: kvm
EOD
  do_utilitypool = <<EOD

    schemaVersion: 1.0.0
    class: Device
    async: true
    label: Cloudinit Onboarding
    Common:
      class: Tenant
      utilityLicense:
        class: License
        licenseType: licensePool
        bigIqHost: ${var.license_host}
        bigIqUsername: ${var.license_username}
        bigIqPassword: ${var.license_password}
        licensePool: ${var.license_pool}
        skuKeyword1: ${var.license_sku_keyword_1}
        skuKeyword2: ${var.license_sku_keyword_2}
        unitOfMeasure: ${var.license_unit_of_measure}
        reachable: false
        hypervisor: kvm
EOD
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
  do_declaration_url   = var.do_declaration_url == "" ? "null" : var.do_declaration_url
  as3_declaration_url  = var.as3_declaration_url == "" ? "null" : var.as3_declaration_url
  ts_declaration_url   = var.ts_declaration_url == "" ? "null" : var.ts_declaration_url
  phone_home_url       = var.phone_home_url == "" ? "null" : var.phone_home_url
  tgactive_url         = var.tgactive_url == "" ? "null" : var.tgactive_url
  tgstandby_url        = var.tgstandby_url == "" ? "null" : var.tgstandby_url
  tgrefresh_url        = var.tgrefresh_url == "" ? "null" : var.tgrefresh_url
  do_dec1              = var.license_type == "byol" ? chomp(local.do_byol_license): "null"
  do_dec2              = var.license_type == "regkeypool" ? chomp(local.do_regekypool): local.do_dec1
  do_local_declaration = var.license_type == "utilitypool" ? chomp(local.do_utilitypool): local.do_dec2 
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
    hostname                = var.hostname
    domain                  = var.domain
    default_route_interface = local.default_route_interface
    default_route_gateway   = local.default_gateway_ipv4_address
    do_local_declaration    = local.do_local_declaration
    do_declaration_url      = local.do_declaration_url
    as3_declaration_url     = local.as3_declaration_url
    ts_declaration_url      = local.ts_declaration_url
    phone_home_url          = local.phone_home_url
    tgactive_url            = local.tgactive_url
    tgstandby_url           = local.tgstandby_url
    tgrefresh_url           = local.tgrefresh_url
    template_source         = var.template_source
    template_version        = var.template_version
    zone                    = data.ibm_is_subnet.f5_management_subnet.zone
    vpc                     = data.ibm_is_subnet.f5_management_subnet.vpc
    app_id                  = var.app_id
  }
}

# create compute instance
resource "ibm_is_instance" "f5_ve_instance" {
  name           = var.instance_name
  resource_group = data.ibm_resource_group.group.id
  image          = local.image_id
  profile        = data.ibm_is_instance_profile.instance_profile.id
  primary_network_interface {
    name            = "management"
    subnet          = data.ibm_is_subnet.f5_management_subnet.id
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
  vpc        = data.ibm_is_subnet.f5_management_subnet.vpc
  zone       = data.ibm_is_subnet.f5_management_subnet.zone
  keys       = [data.ibm_is_ssh_key.ssh_pub_key.id]
  user_data  = data.template_file.user_data.rendered
  depends_on = [ibm_is_security_group_rule.f5_allow_outbound]
  timeouts {
    create = "60m"
    delete = "120m"
  }
}

locals {
  vs_interface_index   = length(ibm_is_instance.f5_ve_instance.network_interfaces) - 1
  snat_interface_index = length(ibm_is_instance.f5_ve_instance.network_interfaces) < 3 ? 0 : 1
}

resource "ibm_is_floating_ip" "f5_management_floating_ip" {
  name           = "fmgmt-${random_uuid.namer.result}"
  resource_group = data.ibm_resource_group.group.id
  count          = var.bigip_management_floating_ip ? 1 : 0
  target         = ibm_is_instance.f5_ve_instance.primary_network_interface.0.id
}

resource "ibm_is_floating_ip" "f5_external_floating_ip" {
  name           = "fext-${random_uuid.namer.result}"
  resource_group = data.ibm_resource_group.group.id
  count          = local.external_floating_ip ? 1 : 0
  target         = element(ibm_is_instance.f5_ve_instance.network_interfaces.*.id, local.vs_interface_index)
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
