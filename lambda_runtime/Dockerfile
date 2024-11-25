FROM public.ecr.aws/amazonlinux/amazonlinux:2023-minimal
RUN dnf install -y jq libgomp && dnf clean all
COPY model.gguf .
COPY llama-cli .
COPY bootstrap .
CMD [ "./bootstrap" ]
