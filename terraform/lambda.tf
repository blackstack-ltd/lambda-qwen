variable "build_id" {
  type        = string
  description = "The build id that the ecr image is tagged with"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = local.namespace
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_execution_role" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "test_lambda" {
  function_name = local.namespace
  role          = aws_iam_role.lambda_role.arn
  image_uri     = "${aws_ecr_repository.ecr_repo.repository_url}:${var.build_id}"
  package_type  = "Image"
  timeout       = 900
  memory_size   = 10240
}
