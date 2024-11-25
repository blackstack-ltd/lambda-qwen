# lambda-qwen
## Running a Qwen LLM Model in a Lambda Function with llama.cpp

Running an LLM model in a Lambda function isn’t ideal, primarily due to the lack of GPU resources. This is an experiment to see if it’s possible at all, using the `Qwen/Qwen2.5-0.5B` model.

### Prequisites

🔧 [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
🐍 [Python](https://www.python.org/downloads/)
🛠️ [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
🐳 [Docker](https://www.docker.com/get-started/)
☁️  An AWS account
🖥️ [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html), configured to connect to your AWS account

### Getting started

1. 📂 Clone the repository

```bash
  git clone https://github.com/blackstack-ltd/lambda-qwen.git
```

2. 🔧 Run the installer/deployer

```bash
  cd lambda-qwen/src
  ./build.sh
```

3. 🚀 Invoke the Lambda function in your AWS environment with a string input containing the prompt.

```bash
  aws lambda invoke --function-name lambda_qwen --cli-binary-format raw-in-base64-out --payload '"Once upon a time ..."' output.txt
  cat output.txt
```

⚠️  Note: This functions cold start time is more than a minute, mostly due to having to load the model.

### Test a different model

At the top of the `build.sh` deployment script, there is a variable called `MODEL`.
You can change this to any other Hugging Face model name and test its compatibility.

⚠️  Note: More computationally expensive models may exceed Lambda’s maximum execution time of 15 minutes.
