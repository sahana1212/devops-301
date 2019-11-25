provider "aws" {
  region = "eu-central-1"
  
}

resource "aws_instance" "backend" {
  ami                    = "ami-0cc0a36f626a4fdf5"
  instance_type          = "t2.micro"
  key_name               = "master-key"
  vpc_security_group_ids = ["${var.sg-id}"]

}

resource "null_resource" "remote-exec-1" {
    connection {
    user        = "ubuntu"
    type        = "ssh"
    private_key = "/var/lib/jenkins/master-key.pem"
    host        = "${aws_instance.backend.public_ip}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install python sshpass -y",
    ]
  }
}

resource "null_resource" "ansible-main" {
provisioner "local-exec" {
  command = <<EOT
        sleep 100;
        > jenkins-ci.ini;
        echo "[jenkins-ci]"| tee -a jenkins-ci.ini;
        export ANSIBLE_HOST_KEY_CHECKING=False;
        echo "${aws_instance.backend.public_ip}" | tee -a jenkins-ci.ini;
        ansible-playbook -e  sshKey=${var.pvt_key} -i jenkins-ci.ini ./ansible/setup-backend.yaml -u ubuntu -v
    EOT
}
}
