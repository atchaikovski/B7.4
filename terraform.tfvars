region                     = "us-east-1"
instance_type              = "t2.medium"
enable_detailed_monitoring = true

common_tags = {
  Owner       = "Alex Tchaikovski"
  Project     = "Small k8s cluster"
  Purpose     = "B7.4"
}

master_host_name = "master"
worker_host_name = "worker"