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
  value   = "\"v=spf1 a include:mailbox.org ~all\""
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

resource "hetznerdns_record" "www" {
  zone_id = data.hetznerdns_zone.citizenalpha_de.id
  name    = "www"
  value   = "${data.hetznerdns_zone.citizenalpha_de.name}."
  type    = "CNAME"
}

resource "hetznerdns_record" "offen" {
  zone_id = data.hetznerdns_zone.citizenalpha_de.id
  name    = "offen"
  value   = "${data.hetznerdns_zone.citizenalpha_de.name}."
  type    = "CNAME"
}

resource "hetznerdns_record" "chasquid_dkim" {
  zone_id = data.hetznerdns_zone.citizenalpha_de.id
  name    = "20240605._domainkey"
  value   = "\"v=DKIM1; k=rsa; p=MIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEApmcstRdumddnWtYblAX8E48iIsD2RRG+SKNHJJ0Gf+/je/bznbKizBLcqrgWqJuVlDXo/85BVVXE8O31L5Vn0WtpSOKShTtP0bVOvLJm9CobmN3IUt7vcsxkI7I2Dd8F1WmXB/IHLn876X0GGtr87cSDM+JWXzPrZ4q6C2808/11bY/qlEKhGkP9BhIUrGEb6\" \"ezTi3B1FbI2kBt785PNVCOKZbIFy082xd2ZYbxCP8f/u4Nn8FQW9qBm94GBSd/UCboucXXnthPpQ3/SybDHnerqsSpui8XRcFei0Gk5xz2sMqi0pDQRfVRxc6fWJzdp9td1xYhFRlo5QXcroV4hXkkFIFbkwRf16FzasXxZf5sit+6u0ijmoes5XEPWdH6OymPrcApghjLbTNAffYSmaZDXHNedlke59iCUb7WW1iHcpP8/5PoPYYUb04qYOMTI\" \"nH15cknyyMr872mBkRmq04KAcESyFqWXKRDG4XQ7pioW2p24Vy6J+o1okvF51w6lAgMBAAE=\" "
  type    = "TXT"
}
