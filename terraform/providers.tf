provider "proxmox" {
  pm_api_url          = "https://${var.proxmox_api.host}:${var.proxmox_api.port}/api2/json"
  pm_api_token_id     = var.proxmox_api_token.id
  pm_api_token_secret = var.proxmox_api_token.secret

  # NOTE Optional, but recommended to set to true if you are using self-signed certificates.
  pm_tls_insecure = true
}