#!/bin/bash

# Define the DATA_DIR variable
DATA_DIR=${DATA_DIR:-/data} # Default value if not set

# Read the MODE environment variable
MODE=${MODE:-default}
MAX_PLAYERS=${MAX_PLAYERS:-100} # Default value if not set
FORWARDING_SECRET=${FORWARDING_SECRET:-default_secret} # Default value if not set

echo "Current MODE is: $MODE"

mkdir -p ${DATA_DIR}

# Function to download a file if it does not exist
download_if_not_exists() {
    local url=$1
    local file=$2

    # Extract the directory path from the file path
    local dir=$(dirname "$file")

    # Create the directory if it does not exist
    mkdir -p "$dir"

    if [[ ! -f "$file" ]]; then
        echo "Downloading $file..."
        curl -o "$file" "$url"
    else
        echo "$file already exists."
    fi
}

# Function to handle BUNGEECORD mode
function handle_bungeecord() {
    echo "Handling BUNGEECORD mode"

    # Use the new function to download
    download_if_not_exists "https://raw.githubusercontent.com/theSimpleCloud/minecraft-configs/main/bungeecord/config.yml" "${DATA_DIR}/config.yml"

    # Ensure yq is installed and available
    if ! command -v yq &> /dev/null; then
        echo "yq could not be found, please install it."
        exit 1
    fi

    # Edit the host field
    yq e '.listeners[0].host = "0.0.0.0:25565"' -i ${DATA_DIR}/config.yml

    # Set max_players to the value from MAX_PLAYERS environment variable
    yq e ".listeners[0].max_players = env(MAX_PLAYERS)" -i ${DATA_DIR}/config.yml

    cat ${DATA_DIR}/config.yml
}

# Function to handle VELOCITY mode
function handle_velocity() {
    echo "Handling VELOCITY mode"

    # Use the new function to download
    download_if_not_exists "https://raw.githubusercontent.com/theSimpleCloud/minecraft-configs/main/velocity/velocity.toml" "${DATA_DIR}/velocity.toml"

    # Ensure sed is available
    if ! command -v sed &> /dev/null; then
        echo "sed could not be found, please install it."
        exit 1
    fi

    # Export MAX_PLAYERS and FORWARDING_SECRET so they can be referenced directly
    export MAX_PLAYERS
    export FORWARDING_SECRET

    # Set bind to "0.0.0.0:25565"
    sed -i 's/^bind = .*/bind = "0.0.0.0:25565"/' "${DATA_DIR}/velocity.toml"

    # Set show-max-players to the value from MAX_PLAYERS environment variable
    sed -i "s/^show-max-players = .*/show-max-players = $MAX_PLAYERS/" "${DATA_DIR}/velocity.toml"

    # Set player-info-forwarding-mode to "modern"
    sed -i 's/^player-info-forwarding-mode = .*/player-info-forwarding-mode = "modern"/' "${DATA_DIR}/velocity.toml"

    # Set haproxy-protocol to true
    sed -i 's/^haproxy-protocol = .*/haproxy-protocol = true/' "${DATA_DIR}/velocity.toml"

    # Write the content of FORWARDING_SECRET to forwarding.secret file
    echo "$FORWARDING_SECRET" > "${DATA_DIR}/forwarding.secret"

    cat "${DATA_DIR}/velocity.toml"
    cat "${DATA_DIR}/forwarding.secret"
}


function handle_spigot() {
    echo "Handling spigot"

    # Use the new function to download
    download_if_not_exists "https://raw.githubusercontent.com/theSimpleCloud/minecraft-configs/main/spigot/server.properties" "${DATA_DIR}/server.properties"
    download_if_not_exists "https://raw.githubusercontent.com/theSimpleCloud/minecraft-configs/main/spigot/spigot.yml" "${DATA_DIR}/spigot.yml"

    # Edit server.properties
    sed -i 's/^server-ip=.*$/server-ip=0.0.0.0/' ${DATA_DIR}/server.properties
    sed -i "s/^max-players=.*$/max-players=$MAX_PLAYERS/" ${DATA_DIR}/server.properties
    sed -i 's/^server-port=.*$/server-port=25565/' ${DATA_DIR}/server.properties
    sed -i 's/^online-mode=.*$/online-mode=false/' ${DATA_DIR}/server.properties

    cat ${DATA_DIR}/server.properties
    cat ${DATA_DIR}/spigot.yml
}


# Function to handle SPIGOT_BUNGEECORD mode
function handle_spigot_bungeecord() {
    echo "Handling SPIGOT_BUNGEECORD mode"

    handle_spigot

    # Edit spigot.yml
    yq e '.settings.bungeecord = true' -i ${DATA_DIR}/spigot.yml

    cat ${DATA_DIR}/spigot.yml
}

# Function to handle PAPER_VELOCITY mode
function handle_paper_velocity() {
    handle_spigot

    echo "Handling PAPER_VELOCITY mode"

    # Use the new function to download
    download_if_not_exists "https://raw.githubusercontent.com/theSimpleCloud/minecraft-configs/main/paper/paper-global.yml" "${DATA_DIR}/config/paper-global.yml"

    export FORWARDING_SECRET

    # Edit paper-global.yml
    yq e '.proxies.velocity.enabled = true' -i ${DATA_DIR}/config/paper-global.yml
    yq e '.proxies.velocity.online-mode = true' -i ${DATA_DIR}/config/paper-global.yml
    yq e '.proxies.velocity.secret = env(FORWARDING_SECRET)' -i ${DATA_DIR}/config/paper-global.yml

    cat ${DATA_DIR}/config/paper-global.yml
}

# Main logic to call functions based on the MODE
case $MODE in
    BUNGEECORD)
        handle_bungeecord
        ;;
    VELOCITY)
        handle_velocity
        ;;
    PAPER_VELOCITY)
        handle_paper_velocity
        ;;
    SPIGOT_BUNGEECORD)
        handle_spigot_bungeecord
        ;;
    *)
        echo "Unknown mode: $MODE"
        exit 1
        ;;
esac
