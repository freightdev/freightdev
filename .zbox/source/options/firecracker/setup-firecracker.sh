cd ~/firecracker || mkdir ~/firecracker && cd ~/firecracker

# Download the correct asset
curl -L -o firecracker-v1.13.1-x86_64.tgz \
     https://github.com/firecracker-microvm/firecracker/releases/download/v1.13.1/firecracker-v1.13.1-x86_64.tgz

# Extract
tar -xzf firecracker-v1.13.1-x86_64.tgz

# Inspect the extracted directory
ls -l

# Assuming the extracted folder is `firecracker-v1.13.1-x86_64`, move binaries
sudo mv firecracker-v1.13.1-x86_64/firecracker /usr/local/bin/firecracker
sudo mv firecracker-v1.13.1-x86_64/jailer /usr/local/bin/jailer

# Set permissions
sudo chmod +x /usr/local/bin/firecracker /usr/local/bin/jailer

# Verify
/usr/local/bin/firecracker --version
/usr/local/bin/jailer --version
