variable "cowrie_config" {
  type = "map"

  # Launch each instance with a different payload
  # References a path under the "./payload" directory
  default = {
    "0" = "arm-default"
    "1" = "arm-elf-patch"
    "2" = "arm-responder"
  }
}
