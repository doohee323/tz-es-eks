//data "template_file" "es-eks-bastion-init" {
//  template = file("../../scripts/es-eks-bastion-init.sh")
//  vars = {
//    DEVICE            = var.INSTANCE_DEVICE_NAME
//  }
//}
//
//data "template_cloudinit_config" "es-eks-bastion-cloudinit" {
//  gzip          = false
//  base64_encode = false
//
//  part {
//    content_type = "text/x-shellscript"
//    content      = data.template_file.es-eks-bastion-init.rendered
//  }
//}
//
