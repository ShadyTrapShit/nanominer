#!/bin/bash

# Define file to store previous wallet addresses
wallet_file="wallet_addresses.txt"

# Update packages
echo "Updating packages..."
if ! pkg update -y; then
    echo "Failed to update packages. Please check your package manager."
    exit 1
fi

# Install necessary packages
echo "Installing necessary packages..."
if ! pkg install -y cmake git; then
    echo "Failed to install necessary packages."
    exit 1
fi

# Clone the repository and build the project if not already done
if [ ! -d "xmrig" ]; then
    echo "Cloning and building XMRig..."
    if ! git clone https://github.com/xmrig/xmrig.git; then
        echo "Failed to clone XMRig. Check your internet connection."
        exit 1
    fi
    cd xmrig || exit
    mkdir build && cd build || exit
    if ! cmake -DWITH_HWLOC=OFF .. && make; then
        echo "Failed to build XMRig. Check cmake and make installation."
        exit 1
    fi
else
    echo "XMRig already cloned and built."
    cd xmrig/build
    if ! make; then
        echo "Failed to build XMRig on subsequent attempt. Check cmake and make installation."
        exit 1
    fi
fi
cd ../.. # Navigate back after building or attempting to rebuild XMRig

# Assuming XMRig is located in 'xmrig/build'
xmrig_path="xmrig/build"

# Function to prompt for cryptocurrency and wallet address
prompt_for_details() {
    echo "Please choose a cryptocurrency: Bitcoin (B), Dogecoin (D), or Nano (N)."
    read -r choice
    case $choice in
        B|b) 
            crypto="BTC"
            tag=".unmineable_worker_orbbwutd"
            ;;
        D|d) 
            crypto="DOGE"
            tag=".unmineable_worker_khirdmkp"
            ;;
        N|n) 
            crypto="XNO"
            tag=".unmineable_worker_nkdrzce"
            ;;
        *) echo "Invalid choice, exiting."; exit 1;;
    esac
    echo "Please enter your wallet address for $crypto:"
    read -r wallet_address
    echo "${crypto}_address=$wallet_address" >> "$wallet_file"
    # Set final command based on cryptocurrency
    final_command="./xmrig -a rx -o stratum+ssl://rx.unmineable.com:443 -u $crypto:$wallet_address$tag -p x"
}

prompt_for_details

# Check if xmrig executable exists and is executable
if [ ! -x "$xmrig_path/xmrig" ]; then
    echo "XMRig executable not found or not executable. Please check the build."
    exit 1
fi

# Execute the mining command
echo "Starting mining with the following command:"
echo $final_command
(cd $xmrig_path && eval $final_command)