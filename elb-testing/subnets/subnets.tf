data "aws_subnet_ids" "example" {
  vpc_id = "vpc-c8e2e0b2"
}

data "aws_subnet" "example" {
  for_each = data.aws_subnet_ids.example.ids
  id       = each.value

}

output "aws_subs" {
  value = [for s in data.aws_subnet.example : s.id]
}

output "subnet_cidr_blocks" {
  value = [for s in data.aws_subnet.example : s.cidr_block]
}
