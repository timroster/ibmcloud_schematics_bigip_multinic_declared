##################################################################################
# region - The VPC region to instatiate the F5 BIG-IP instance
##################################################################################
variable "region" {
  type        = string
  default     = "us-south"
  description = "The VPC region to instatiate the F5 BIG-IP instance"
}
# Present for CLI testng
#variable "api_key" {
#  type        = string
#  default     = ""
#  description = "IBM Public Cloud API KEY"
#}

##################################################################################
# resource_group - The IBM Cloud resource group to create the F5 BIG-IP instance
##################################################################################
variable "resource_group" {
  type        = string
  default     = "default"
  description = "The IBM Cloud resource group to create the F5 BIG-IP instance"
}

##################################################################################
# instance_name - The name of the F5 BIG-IP instance
##################################################################################
variable "instance_name" {
  type        = string
  default     = "f5-ve-01"
  description = "The VPC Instance name"
}

##################################################################################
# hostname - The hostname of the F5 BIG-IP instance
##################################################################################
variable "hostname" {
  type        = string
  default     = "f5-ve-01"
  description = "The F5 BIG-IP hostname"
}

##################################################################################
# domain - The domain name of the F5 BIG-IP instance
##################################################################################
variable "domain" {
  type        = string
  default     = "local"
  description = "The F5 BIG-IP domain name"
}

##################################################################################
# tmos_image_name - The name of VPC image to use for the F5 BIG-IP instnace
##################################################################################
variable "tmos_image_name" {
  type        = string
  default     = "bigip-15-1-2-0-0-9-all-1slot"
  description = "The image to be used when provisioning the F5 BIG-IP instance"
}

##################################################################################
# instance_profile - The name of the VPC profile to use for the F5 BIG-IP instnace
##################################################################################
variable "instance_profile" {
  type        = string
  default     = "cx2-2x4"
  description = "The resource profile to be used when provisioning the F5 BIG-IP instance"
}

##################################################################################
# ssh_key_name - The name of the public SSH key to be used when provisining F5 BIG-IP
##################################################################################
variable "ssh_key_name" {
  type        = string
  default     = ""
  description = "The name of the public SSH key (VPC Gen 2 SSH Key) to be used when provisioning the F5 BIG-IP instance"
}

##################################################################################
# tmos_admin_password - The password for the built-in admin F5 BIG-IP user
##################################################################################
variable "tmos_admin_password" {
  type        = string
  default     = ""
  description = "admin account password for the F5 BIG-IP instance"
}

##################################################################################
# management_subnet_id - The VPC subnet ID for the F5 BIG-IP management interface
##################################################################################
variable "management_subnet_id" {
  type        = string
  default     = null
  description = "Required VPC Gen2 subnet ID for the F5 BIG-IP management network"
}

##################################################################################
# cluster_subnet_id - The VPC subnet ID for the F5 BIG-IP configsync interface
##################################################################################
variable "cluster_subnet_id" {
  type        = string
  default     = ""
  description = "Optional VPC Gen2 subnet ID for the F5 BIG-IP configsync activities"
}

##################################################################################
# internal_subnet_id - The VPC subnet ID for the F5 BIG-IP internal resources
##################################################################################
variable "internal_subnet_id" {
  type        = string
  default     = ""
  description = "Optional VPC Gen2 subnet ID for the F5 BIG-IP access to internal resources"
}

##################################################################################
# external_subnet_id - The VPC subnet ID for the F5 BIG-IP virtual service listeners
##################################################################################
variable "external_subnet_id" {
  type        = string
  default     = ""
  description = "Required VPC Gen2 subnet ID for the F5 BIG-IP virtual service listeners"
}

##################################################################################
# default_route_interface - The F5 BIG-IP interface name for the default route
##################################################################################
variable "default_route_interface" {
  type        = string
  default     = ""
  description = "The F5 BIG-IP interface name for the default route. Leave blank to auto assign."
}


##################################################################################
# A&O Declaration Sources
##################################################################################
variable "do_declaration_url" {
  type        = string
  default     = "none"
  description = "URL to fetch the f5-declarative-onboarding declaration"
}
variable "as3_declaration_url" {
  type        = string
  default     = "none"
  description = "URL to fetch the f5-appsvcs-extension declaration"
}
variable "ts_declaration_url" {
  type        = string
  default     = "none"
  description = "URL to fetch the f5-telemetry-streaming declaration"
}

##################################################################################
# phone_home_url - The web hook URL to POST status to when F5 BIG-IP onboarding completes
##################################################################################
variable "phone_home_url" {
  type        = string
  default     = ""
  description = "The URL to POST status when BIG-IP is finished onboarding"
}

##################################################################################
# schematic template for phone_home_url_metadata
##################################################################################
variable "template_source" {
  default     = "f5devcentral/ibmcloud_schematics_bigip_multinic_declared"
  description = "The terraform template source for phone_home_url_metadata"
}
variable "template_version" {
  default     = "20210201"
  description = "The terraform template version for phone_home_url_metadata"
}
variable "app_id" {
  default     = "undefined"
  description = "The terraform application id for phone_home_url_metadata"
}

##################################################################################
# tgactive_url - The web hook URL to POST defined L3 addresses when tgactive is triggered
##################################################################################
variable "tgactive_url" {
  type        = string
  default     = ""
  description = "The URL to POST L3 addresses when tgactive is triggered"
}

##################################################################################
# tgstandby_url - The web hook URL to POST defined L3 addresses when tgstandby is triggered
##################################################################################
variable "tgstandby_url" {
  type        = string
  default     = ""
  description = "The URL to POST L3 addresses when tgstandby is triggered"
}

##################################################################################
# tgrefresh_url - The web hook URL to POST defined L3 addresses when tgrefresh is triggered
##################################################################################
variable "tgrefresh_url" {
  type        = string
  default     = ""
  description = "The URL to POST L3 addresses when tgrefresh is triggered"
}