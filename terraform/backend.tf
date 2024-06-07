terraform {
  backend "http" {
    address        = "https://lynx.citizenalpha.de/client/infra/infra/prod/state"
    lock_address   = "https://lynx.citizenalpha.de/client/infra/infra/prod/lock"
    unlock_address = "https://lynx.citizenalpha.de/client/infra/infra/prod/unlock"
    lock_method    = "POST"
    unlock_method  = "POST"
  }
}
