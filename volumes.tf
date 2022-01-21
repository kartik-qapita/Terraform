#SCRIPT FOR EBS VOLUME ATTACHMENT TO EC2 INSTANCE
#Resource : EBS_Volume-1 
resource "aws_volume_attachment" "EBS_Attach-1" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.var.id
  instance_id = aws_instance.phantoms-dev-instance.id
}
resource "aws_ebs_volume" "var" {
  availability_zone = "ap-south-1b"
  size              = "15"
}

#Resource : EBS_Volume-2
resource "aws_volume_attachment" "EBS_Attach-2" {
  device_name = "/dev/sdi"
  volume_id   = aws_ebs_volume.home.id
  instance_id = aws_instance.phantoms-dev-instance.id
}
resource "aws_ebs_volume" "home" {
  availability_zone = "ap-south-1b"
  size              = "10"
}

#Resource : EBS_Volume-3
resource "aws_volume_attachment" "EBS_Attach-3" {
  device_name = "/dev/sdj"
  volume_id   = aws_ebs_volume.seqdata.id
  instance_id = aws_instance.phantoms-dev-instance.id
}
resource "aws_ebs_volume" "seqdata" {
  availability_zone = "ap-south-1b"
  size              = "10"
}

#Resource : EBS_Volume-4
resource "aws_volume_attachment" "EBS_Attach-4" {
  device_name = "/dev/sdk"
  volume_id   = aws_ebs_volume.mongodb-data.id
  instance_id = aws_instance.phantoms-dev-instance.id
}
resource "aws_ebs_volume" "mongodb-data" {
  availability_zone = "ap-south-1b"
  size              = "30"
}

#Resource : EBS_Volume-5
resource "aws_volume_attachment" "EBS_Attach-5" {
  device_name = "/dev/sdl"
  volume_id   = aws_ebs_volume.eventstore.id
  instance_id = aws_instance.phantoms-dev-instance.id
}
resource "aws_ebs_volume" "eventstore" {
  availability_zone = "ap-south-1b"
  size              = "30"
}
