resource "google_compute_network" "tyk" {
  name                    = "tyk-testbench"
  auto_create_subnetworks = "false"
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "tyk_k8s" {
  name          = "tyk-testbench-k8s"
  ip_cidr_range = "10.2.0.0/16"

  # region        = "europe-west1"
  network                  = "${google_compute_network.tyk.self_link}"
  private_ip_google_access = "true"                                    # Private Google Access is required for private k8s cluster in this subnet
}

resource "google_compute_subnetwork" "tyk_mongo" {
  name          = "tyk-testbench-mongo"
  ip_cidr_range = "10.3.2.0/24"

  # region        = "europe-west1"
  network = "${google_compute_network.tyk.self_link}"
}

resource "google_compute_subnetwork" "tyk_utils" {
  name          = "tyk-testbench-utils"
  ip_cidr_range = "10.3.1.0/24"

  # region        = "europe-west1"
  network = "${google_compute_network.tyk.self_link}"
}

resource "google_compute_router" "tyk" {
  name    = "tyk-testbench-router"
  network = "${google_compute_network.tyk.self_link}"
}

resource "google_compute_address" "tyk_nat" {
  count = 2
  name  = "tyk-testbench-nat-${count.index}"
}

resource "google_compute_router_nat" "tyk" {
  name                               = "tyk-testbench-nat"
  router                             = "${google_compute_router.tyk.name}"
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = ["${google_compute_address.tyk_nat.*.self_link}"]
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

resource "google_compute_firewall" "tyk_k8s" {
  name    = "tyk-testbench-k8s"
  network = "${google_compute_network.tyk.name}"

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "8080", "3000", "5000"]
  }

  # source_tags = ["tyk-utils"]
  target_tags = ["tyk-k8s"]
}

resource "google_compute_firewall" "tyk_mongo" {
  name    = "tyk-testbench-mongo"
  network = "${google_compute_network.tyk.name}"

  allow {
    protocol = "tcp"
    ports    = ["22", "27017"]
  }

  # source_tags = ["tyk-k8s", "tyk-utils", "tyk-mongo"]
  target_tags = ["tyk-mongo"]
}

resource "google_compute_firewall" "tyk_utils" {
  name    = "tyk-testbench-utils"
  network = "${google_compute_network.tyk.name}"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["tyk-utils"]
}
