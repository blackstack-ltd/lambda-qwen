import argparse
from pathlib import Path
from huggingface_hub import snapshot_download

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="download.py",
        description="Download a model from huggingface and save it locally"
    )
    parser.add_argument(
        "-m", "--model",
        type=str,
        default=None,
        help="the name of the model to download from huggingface"
    )
    parser.add_argument(
        "-l", "--local-dir",
        type=Path,
        default="downloaded_model",
        help="the local folder to download the model to"
    )
    return parser.parse_args()

#model_id="Qwen/Qwen2.5-0.5B-Instruct-AWQ"
#snapshot_download(repo_id=model_id, local_dir="Qwen2.5-0.5B-Instruct-AWQ", local_dir_use_symlinks=False, revision="main")

def main() -> None:
    args = parse_args()
    snapshot_download(repo_id=args.model, local_dir=args.local_dir, revision="main")

if __name__ == '__main__':
    main()
