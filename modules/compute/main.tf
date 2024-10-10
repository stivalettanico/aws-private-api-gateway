# Create the Lambda zip file from the Python code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

data "aws_ssm_parameter" "latest_amazon_linux_2" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

# Create IAM Role for the Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the basic execution policy for Lambda
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Create the Lambda function
resource "aws_lambda_function" "lambda_function" {
  function_name = var.function_name
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  filename      = data.archive_file.lambda_zip.output_path

  # Generate the zip file from the Python code
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}


# IAM role for EC2 instance to use SSM
resource "aws_iam_role" "ec2_ssm_role" {
  name = "ec2_ssm_role_test_ns"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the SSM role policy to allow EC2 to use SSM
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Create an IAM instance profile to attach the role to the EC2 instance
resource "aws_iam_instance_profile" "ec2_ssm_profile" {
  name = "ec2_ssm_instance_profile"
  role = aws_iam_role.ec2_ssm_role.name
}


resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg"
  description = "Security group for private EC2 instance"
  vpc_id      = var.vpc_id

  # Outbound traffic to the VPC Endpoint security group on port 443
  egress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [var.vpce-execute-api-sg] # VPC Endpoint security group ID
  }

  # Egress rule to allow all other outbound traffic (needed for SSM)
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allows outbound to internet or SSM endpoints
  }



  tags = {
    Name = "ec2-sg-${var.project_name}-${var.environment}-${var.region_substring}"
  }
}


resource "aws_instance" "private_ec2" {
  ami           = data.aws_ssm_parameter.latest_amazon_linux_2.value
  instance_type = "t3.micro"
  subnet_id     = var.subnet_id

  # Security group configuration
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  # IAM role for SSM access
  iam_instance_profile = aws_iam_instance_profile.ec2_ssm_profile.name

  tags = {
    Name = "ec2-instance-${var.project_name}-${var.environment}-${var.region_substring}"
  }
}