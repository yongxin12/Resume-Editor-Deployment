# output "market_backend_tg_arn" {
#   value = aws_lb_target_group.this["market_backend_tg"].arn
# }

# output "market_frontend_tg_arn" {
#   value = aws_lb_target_group.this["market_frontend_tg"].arn
# }

# output "editor_backend_tg_arn" {
#   value = aws_lb_target_group.this["editor_backend_tg"].arn
# }

# output "editor_frontend_tg_arn" {
#   value = aws_lb_target_group.this["editor_frontend_tg"].arn
# }

output "target_group_arns" {
  description = "ARNs of all target groups"
  value       = { for name, tg in aws_lb_target_group.target_groups : name => tg.arn }
}