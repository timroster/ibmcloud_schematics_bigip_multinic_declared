locals {
  custom_image = var.tmos_custom_image == "" ? 0 : 1
  public_image = var.tmos_custom_image == "" ? 1 : 0
  image_id     = var.tmos_custom_image == "" ? data.external.tmos_public_image.0.result.image_id : data.ibm_is_image.tmos_custom_image.0.id
}

data "ibm_is_image" "tmos_custom_image" {
  count = local.custom_image
  name  = var.tmos_custom_image
}

data "external" "tmos_public_image" {
  count   = local.public_image
  program = ["python3", "${path.module}/bigip_image_selector.py"]
  query = {
    type           = var.tmos_type
    region         = var.region
    version_prefix = var.tmos_image_name
  }
}



