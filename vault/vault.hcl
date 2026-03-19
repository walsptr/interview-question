storage "file" {
  path = "/vault/data"
}

# In production, always use TLS with proper certificates
listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = "false"
  tls_client_ca_file = "/vault/certs/ca.crt"
  tls_cert_file = "/vault/certs/vault.crt"
  tls_key_file  = "/vault/certs/vault.key"
  tls_disable_client_certs  = "true"
}

api_addr = "https://vault.syawal.local:8200"

cluster_addr = "https://vault.syawal.local:8201"

disable_mlock = true

ui = true

telemetry {
  prometheus_retention_time = "30s"
  disable_hostname = true
}