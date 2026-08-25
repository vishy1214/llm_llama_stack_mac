### The Production Performance Docker ComposeCreate a file named docker-compose.yaml on your DGX Spark host machine:yaml

```
version: '3.8'
services:
  vllm-scout:
    image: vllm/vllm-openai:latest
    container_name: vllm-scout
    restart: unless-stopped
    ipc: host  # CRITICAL: Allows vLLM to use host-level shared memory without throttling
    environment:
      - HF_TOKEN=your_huggingface_token_here
      - VLLM_DISABLE_COMPILE_CACHE=1  # CRITICAL: Prevents compilation bugs on Blackwell
    volumes:
      # Stores model weights on the host so they don't re-download on restart
      - ~/.cache/huggingface:/root/.cache/huggingface
    expose:
      - "8000"
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all  # EQUIVALENT TO: --gpus all (Passes all Blackwell cores to Docker)
              capabilities: [gpu]
    command: >
      vllm serve "meta-llama/Llama-4-Scout-17B-16E-Instruct"
      --host 0.0.0.0
      --port 8000
      --served-model-name "llama-4-scout"
      --gpu-memory-utilization 0.90  # CRITICAL: Locks 90% of the 128GB unified memory
      --max-model-len 16384
      --max-num-seqs 32
      --trust-remote-code

  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: open-webui
    restart: unless-stopped
    ports:
      # CRITICAL: Binds strictly to your Tailscale IP to lock out external networks
      - "100.11.22.33:3000:8080"
    volumes:
      - open-webui:/app/backend/data
    environment:
      - OPENAI_API_BASE_URL=http://vllm-scout:8000/v1
      - OPENAI_API_KEY=sk-not-needed-locally
      - ENABLE_OLLAMA_API=false
    depends_on:
      - vllm-scout

volumes:
  open-webui:
  ```
Use code with caution.(Note: Remember to replace your_huggingface_token_here and change 100.11.22.33 to your true Tailscale IP address before continuing).

### 📋 Step-by-Step Execution Plan for DGX Spark

Follow these steps in order to install, configure, and safely boot up the system.

# Step 1: Prep the Host Machine
Ensure your Tailscale VPN is up and active, and check your private IP address.bash 

```
#1. Get your Tailscale IP address to use in the docker-compose file
tailscale ip -4

#2.Create the Hugging Face cache directory on your host system
mkdir -p ~/.cache/huggingface
```

Use code with caution.

# Step 2: Verify the NVIDIA Container Toolkit

Before running Docker, ensure that the host OS can pass the GPU straight into a container. 
If you haven't installed the toolkit yet, configure the production repositories and install it:

bash
```
# 1. Setup the package repository
curl -fsSL https://github.io | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://github.io | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.4th/nvidia-container-toolkit.list

# 2. Install the toolkit
sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit

# 3. Configure the Docker runtime and restart Docker to apply changes
sudo nvidia-container-toolkit qconfig --set nvidia-container-runtime.experimental
sudo systemctl restart docker

```


# Step 3: Run a Hardware Sanity Check

Test if Docker can see the Grace Blackwell hardware with maximum access permissions before launching the full stack:bashdocker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi
Use code with caution.If this command displays your GPU specifications, your hardware pass-through is working flawlessly.Step 4: Launch the Production StackNavigate to the directory containing your updated docker-compose.yaml and pull down the optimized runtime images:bash# 1. Pull the official images
docker compose pull

# 2. Launch the containers in detached (background) mode
docker compose up -d
Use code with caution.Step 5: Monitor the Setup LogsBecause Llama 4 Scout is a large model, vLLM needs a few minutes to download the weights from Hugging Face and prepare the internal memory tables. Track its progress live:bashdocker logs -f vllm-scout
Use code with caution.Look for the line: Uvicorn running on http://0.0.0. This means the model is fully awake, optimized, and ready to accept traffic.Step 6: Onboard Your UsersHave an administrator connect to the Tailscale VPN.Open a browser and head to http://<YOUR-DGX-TAILSCALE-IP>:3000.Create the very first account. This account automatically gets global administrator privileges.Go into the Admin Panel settings to enable user registrations or invite your 30+ team members directly.