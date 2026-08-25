#Verify and Boot Your Containers

# 1. Run a quick check to make sure Docker can access your GPU drivers
docker run --rm --runtime=nvidia --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi

# 2. Fire up your updated composition stack in the background
docker compose up -d
