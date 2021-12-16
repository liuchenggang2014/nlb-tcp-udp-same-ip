

# 1. create a google public ip

resource "google_compute_address" "nlb" {
  name = "nlb-public-ip"
}

output "nlb_addr" {
  value       = google_compute_address.nlb.address
  description = "The nlb external IP."
}


# 2. create a gce vm

resource "google_compute_instance" "vm1" {
  name         = "nlb-vm"
  machine_type = "e2-medium"

  # network tag
  tags = ["http-server", "https-server"]

  # os image by run "gcloud compute images list"
  boot_disk {
    initialize_params {
      image = "centos-7-v20211214"
    }
  }


  network_interface {
    network = "default"

    access_config {
      // Ephemeral public IP
    }
  }

  # allows Terraform to stop the instance to update its properties. I
  allow_stopping_for_update = "true"


  # use the project default service account but with the full cloud scopes.
  service_account {
    scopes = ["cloud-platform"]
  }
}

output "nlb_vm" {
  value       = google_compute_instance.vm1.name
  description = "The vm for nlb."
}

# 3. create a un-managed instance group

resource "google_compute_instance_group" "nlb_umig" {
  name = "nlb-unmanaged-instance-group"

  instances = [google_compute_instance.vm1.self_link]

  #   named_port {
  #     name = "tcp-port1"
  #     port = "10001"
  #   }

  #   named_port {
  #     name = "tcp-port2"
  #     port = "10002"
  #   }

  #   named_port {
  #     name = "udp-port1"
  #     port = "10001"
  #   }

  #   named_port {
  #     name = "udp-port2"
  #     port = "10002"
  #   }

}

output "nlb_umig" {
  value       = google_compute_instance_group.nlb_umig.self_link
  description = "umig for nlb."
}

# 4. healthcheck for nlb-tcp
resource "google_compute_region_health_check" "nlb_hc" {
  name                = "check-tcp"
  timeout_sec         = 1
  check_interval_sec  = 1
  healthy_threshold   = 2
  unhealthy_threshold = 10 # 10 seconds

  tcp_health_check {
    port = "10001"
  }
}

output "nlb_hc" {
  value       = google_compute_region_health_check.nlb_hc.type
  description = "nlb health check."
}


# 5. nlb_tcp backend service

resource "google_compute_region_backend_service" "nlb_be_tcp" {

  name                  = "nlb-bs-tcp"
  protocol              = "TCP"
  timeout_sec           = 10
  load_balancing_scheme = "EXTERNAL"
  health_checks         = [google_compute_region_health_check.nlb_hc.id]

  # https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_instance_group_manager#attributes-reference
  # refer to this doc to use this attribute to get the full URL
  backend {
    group = google_compute_instance_group.nlb_umig.id
  }
}


output "nlb_tcp_banckend_service" {
  value       = google_compute_region_backend_service.nlb_be_tcp.name
}

# 6. nlb-TCP frontend forwarding rule , choose all_ports from (ports and allports)
resource "google_compute_forwarding_rule" "nlb_fe_tcp_allport" {

  name        = "nlb-forwarding-rule-tcp-allports"
  ip_protocol = "TCP"
  all_ports   = true
  ip_address  = google_compute_address.nlb.address

  backend_service = google_compute_region_backend_service.nlb_be_tcp.id
}

output "nlb_TCP_frontend_service" {
  value       = google_compute_forwarding_rule.nlb_fe_tcp_allport.name
}

# 7. nlb_tcp backend service

resource "google_compute_region_backend_service" "nlb_be_udp" {

  name                  = "nlb-bs-udp"
  protocol              = "UDP"
  timeout_sec           = 10
  load_balancing_scheme = "EXTERNAL"
  health_checks         = [google_compute_region_health_check.nlb_hc.id]

  # https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_instance_group_manager#attributes-reference
  # refer to this doc to use this attribute to get the full URL
  backend {
    group = google_compute_instance_group.nlb_umig.id
  }
}


output "nlb_UDP_banckend_service" {
  value       = google_compute_region_backend_service.nlb_be_udp.name
}

# 8. nlb-udp frontend forwarding rule , choose all_ports from (ports and allports)
resource "google_compute_forwarding_rule" "nlb_fe_udp_allport" {

  name            = "nlb-forwarding-rule-udp-allports"
  ip_protocol     = "UDP"
  all_ports       = true
  ip_address      = google_compute_address.nlb.address
  backend_service = google_compute_region_backend_service.nlb_be_udp.id

}

output "nlb_UDP_frontend_service" {
  value       = google_compute_forwarding_rule.nlb_fe_udp_allport.name
}