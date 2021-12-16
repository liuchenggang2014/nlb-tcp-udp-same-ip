provider "google" {
  # Update credentials to the correct location, alternatively set   GOOGLE_APPLICATION_CREDENTIALS=/path/to/.ssh/bq-key.json in your shell session and   remove the credentials attribute.
  #   credentials = file("sa.json")
  project = "cliu201"
  region  = "us-central1"
  zone    = "us-central1-a"

}
