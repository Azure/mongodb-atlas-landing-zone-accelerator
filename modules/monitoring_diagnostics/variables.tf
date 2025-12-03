variable "diagnostic_setting_name" {
  description = "Name used for diagnostic settings."
  type        = string
}

variable "diagnostic_targets" {
  description = "Keys to diagnostic targets."
  type = object({
    workspace_id = string
    resources = optional(map(object({
      id = string
    })), {})
  })
}
