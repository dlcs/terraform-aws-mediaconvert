variable "revision" {
  description = "Module revision, altering this will trigger script to be run"
  default     = "2"
}

resource "terraform_data" "create_presets" {
  input            = var.revision
  triggers_replace = var.revision

  provisioner "local-exec" {
    command     = "python upsert_presets.py"
    working_dir = path.module
  }
}
