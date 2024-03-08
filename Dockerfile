FROM --platform=linux/amd64 ubuntu:latest

# Install build essentials and git
RUN apt-get update -y &&\
    apt-get install -y \
    build-essential \
    curl \
    git \
    wget \
    jq \
    gzip \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Install the latest version of Golang by downloading from the official source
ENV PATH=/usr/local/go/bin:$PATH

RUN set -ex;\
    GOLANG_VERSION=$(curl -s https://go.dev/dl/?mode=json | jq -r '[.[] | select(.files[].os == "linux" and .files[].arch == "amd64")][0].version');\
    curl -sSL "https://go.dev/dl/${GOLANG_VERSION}.linux-amd64.tar.gz" | tar -C /usr/local -xz;\
    # Verify the installation
    go version

# install cmake
RUN wget -q "https://github.com/Kitware/CMake/releases/download/v3.28.3/cmake-3.28.3-linux-x86_64.sh" -O cmake-install.sh && \
    chmod +x cmake-install.sh && \
    ./cmake-install.sh --skip-license --prefix=/usr/local && \
    rm cmake-install.sh


# Create a user 'duck' with sudo access and no password for sudo
RUN useradd -m duck && \
    echo "duck ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/duck && \
    chmod 0440 /etc/sudoers.d/duck


WORKDIR /tmp

RUN set -ex;\
    VSCODE_VERSION=2ccd690cbff1569e4a83d7c43d45101f817401dc;\
    vscode_dir="~/.vscode-server/bin/${VSCODE_VERSION}";\
    archive="vscode-server-linux-x64.tar.gz";\
    curl -L "https://update.code.visualstudio.com/commit:${VSCODE_VERSION}/server-linux-x64/stable" -o "vscode-server-linux-x64.tar.gz";\
    mkdir -vp "$vscode_dir";\
    tar --no-same-owner -xz --strip-components=1 -C "$vscode_dir" -f "/tmp/${archive}";\
    $vscode_dir/bin/code-server --version;\
    $vscode_dir/bin/code-server --install-extension ms-python.python;\
    $vscode_dir/bin/code-server --install-extension ms-vscode.cpptools;\
    $vscode_dir/bin/code-server --install-extension ms-vscode.cmake-tools;\
    $vscode_dir/bin/code-server --install-extension golang.go;\
    $vscode_dir/bin/code-server --install-extension github.copilot;\
    $vscode_dir/bin/code-server --install-extension github.copilot-chat;\
    $vscode_dir/bin/code-server --install-extension visualstudioexptteam.vscodeintellicode;\
    $vscode_dir/bin/code-server --install-extension visualstudioexptteam.intellicode-api-usage-examples;\
    $vscode_dir/bin/code-server --install-extension twxs.cmake;\
    rm -rd "$vscode_dir";\
    rm "/tmp/${archive}"


USER duck

# Set the work directory
WORKDIR /home/duck


CMD ["/bin/bash"]
