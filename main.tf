locals {
  is_t_instance_type = replace(var.instance_type, "/^t[23]{1}\\..*$/", "1") == "1" ? "1" : "0"

  ncount             = length(var.names)
  icount             = local.ncount > 0 ? local.ncount : var.instance_count
  ucount             = length(var.user_data_list)
  use_num_suffix     = local.ncount > 0 ? false : var.use_num_suffix

  instance_count     = local.icount * (1 - local.is_t_instance_type)
  t_instance_count   = local.icount * local.is_t_instance_type
}

######
# Note: network_interface can't be specified together with associate_public_ip_address
######
resource "aws_instance" "this" {
  count = local.instance_count > 0 ? local.instance_count : 0

  ami           = var.ami
  instance_type = var.instance_type
  user_data     = local.ucount > 0 ? element(var.user_data_list, count.index) : var.user_data
  subnet_id     = element(
    distinct(compact(concat([var.subnet_id], var.subnet_ids))),
    count.index,
  )
  key_name               = var.key_name
  monitoring             = var.monitoring
  vpc_security_group_ids = var.vpc_security_group_ids
  iam_instance_profile   = var.iam_instance_profile

  associate_public_ip_address = var.associate_public_ip_address
  private_ip                  = var.private_ip
  ipv6_address_count          = var.ipv6_address_count
  ipv6_addresses              = var.ipv6_addresses

  ebs_optimized = var.ebs_optimized

  dynamic "root_block_device" {
    for_each = var.root_block_device
    content {
      delete_on_termination = lookup(root_block_device.value, "delete_on_termination", null)
      iops                  = lookup(root_block_device.value, "iops", null)
      volume_size           = lookup(root_block_device.value, "volume_size", null)
      volume_type           = lookup(root_block_device.value, "volume_type", null)
    }
  }

  dynamic "ebs_block_device" {
    for_each = var.ebs_block_device
    content {
      delete_on_termination = lookup(ebs_block_device.value, "delete_on_termination", null)
      device_name           = ebs_block_device.value.device_name
      encrypted             = lookup(ebs_block_device.value, "encrypted", null)
      iops                  = lookup(ebs_block_device.value, "iops", null)
      snapshot_id           = lookup(ebs_block_device.value, "snapshot_id", null)
      volume_size           = lookup(ebs_block_device.value, "volume_size", null)
      volume_type           = lookup(ebs_block_device.value, "volume_type", null)
    }
  }

  dynamic "ephemeral_block_device" {
    for_each = var.ephemeral_block_device
    content {
      device_name  = ephemeral_block_device.value.device_name
      no_device    = lookup(ephemeral_block_device.value, "no_device", null)
      virtual_name = lookup(ephemeral_block_device.value, "virtual_name", null)
    }
  }

  source_dest_check                    = var.source_dest_check
  disable_api_termination              = var.disable_api_termination
  instance_initiated_shutdown_behavior = var.instance_initiated_shutdown_behavior
  placement_group                      = var.placement_group
  tenancy                              = var.tenancy

  tags = merge(
    {
      "Name" = local.ncount > 0 ? element(var.names, count.index) : local.instance_count > 1 || local.use_num_suffix ? format("%s-%d", var.name, count.index + 1) : var.name
    },
    var.tags,
  )

  volume_tags = merge(
    {
      "Name" = local.ncount > 0 ? element(var.names, count.index) : local.instance_count > 1 || local.use_num_suffix ? format("%s-%d", var.name, count.index + 1) : var.name
    },
    var.volume_tags,
  )

  lifecycle {
    # Due to several known issues in Terraform AWS provider related to arguments of aws_instance:
    # (eg, https://github.com/terraform-providers/terraform-provider-aws/issues/2036)
    # we have to ignore changes in the following arguments
    ignore_changes = [
      private_ip,
      root_block_device,
      ebs_block_device,
    ]
  }
}

resource "aws_instance" "this_t2" {
  count = local.t_instance_count > 0 ? local.t_instance_count : 0

  ami           = var.ami
  instance_type = var.instance_type
  user_data     = local.ucount > 0 ? element(var.user_data_list, count.index) : var.user_data
  subnet_id = element(
    distinct(compact(concat([var.subnet_id], var.subnet_ids))),
    count.index,
  )
  key_name               = var.key_name
  monitoring             = var.monitoring
  vpc_security_group_ids = var.vpc_security_group_ids
  iam_instance_profile   = var.iam_instance_profile

  associate_public_ip_address = var.associate_public_ip_address
  private_ip                  = var.private_ip
  ipv6_address_count          = var.ipv6_address_count
  ipv6_addresses              = var.ipv6_addresses

  ebs_optimized = var.ebs_optimized

  dynamic "root_block_device" {
    for_each = var.root_block_device
    content {
      delete_on_termination = lookup(root_block_device.value, "delete_on_termination", null)
      iops                  = lookup(root_block_device.value, "iops", null)
      volume_size           = lookup(root_block_device.value, "volume_size", null)
      volume_type           = lookup(root_block_device.value, "volume_type", null)
    }
  }

  dynamic "ebs_block_device" {
    for_each = var.ebs_block_device
    content {
      delete_on_termination = lookup(ebs_block_device.value, "delete_on_termination", null)
      device_name           = ebs_block_device.value.device_name
      encrypted             = lookup(ebs_block_device.value, "encrypted", null)
      iops                  = lookup(ebs_block_device.value, "iops", null)
      snapshot_id           = lookup(ebs_block_device.value, "snapshot_id", null)
      volume_size           = lookup(ebs_block_device.value, "volume_size", null)
      volume_type           = lookup(ebs_block_device.value, "volume_type", null)
    }
  }

  dynamic "ephemeral_block_device" {
    for_each = var.ephemeral_block_device
    content {
      device_name  = ephemeral_block_device.value.device_name
      no_device    = lookup(ephemeral_block_device.value, "no_device", null)
      virtual_name = lookup(ephemeral_block_device.value, "virtual_name", null)
    }
  }

  source_dest_check                    = var.source_dest_check
  disable_api_termination              = var.disable_api_termination
  instance_initiated_shutdown_behavior = var.instance_initiated_shutdown_behavior
  placement_group                      = var.placement_group
  tenancy                              = var.tenancy

  credit_specification {
    cpu_credits = var.cpu_credits
  }

  tags = merge(
    {
      "Name" = local.ncount > 0 ? element(var.names, count.index) : local.t_instance_count > 1 || local.use_num_suffix ? format("%s-%d", var.name, count.index + 1) : var.name
    },
    var.tags,
  )

  volume_tags = merge(
    {
      "Name" = local.ncount > 0 ? element(var.names, count.index) : local.t_instance_count > 1 || local.use_num_suffix ? format("%s-%d", var.name, count.index + 1) : var.name
    },
    var.volume_tags,
  )

  lifecycle {
    # Due to several known issues in Terraform AWS provider related to arguments of aws_instance:
    # (eg, https://github.com/terraform-providers/terraform-provider-aws/issues/2036)
    # we have to ignore changes in the following arguments
    ignore_changes = [
      private_ip,
      root_block_device,
      ebs_block_device,
    ]
  }
}

