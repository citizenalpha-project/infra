terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.47.0"
    }

    hetznerdns = {
      source  = "timohirt/hetznerdns"
      version = "~> 2.2.0"
    }
  }

  required_version = "~> 1.8.4"
}
