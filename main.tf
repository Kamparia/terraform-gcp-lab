// Configure the Google Cloud provider
provider "google" {
    credentials = file("CREDENTIALS_FILE.json") // GCP service account with permission to compute engine
    project     = "geospatial-dev-on-cloud"
    region      = "us-central1"
}

// Terraform plugin for creating random ids
resource "random_id" "instance_id" {
    byte_length = 8
}

// A single Compute Engine instance with Debian Linux OS
resource "google_compute_instance" "default" {
    name         = "webserver-vm-${random_id.instance_id.hex}"
    machine_type = "e2-micro"
    zone         = "us-central1-a"

    boot_disk {
        initialize_params {
            image = "debian-cloud/debian-11"
        }
    }

    network_interface {
        network = "default"
        access_config {
            // Include this section to give the VM an external ip address
        } 
    }

    // Make sure Apache is installed on all new instances for later steps
    metadata_startup_script = "sudo apt-get update && sudo apt-get install apache2 -y && echo '<!doctype html><html><body><h1>Hello from Terraform on Google Cloud!</h1></body></html>' | sudo tee /var/www/html/index.html"

    // Apply the firewall rule to allow external IPs to access this instance
    tags = ["http-server"]    
}

// Allow HTTP traffic
resource "google_compute_firewall" "http-server" {
    name    = "terraform-allow-http"
    network = "default"

    allow {
        protocol = "tcp"
        ports    = ["80"]
    }

    // Allow traffic from everywhere to instances with an http-server tag
    source_ranges = ["0.0.0.0/0"]
    target_tags   = ["http-server"]    
}

output "ip" {
    value = "${google_compute_instance.default.network_interface.0.access_config.0.nat_ip}"
}