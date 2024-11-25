#!/bin/bash

LLAMBDA_IMAGE="lambda:llama"
MODEL="Qwen/Qwen2.5-0.5B"
MODELNAME="$(echo ${MODEL} | cut -d '/' -f 2)"

run_cmd() {
  local title="$1"
  local cmd="$2"

  echo ""
  echo "${title}"

  if [[ "${cmd}" != "" ]]; then
    {
      eval "${cmd}"
    } 2>&1 | while read -r line; do
      echo -e "  \e[3;90m$line\e[0m"
    done
  fi
}

run_cmd "🚀 Starting the build process for llama-cli, llama-quantizer, and model..."

if [[ ! -f ../lambda_runtime/llama-cli ]] || [[ ! -f ../lambda_runtime/model.gguf ]]; then
  run_cmd \
    "🔨 Building ${LLAMBDA_IMAGE} docker image..." \
    "docker build -t ${LLAMBDA_IMAGE} ."
  run_cmd \
    "📂 Cloning llama.cpp repository..." \
    "git clone git@github.com:ggerganov/llama.cpp.git"
  run_cmd \
    "🔧 Compiling llama-cli and llama-quantize inside build container..." \
    "docker run -v ./llama.cpp:/llama.cpp -w /llama.cpp ${LLAMBDA_IMAGE} make llama-cli llama-quantize"
  run_cmd \
    "📥 Downloading model ${MODEL}..." \
    "python download.py -m ${MODEL}"
  run_cmd \
    "🔄 Converting model to GGUF format..." \
    "python llama.cpp/convert_hf_to_gguf.py downloaded_model --outfile ${MODELNAME}-f16.gguf"
  run_cmd \
    "📂 Moving converted model to llama.cpp directory..." \
    "mv ${MODELNAME}-f16.gguf ./llama.cpp/"
  run_cmd \
    "🔧 Quantizing the model with Q4_0 precision, inside build container..." \
    "docker run -v ./llama.cpp:/llama.cpp -w /llama.cpp ${LLAMBDA_IMAGE} ./llama-quantize ${MODELNAME}-f16.gguf ${MODELNAME}-q4_0.gguf q4_0"
  run_cmd \
    "📂 Copying quantized model and llama-cli to lambda_runtime..." \
    "cp llama.cpp/${MODELNAME}-q4_0.gguf ../lambda_runtime/model.gguf && cp llama.cpp/llama-cli ../lambda_runtime/"
else
  run_cmd "✅ llama-cli and model are already built and available in lambda_runtime."
fi

run_cmd "📦 Calculating build ID for Docker image..."
BUILD_ID=$(shasum ../lambda_runtime/Dockerfile ../lambda_runtime/bootstrap ../lambda_runtime/llama-cli ../lambda_runtime/model.gguf | shasum | cut -d ' ' -f 1)
ALREADY_BUILT="NO"
run_cmd "🔍 Checking if image with build ID ${BUILD_ID} already exists in ECR..."
for IMAGE_TAG in $(aws ecr list-images --repository-name lambda_qwen --query 'imageIds[*].imageTag' --out text); do
  if [[ "${IMAGE_TAG}" == "${BUILD_ID}" ]]; then
    ALREADY_BUILT="YES"
    run_cmd "✅ Docker image with build ID ${BUILD_ID} already exists in ECR."
    break
  fi
done
if [[ "${ALREADY_BUILT}" == "NO" ]]; then
  REPOSITORY_URI=$(aws ecr describe-repositories --repository-names lambda_qwen --query 'repositories[0].repositoryUri' --out text)
  REGION=$(echo ${REPOSITORY_URI} | cut -d '.' -f 4)
  REGISTRY_URL=$(echo ${REPOSITORY_URI} | cut -d '/' -f 1)
  cd ../lambda_runtime

  run_cmd \
    "🏗️ Building new Docker image..." \
    "docker build -t ${REPOSITORY_URI}:${BUILD_ID} ."
  run_cmd \
    "🔑 Logging into ECR registry ${REGISTRY_URL}..." \
    "aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${REGISTRY_URL}"
  run_cmd \
    "📤 Pushing Docker image to ECR..." \
    "docker push ${REPOSITORY_URI}:${BUILD_ID}"
fi

cd ../terraform
run_cmd \
  "🌍 Preparing to deploy Terraform configuration..." \
  "terraform plan -var=\"build_id=${BUILD_ID}\" -out terraform.plan"

echo ""
read -p "👀 Does this 👆 plan look good? Can I apply it? [Y/N] " ANSWER

if [[ "${ANSWER}" == "Y" ]]; then
  run_cmd \
    "🚀 Applying Terraform plan..." \
    "terraform apply terraform.plan"
else
  run_cmd "❌ Terraform deployment aborted."
fi

cd ../src
run_cmd "🎉 Build and deployment process completed!"
