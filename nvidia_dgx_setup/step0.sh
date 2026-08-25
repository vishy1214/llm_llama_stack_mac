# 1. Get your Tailscale IP address to use in the docker-compose file
tailscale ip -4

# 2. Create the Hugging Face cache directory on your host system
mkdir -p ~/.cache/huggingface
