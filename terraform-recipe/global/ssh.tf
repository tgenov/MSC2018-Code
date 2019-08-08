resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "ssh_key_private" {
  content  = "${tls_private_key.ssh.private_key_pem}"
  filename = "${path.root}/assets/ssh-key/id_rsa"

  provisioner "local-exec" {
    command = "chmod 600 ${path.root}/assets/ssh-key/id_rsa"
  }

}
resource "local_file" "ssh_key_public" {
  content  = "${tls_private_key.ssh.public_key_openssh}"
  filename = "${path.root}/assets/ssh-key/id_rsa.pub"

  provisioner "local-exec" {
    command = "chmod 666 ${path.root}/assets/ssh-key/id_rsa.pub"
  }
}

output "public_key" {
  value = "${tls_private_key.ssh.public_key_openssh}"
}

output "private_key" {
  value = "${tls_private_key.ssh.private_key_pem}"
  description = "Private SSH key for accessing the launched honeypots"
  sensitive = true
}