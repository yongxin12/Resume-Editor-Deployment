output "market_frontend_tg_arn" {
  value = aws_lb_target_group.market_frontend_tg.arn
}

output "market_backend_tg_arn" {
  value = aws_lb_target_group.market_backend_tg.arn
}

output "editor_frontend_tg_arn" {
  value = aws_lb_target_group.editor_frontend_tg.arn
}

output "editor_backend_tg_arn" {
  value = aws_lb_target_group.editor_backend_tg.arn
}