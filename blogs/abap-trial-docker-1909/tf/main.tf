# API Service:   Enable GoogleAPIs 
# Local:  modules/[channel]
# Remote: github.com://CloudVLab/terraform-lab-foundation//[module]/[channel]

# Module: Enable Google APIs
module "la_api_batch" {
  source = "github.com/CloudVLab/terraform-lab-foundation//basics/api_service/dev"

  # Pass values to the module
  gcp_project_id = var.gcp_project_id
  gcp_region     = var.gcp_region
  gcp_zone       = var.gcp_zone

  # Customise the GCE instance
  api_services = [ "compute.googleapis.com", "iamcredentials.googleapis.com", "addressvalidation.googleapis.com" ] 
}

# Reference:
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall
# https://github.com/terraform-google-modules/terraform-google-network/tree/master/modules/firewall-rules

module "la_fw" {
  ## NOTE: When changing the source parameter, `terraform init` is required

  ## REMOTE: GitHub (Public) access - working 
  source = "github.com/CloudVLab/terraform-lab-foundation//basics/vpc_firewall/stable"

  # Pass values to the module
  gcp_project_id = var.gcp_project_id
  gcp_region     = var.gcp_region
  gcp_zone       = var.gcp_zone

  ## Ex: Default Network
   fwr_network      = "default" 
  ## Ex: Custom Network
  # fwr_network      = module.la_vpc.vpc_network_name

  # Firewall Policy - Repeatable list of objects
  fwr_rules = [
  {
    fwr_name                    = "sapmachine"
    fwr_description             = "sapmachine"
    fwr_source_ranges           = [ "0.0.0.0/0" ]
    fwr_destination_ranges      = null
    fwr_source_tags             = null
    fwr_source_service_accounts = null
    fwr_target_tags             = ["sapmachine"]
    fwr_target_service_accounts = null
    fwr_priority                = "1000"
    fwr_direction               = "INGRESS"

    # Allow List
    allow = [
    {
      protocol     = "tcp"
      ports        = [ "3200","3300","8443","30213","50000","50001" ]
    }]

    # Deny List
    deny = []

    log_config = {
      metadata = "INCLUDE_ALL_METADATA"
    }

  }
  ]

  ## Firewall depends on existence of Network
 # depends_on = [ module.la_vpc.vpc_network_name ]
}

# Basics: IAM Service Account 
# Local:  basics/iam_service_account/dev
# Remote: github//basics/iam_service_account/stable

module "la_sa" {
  ## NOTE: When changing the `source` parameter
  ## `terraform init` is required

  ## https://www.terraform.io/language/modules/sources#selecting-a-revision
  ## Local Modules - working
  ## Module subdirectory needs to be defined within the TF directory
  ## source = "./basics/iam_service_account/stable"

  ## REMOTE: GitHub (Public) access - working 
  ## source = "github.com/CloudVLab/terraform-lab-foundation//basics/iam_service_account/dev?ref=tlf_iam"

  ## REMOTE: GitHub (Public) access - working 
  source = "github.com/CloudVLab/terraform-lab-foundation//basics/iam_service_account/stable"

  ## Exchange values between Qwiklabs and Module
  gcp_project_id = var.gcp_project_id
  gcp_region     = var.gcp_region 
  gcp_zone       = var.gcp_zone 

  ## Custom Properties
  # Pass reference to the student username
  iam_sa_name = "abap-sdk-dev" 
  iam_sa_display = "ABAP SDK Dev Account" 
  iam_sa_description = "ABAP SDK Dev Account" 
}



# GCE:    Virtual Machine
# Local:  modules/[channel]
# Remote: github.com://CloudVLab/terraform-lab-foundation//[module]/[channel]

# Module: Google Compute Engine

module "la_gce" {
  source = "github.com/CloudVLab/terraform-lab-foundation//basics/gce_instance/stable"

  # Pass values to the module
  gcp_project_id = var.gcp_project_id
  gcp_region     = var.gcp_region
  gcp_zone       = var.gcp_zone

  # Customise the GCE instance
  gce_name            = "abap-trial-docker" 
  gce_machine_network = "default" 
  gce_metadata         = null
  gce_startup_script   = "curl https://raw.githubusercontent.com/google-cloud-abap/community/main/blogs/abap-trial-docker-1909/vm_startup_script.sh -o /tmp/vm_startup_script.sh\nchmod 755 /tmp/vm_startup_script.sh\nnohup /tmp/vm_startup_script.sh > /tmp/output.txt &"

  ## Overrides
  #gce_region          = "us-central1" 
  #gce_zone            = "us-central1-a" 
  gce_machine_type    = "e2-highmem-2" 
  gce_tags            = ["sapmachine"] 
  gce_machine_image   = "projects/debian-cloud/global/images/debian-12-bookworm-v20230814" 
  #gce_machine_network = google_compute_subnetwork.dev_subnet.name
  gce_scopes          = ["cloud-platform"] 
  gce_service_account = "default"
  #gce_startup_script   = "${file("./scripts/lab-init")}"
}

# terraform init
# terraform plan -var "gcp_project_id=propane-bearing-399810" -var "gcp_region=us-west4" -var "gcp_zone=us-west4-b"
# terraform apply -var "gcp_project_id=propane-bearing-399810" -var "gcp_region=us-west4" -var "gcp_zone=us-west4-b"
# terraform plan -destroy -var "gcp_project_id=propane-bearing-399810" -var "gcp_region=us-west4" -var "gcp_zone=us-west4-b"

# This code is compatible with Terraform 4.25.0 and versions that are backwards compatible to 4.25.0.
# For information about validating this Terraform code, see https://developer.hashicorp.com/terraform/tutorials/gcp-get-started/google-cloud-platform-build#format-and-validate-the-configuration
/*
resource "google_compute_instance" "abap-trial-docker" {
  boot_disk {
    auto_delete = true
    device_name = "abap-trial-docker"

    initialize_params {
      image = "projects/debian-cloud/global/images/debian-12-bookworm-v20230814"
      size  = 200
      type  = "pd-balanced"
    }

    mode = "READ_WRITE"
  }

  can_ip_forward      = false
  deletion_protection = false
  enable_display      = false

  labels = {
    goog-ec-src = "vm_add-tf"
  }

  machine_type = "e2-highmem-2"

  metadata = {
    startup-script = "curl https://raw.githubusercontent.com/google-cloud-abap/community/main/blogs/abap-trial-docker-1909/vm_startup_script.sh -o /tmp/vm_startup_script.sh\nchmod 755 /tmp/vm_startup_script.sh\nnohup /tmp/vm_startup_script.sh > /tmp/output.txt &"
  }

  name = "abap-trial-docker"

  network_interface {
    access_config {
      network_tier = "PREMIUM"
    }

    subnetwork = "default"
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = false
    provisioning_model  = "STANDARD"
  }

  service_account {
    email  = "default"
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = false
    enable_vtpm                 = true
  }

  tags = ["sapmachine"]
}
*/