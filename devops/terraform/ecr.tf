resource "aws_ecr_repository" "services" {
    for_each = toset(["ui", "orders", "catalog", "cart", "checkout"])

    name = "${var.project-name}-${each.key}"
    image_tag_mutability = "IMMUTABLE"

    image_scanning_configuration {
    scan_on_push = true
  }
}