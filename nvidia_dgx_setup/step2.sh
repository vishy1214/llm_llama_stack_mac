##Set Up Free NVIDIA Pass-Through

# Configure the NVIDIA runtime engine for your newly installed Docker CE
sudo nvidia-container-toolkit runtime configure --runtime=docker

# Restart the background Docker service to apply the hardware changes
sudo systemctl restart docker
