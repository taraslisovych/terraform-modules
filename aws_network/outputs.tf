output "ter_vpc_id" {
  value = aws_vpc.terVPC.id
}

output "ter_def_sg" {
  value = aws_security_group.terDefaultSG.id
}

output "ter_private_net_ids" {
  value = aws_subnet.terPrivateSubnets[*].id
}

output "ter_public_net_ids" {
  value = aws_subnet.terPublicSubnets[*].id
}
