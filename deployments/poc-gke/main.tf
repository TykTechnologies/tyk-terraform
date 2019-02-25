provider "google" {
  credentials = "${file("account.json")}"
  project = "${var.gcp_project}"
  region = "${var.gcp_default_region}"
  zone = "${var.gcp_default_zone}"
}

# Bastion instance

resource "google_compute_instance" "bastion" {
  name         = "tyk-testbench-bastion"
  machine_type = "n1-standard-1"

  tags = ["tyk-utils"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  // Local SSD disk
  scratch_disk {
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.tyk_utils.self_link}"

    access_config {
      // Ephemeral IP
    }
  }

  allow_stopping_for_update = true
}

# K8s cluster

resource "google_container_cluster" "tyk" {
  name   = "tyk-testbench"
  region = "${var.gcp_default_region}"

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count = 1

  # Setting an empty username and password explicitly disables basic auth
  master_auth {
    username = ""
    password = ""
  }

  network = "${google_compute_network.tyk.self_link}"
  subnetwork = "${google_compute_subnetwork.tyk_k8s.self_link}"

  # Enables VPC-native policy, auto-creates two secondary IP ranges on the subnet
  ip_allocation_policy {
  }

  private_cluster_config {
    # enable_private_endpoint = true  # This should only be enabled for fully private master
    enable_private_nodes = true
    master_ipv4_cidr_block = "172.16.0.0/28"
  }

  master_authorized_networks_config {
    # Access cluster master from utils subnet (like bastion host)
    cidr_blocks {
      cidr_block = "${google_compute_subnetwork.tyk_utils.ip_cidr_range}"
      display_name = "Tyk Utils subnet"
    }
  }

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    tags = ["tyk-k8s"]
  }
}

resource "google_container_node_pool" "tyk" {
  name       = "tyk-testbench-pool"
  region     = "${var.gcp_default_region}"
  cluster    = "${google_container_cluster.tyk.name}"
  node_count = 1  # For a regional cluster this is per zone rather than total

  node_config {
    machine_type = "n1-standard-1"

    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    tags = ["tyk-k8s"]
  }
  count = 0
}

resource "google_container_node_pool" "tyk_hcpu" {
  name       = "tyk-testbench-pool-hcpu"
  region     = "${var.gcp_default_region}"
  cluster    = "${google_container_cluster.tyk.name}"
  node_count = 1  # For a regional cluster this is per zone rather than total

  node_config {
    machine_type = "n1-highcpu-4"

    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    tags = ["tyk-k8s"]
  }
}


# MemoryStore Redis
resource "google_redis_instance" "redis" {
  name           = "tyk-testbench-redis"
  tier           = "STANDARD_HA"
  memory_size_gb = 2

  authorized_network = "${google_compute_network.tyk.self_link}"

  redis_version     = "REDIS_3_2"
  display_name      = "Tyk Testbench Redis HA"
  # reserved_ip_range = "192.168.0.0/29"
}


# Outputs

output "bastion_endpoint" {
  value = "${google_compute_instance.bastion.network_interface.0.access_config.0.nat_ip}"
}

output "cluster_endpoint" {
  value = "${google_container_cluster.tyk.endpoint}"
}

output "cluster_client_certificate" {
  value = "${google_container_cluster.tyk.master_auth.0.client_certificate}"
}

output "cluster_client_key" {
  value = "${google_container_cluster.tyk.master_auth.0.client_key}"
}

output "cluster_ca_certificate" {
  value = "${google_container_cluster.tyk.master_auth.0.cluster_ca_certificate}"
}

output "redis_host" {
  value = "${google_redis_instance.redis.host}"
}

output "redis_port" {
  value = "${google_redis_instance.redis.port}"
}
