terraform {
  required_version = ">= 1.5.0"

  required_providers {
    ibm = {
      source  = "ibm-cloud/ibm"
      version = "~> 1.89"
    }
  }
}

provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.provider_region
}

provider "ibm" {
  alias            = "eu_de"
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = "eu-de"
}

provider "ibm" {
  alias            = "eu_es"
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = "eu-es"
}
