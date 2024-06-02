resource "hcloud_ssh_key" "flokoe" {
  name       = "flokoe"
  public_key = file("../files/flokoe.pub")
}

resource "hcloud_firewall" "main" {
  name = "main"

  rule {
    direction = "in"
    protocol  = "icmp"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "22"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "80"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "443"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction = "in"
    protocol  = "udp"
    port      = "443"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
}

data "hetznerdns_zone" "citizenalpha_de" {
  name = "citizenalpha.de"
}

resource "hcloud_floating_ip" "main_ipv4" {
  name              = "main-ipv4"
  type              = "ipv4"
  home_location     = "nbg1"
  delete_protection = true
}

resource "hcloud_rdns" "main_ipv4" {
  floating_ip_id = hcloud_floating_ip.main_ipv4.id
  ip_address     = hcloud_floating_ip.main_ipv4.ip_address
  dns_ptr        = "citizenalpha.de"
}

resource "hetznerdns_record" "main_ipv4" {
  zone_id = data.hetznerdns_zone.citizenalpha_de.id
  name    = "@"
  value   = hcloud_floating_ip.main_ipv4.ip_address
  type    = "A"
}

resource "hcloud_floating_ip" "main_ipv6" {
  name              = "main-ipv6"
  type              = "ipv6"
  home_location     = "nbg1"
  delete_protection = true
}

resource "hcloud_rdns" "main_ipv6" {
  floating_ip_id = hcloud_floating_ip.main_ipv6.id
  ip_address     = hcloud_floating_ip.main_ipv6.ip_address
  dns_ptr        = "citizenalpha.de"
}

resource "hcloud_rdns" "main_ipv6_1" {
  floating_ip_id = hcloud_floating_ip.main_ipv6.id
  ip_address     = "${hcloud_floating_ip.main_ipv6.ip_address}1"
  dns_ptr        = "citizenalpha.de"
}

resource "hetznerdns_record" "main_ipv6" {
  zone_id = data.hetznerdns_zone.citizenalpha_de.id
  name    = "@"
  value   = "${hcloud_floating_ip.main_ipv6.ip_address}1"
  type    = "AAAA"
}

resource "hcloud_server" "soerver" {
  name               = "soerver.citizenalpha.de"
  server_type        = "cpx11"
  image              = "debian-12"
  location           = "nbg1"
  ssh_keys           = [hcloud_ssh_key.flokoe.id]
  keep_disk          = true
  firewall_ids       = [hcloud_firewall.main.id]
  delete_protection  = false
  rebuild_protection = false
}

resource "hcloud_rdns" "soerver_ipv4" {
  server_id  = hcloud_server.soerver.id
  ip_address = hcloud_server.soerver.ipv4_address
  dns_ptr    = "soerver.citizenalpha.de"
}

resource "hetznerdns_record" "soerver_ipv4" {
  zone_id = data.hetznerdns_zone.citizenalpha_de.id
  name    = "soerver"
  value   = hcloud_server.soerver.ipv4_address
  type    = "A"
}

resource "hcloud_rdns" "soerver_ipv6" {
  server_id  = hcloud_server.soerver.id
  ip_address = hcloud_server.soerver.ipv6_address
  dns_ptr    = "soerver.citizenalpha.de"
}

resource "hetznerdns_record" "soerver_ipv6" {
  zone_id = data.hetznerdns_zone.citizenalpha_de.id
  name    = "soerver"
  value   = hcloud_server.soerver.ipv6_address
  type    = "AAAA"
}

resource "hcloud_floating_ip_assignment" "main_ipv4" {
  floating_ip_id = hcloud_floating_ip.main_ipv4.id
  server_id      = hcloud_server.soerver.id
}

resource "hcloud_floating_ip_assignment" "main_ipv6" {
  floating_ip_id = hcloud_floating_ip.main_ipv6.id
  server_id      = hcloud_server.soerver.id
}

resource "hetznerdns_record" "mailbox_org_verify" {
  zone_id = data.hetznerdns_zone.citizenalpha_de.id
  name    = "556ae8874e5b529b9c59daefd8c6fcde53a46f4f"
  value   = "f886c1577bda7b15ba3261a2435adf410c3cb967"
  type    = "TXT"
}

resource "hetznerdns_record" "mx" {
  for_each = toset([
    "10 mxext1.mailbox.org.",
    "10 mxext2.mailbox.org.",
    "20 mxext3.mailbox.org."
  ])

  zone_id = data.hetznerdns_zone.citizenalpha_de.id
  name    = "@"
  value   = each.value
  type    = "MX"
}

resource "hetznerdns_record" "spf" {
  zone_id = data.hetznerdns_zone.citizenalpha_de.id
  name    = "@"
  value   = "\"v=spf1 include:mailbox.org ~all\""
  type    = "TXT"
}

resource "hetznerdns_record" "dkim" {
  for_each = toset([
    "mbo0001",
    "mbo0002",
    "mbo0003",
    "mbo0004"
  ])

  zone_id = data.hetznerdns_zone.citizenalpha_de.id
  name    = "${each.value}._domainkey"
  value   = "${each.value}._domainkey.mailbox.org."
  type    = "CNAME"
}

resource "hetznerdns_record" "dmarc" {
  zone_id = data.hetznerdns_zone.citizenalpha_de.id
  name    = "_dmarc"
  value   = "\"v=DMARC1;p=none;rua=mailto:postmaster@citizenalpha.de\""
  type    = "TXT"
}
