# Dockerfile for development with Nix support
FROM mcr.microsoft.com/devcontainers/base:alpine

# Install system dependencies (Alpine-specific)
RUN apk add --no-cache \
    ca-certificates \
    curl \
    git \
    wget \
    xz \
    bash \
    sudo

# Ensure codespace user exists (created by base image)
# If not, create it manually
RUN if ! id -u codespace > /dev/null 2>&1; then \
    addgroup -g 1000 codespace && \
    adduser -u 1000 -G codespace -s /bin/bash -D codespace && \
    echo 'codespace ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers; \
    fi

# Switch to codespace user
USER codespace
WORKDIR /home/codespace

# Install Nix using the official installer
RUN curl -L https://nixos.org/nix/install -o /tmp/install-nix.sh && \
    chmod +x /tmp/install-nix.sh && \
    /tmp/install-nix.sh --no-daemon && \
    rm /tmp/install-nix.sh

# Source nix profile in bashrc
RUN echo '. $HOME/.nix-profile/etc/profile.d/nix.sh' >> $HOME/.bashrc

# Enable experimental features for flakes
RUN mkdir -p ~/.config/nix && \
    echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf

# Set environment variables
ENV PATH="/home/codespace/.nix-profile/bin:${PATH}"
ENV NIX_PATH="/home/codespace/.nix-defexpr/channels:/nix/var/nix/gcroots/per-user/codespace/channels"
