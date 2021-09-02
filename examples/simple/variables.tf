variable "public_key" {
  type = string
}

variable "ec2_image_id" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "test_name" {
  type = string
}
