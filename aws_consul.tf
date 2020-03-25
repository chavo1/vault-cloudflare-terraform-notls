resource "aws_instance" "consul" {
  ami           = "ami-0cc2b036435209c9e"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.chavo.id
  private_ip    = "172.31.16.31"
  subnet_id     = "subnet-ef814da2"

  tags = {
    Name  = "chavo-consul"
    vault = "app"
  }
  connection {
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
    host        = self.public_ip
  }
  provisioner "file" {
    source      = "asset/consul.sh"
    destination = "/tmp/consul.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo bash /tmp/consul.sh virginia",
    ]
  }
}