#!/bin/bash

# --- Windows OpenSSL Detection and PATH Setup ---

# Function to check if an openssl executable is functional
is_openssl_functional() {
    local openssl_cmd="$1"
    if [ -z "$openssl_cmd" ]; then
        return 1 # No command provided
    fi
    # Check if it exists and responds correctly to --help
    if command -v "$openssl_cmd" &>/dev/null && "$openssl_cmd" --help &> /dev/null; then
        return 0 # Functional
    else
        return 1 # Not functional or not found
    fi
}

OPENSSL_CMD="openssl" # Default command name
FOUND_FUNCTIONAL_OPENSSL=false

# 1. Check if the default 'openssl' in PATH is functional
if is_openssl_functional "$OPENSSL_CMD"; then
    echo "Found functional OpenSSL in existing PATH: $(command -v $OPENSSL_CMD)"
    FOUND_FUNCTIONAL_OPENSSL=true
else
    echo "Default OpenSSL in PATH is not functional or not found. Checking specific Windows paths..."
    # 2. Check common Windows installation paths
    declare -a potential_paths=(
        "/c/Program Files/OpenSSL-Win64/bin"
        "/c/Program Files (x86)/OpenSSL-Win64/bin"
        # Add other potential paths here if needed
    )

    for p_path in "${potential_paths[@]}"; do
        if [ -d "$p_path" ]; then # Check if directory exists
            potential_cmd="$p_path/openssl.exe"
            if is_openssl_functional "$potential_cmd"; then
                echo "Found functional OpenSSL at: $p_path"
                # Prepend the found path so it's used first
                export PATH="$p_path:$PATH"
                OPENSSL_CMD="$potential_cmd" # Use the full path if needed, though PATH should suffice
                FOUND_FUNCTIONAL_OPENSSL=true
                break # Found it, no need to check further
            fi
        fi
    done
fi

# 3. Final check and error if still not functional
if ! $FOUND_FUNCTIONAL_OPENSSL; then
    echo -e "${RED}----------------------------------------------------------------------${NC}"
    echo -e "${RED}ERROR: Could not find or execute a functional OpenSSL installation.${NC}"
    echo -e "${YELLOW}Checked standard PATH and common locations like '/c/Program Files/OpenSSL-Win64/bin'.${NC}"
    echo -e "${YELLOW}Please ensure you have installed the full (non-light) version of OpenSSL"
    echo -e "for Windows and that its 'bin' directory is added to your system's PATH"
    echo -e "environment variable.${NC}"
    echo -e "${YELLOW}See detailed instructions in: WINDOWS_Env.sh.md${NC}"
    echo -e "${RED}----------------------------------------------------------------------${NC}"
    exit 1
fi

# --- End Windows OpenSSL Detection ---

# Define color codes
if command -v tput >/dev/null && [ -t 1 ]; then
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    NC=$(tput sgr0) # No Color
else
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
fi

dotenv_replace() {
    local env_var_name=$1
    local new_value=$2
    local file_path=$3
    local sed_option=""

    # Check if running on macOS and adjust sed_option accordingly
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed_option="-i ''"
    else
        sed_option="-i"
    fi

    # Use eval to correctly handle the dynamic insertion of the sed option
    delimiter="#"
    eval sed $sed_option "s$delimiter^${env_var_name}=.*$delimiter${env_var_name}=${new_value}$delimiter" $file_path
}

echo -e "${YELLOW}Creating .env...${NC}"

# Check that docker exists and is running
if !  docker ps &> /dev/null
then
    echo -e "${RED}Docker could not be found. Please check if installed and running.${NC}"
    exit
fi

# If .env exists, ask user if they want to overwrite it
if [ -f .env ]; then
    read -p "A .env file already exists. Do you want to overwrite it? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Exiting...${NC}"
        exit 0
    fi
fi

# Create .env file

if [ ! -e ".env.example" ] ; then
  echo "${RED}No .env.example file found in current directory: $(pwd). Please download .env.example from the Tracecat GitHub repo and rerun the env.sh script."
  exit 1
fi
env_file=".env"

# Check if openssl command is now functional
if ! openssl --help &> /dev/null
then
  echo -e "${RED}----------------------------------------------------------------------${NC}"
  echo -e "${RED}ERROR: Could not find or execute a functional OpenSSL installation.${NC}"
  echo -e "${YELLOW}Please ensure you have installed the full (non-light) version of OpenSSL"
  echo -e "for Windows and that its 'bin' directory is added to your system's PATH"
  echo -e "environment variable.${NC}"
  echo -e "${YELLOW}See detailed instructions in: WINDOWS_Env.sh.md${NC}"
  echo -e "${RED}----------------------------------------------------------------------${NC}"
  exit 1
fi

echo -e "${YELLOW}Generating new service key and signing secret...${NC}"

service_key=$(openssl rand -hex 32)
signing_secret=$(openssl rand -hex 32)


echo -e "${YELLOW}Generating a Fernet encryption key for the database...${NC}"
db_fernet_key=$(docker run --rm python:3.12-slim-bookworm /bin/sh -c "\
    pip install cryptography >/dev/null 2>&1 && \
    python -c 'from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())'")

echo -e "${YELLOW}Creating new .env from .env.example...${NC}"
cp .env.example .env

# Replace existing values of TRACECAT__SERVICE_KEY and TRACECAT__SIGNING_SECRET
dotenv_replace "TRACECAT__SERVICE_KEY" "$service_key" "$env_file"
dotenv_replace "TRACECAT__SIGNING_SECRET" "$signing_secret" "$env_file"
dotenv_replace "TRACECAT__DB_ENCRYPTION_KEY" "$db_fernet_key" "$env_file"


# Prompt user for environment mode
while true; do
    read -p "Use production mode? (y/n, default: y): " prod_mode
    prod_mode=${prod_mode:-y}
    case $prod_mode in
        [Yy]* )
            env_mode="production"
            break
            ;;
        [Nn]* )
            env_mode="development"
            break
            ;;
        * ) echo -e "${RED}Please answer y or n.${NC}";;
    esac
done

# Prompt user for new IP address and strip http:// or https://

while true; do
    read -p "Set \`PUBLIC_APP_URL\` environment variable to (default: localhost): " new_ip
    new_ip=$(sed -E 's/^\s*.*:\/\///g' <<< $new_ip)
    new_ip=${new_ip:-localhost}

    if [ "$new_ip" != "0.0.0.0" ]; then
        break
    fi
    echo -e "${RED}Cannot use 0.0.0.0 as address.\nSee https://docs.tracecat.com/self-hosting/deployment-options/docker-compose#download-configuration-files ${NC}"
done


# Prompt user for PostgreSQL SSL mode
while true; do
    read -p "Require PostgreSQL SSL mode? (y/n, default: n): " postgres_ssl
    postgres_ssl=${postgres_ssl:-n}
    case $postgres_ssl in
        [Yy]* )
            ssl_mode="require"
            break
            ;;
        [Nn]* )
            ssl_mode="disable"
            break
            ;;
        * ) echo -e "${RED}Please answer y or n.${NC}";;
    esac
done

# Update environment variables
dotenv_replace "TRACECAT__APP_ENV" "$env_mode" "$env_file"
dotenv_replace "NODE_ENV" "$env_mode" "$env_file"
dotenv_replace "NEXT_PUBLIC_APP_ENV" "$env_mode" "$env_file"
dotenv_replace "PUBLIC_API_URL" "http://${new_ip}/api/" "$env_file"
dotenv_replace "PUBLIC_APP_URL" "http://${new_ip}" "$env_file"
dotenv_replace "TRACECAT__DB_SSLMODE" "$ssl_mode" "$env_file"

# Remove duplicate entries and leading/trailing commas
new_origins=$(echo "$new_origins" | tr ',' '\n' | sort -u | tr '\n' ',' | sed 's/^,//;s/,$//')
dotenv_replace "TRACECAT__ALLOW_ORIGINS" "$new_origins" "$env_file"

echo -e "${GREEN}Environment file created successfully.${NC}"
