#!/bin/bash

# Banner Display
echo "---------------------------------------------"
echo " LINUX PINGPONG NODE SETUP"
echo " by samuraiheart"
echo " Follow https://github.com/KazamiHazaki"
echo "---------------------------------------------"

# Define variables
ENV_FILE="$PWD/.env-pingpong"
SERVICE_NAME="pingpong"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
PINGPONG_EXECUTABLE="$PWD/PINGPONG"  # Update this with the actual path to your PINGPONG executable
# Install Docker on Ubuntu if not installed and always download PINGPONG file from GitHub

# Stop on any error
set -e

# Step 1: Update the system
echo "Updating system packages..."
sudo apt update

# Check if Docker is already installed
if ! command -v docker &> /dev/null
then
    # Step 2: Install required packages
    echo "Installing required packages..."
    sudo apt install apt-transport-https ca-certificates curl software-properties-common screen -y

    # Step 3: Add Docker's official GPG key
    echo "Adding Docker's official GPG key..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    # Step 4: Add Docker repository
    echo "Adding Docker repository..."
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Step 5: Update apt package index
    echo "Updating apt package index..."
    sudo apt update

    # Step 6: Install Docker Engine
    echo "Installing Docker Engine..."
    sudo apt install docker-ce docker-ce-cli containerd.io -y

    # Step 7: Verify Docker Installation
    echo "Checking Docker status..."
    sudo systemctl status docker

    # Step 8: Run Docker without sudo (Optional)
    echo "Adding current user to Docker group..."
    sudo usermod -aG docker ${USER}
    echo "Please log out and back in to apply group changes, or run 'su - ${USER}'"

    # Step 9: Test Docker Installation
    echo "Testing Docker installation with hello-world container..."
    docker run hello-world
else
    echo "Docker is already installed. Skipping installation..."
fi


# Check if libc6 is installed
if ! dpkg -l libc6 &> /dev/null
then
    # Install libc6 with -yq flag
    echo "Installing libc6..."
    sudo apt install -yq libc6
else
    echo "libc6 is already installed. Skipping installation..."
fi

# Always execute file download
echo "Downloading PINGPONG file..."
curl -L https://pingpong-build.s3.ap-southeast-1.amazonaws.com/linux/latest/PINGPONG -o PINGPONG
echo "File download completed successfully!"

# Make PINGPONG executable
echo "Making PINGPONG executable..."
chmod +x ./PINGPONG
  # .env file in the current working directory

# Check if the .env file exists, create it if not
if [ ! -f "$ENV_FILE" ]; then
    touch "$ENV_FILE"
    echo "Creating .env file: $ENV_FILE"
fi

# Ask for the device ID if not already set in the .env file
if ! grep -q "^Device_ID=" "$ENV_FILE"; then
    echo "Please enter your device ID:"
    read device_id
    echo "Device_ID=$device_id" >> "$ENV_FILE"
    echo "Device ID stored in $ENV_FILE"
fi


# Check if the .env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: Environment file not found: $ENV_FILE"
    exit 1
fi

# Check if the PINGPONG executable exists
if [ ! -x "$PINGPONG_EXECUTABLE" ]; then
    echo "Error: PINGPONG executable not found or not executable: $PINGPONG_EXECUTABLE"
    exit 1
fi

# Create the service file
echo "Creating service file..."
cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=PINGPONG Service
After=network.target

[Service]
Type=simple
ExecStart=$PINGPONG_EXECUTABLE --key \$Device_ID
Restart=always
EnvironmentFile=$ENV_FILE

[Install]
WantedBy=multi-user.target
EOF

echo "Service file created: $SERVICE_FILE"

# Reload Systemd
echo "Reloading Systemd..."
sudo systemctl daemon-reload

# Enable and start the service
echo "Enabling and starting the service..."
sudo systemctl enable "$SERVICE_NAME.service"
sudo systemctl start "$SERVICE_NAME.service"


echo "Script completed!"
