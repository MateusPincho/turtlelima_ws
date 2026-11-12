ARG ROS_DISTRO=jazzy
ARG TARGET_PLATFORM=arm

FROM ros:${ROS_DISTRO}-ros-base AS base
ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      bash-completion \
      build-essential \
      cmake \
      curl \
      git \
      iproute2 \
      less \
      locales \
      openssh-client \
      python3-argcomplete \
      python3-colcon-common-extensions \
      python3-pip \
      python3-rosdep \
      python3-vcstool \
      libusb-1.0-0-dev \
      sudo \
      nano \
      fzf \
      tree \
      psmisc \
      wget && \
    rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# Prime rosdep so both builder and interactive shells work.
RUN rosdep init 2>/dev/null || true && rosdep update

WORKDIR /turtlelima
COPY requirements.txt ./requirements.txt
RUN pip3 install --no-cache-dir --ignore-installed -r requirements.txt --break-system-packages

# -----------------------------------------------------------------------------

FROM base AS builder
ARG ROS_DISTRO
WORKDIR /turtlelima

COPY . /turtlelima
# src/ is empty until the first package lands; keep rosdep/colcon happy either way.
RUN mkdir -p src
RUN apt-get update
RUN rosdep update && \
    rosdep install --from-paths src --ignore-src -r -y --rosdistro ${ROS_DISTRO} && \
    rm -rf /var/lib/apt/lists/*
RUN source /opt/ros/${ROS_DISTRO}/setup.bash && \
    colcon build --merge-install --symlink-install --cmake-args -DBUILD_TESTING=OFF && \
    mkdir -p /turtlelima/install

# -----------------------------------------------------------------------------

FROM builder AS dev
WORKDIR /turtlelima
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
RUN echo 'source /opt/ros/${ROS_DISTRO}/setup.bash' >> ~/.bashrc && \
echo '[ -f /turtlelima/install/setup.sh ] && source /turtlelima/install/setup.sh' >> ~/.bashrc

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]

# -----------------------------------------------------------------------------

FROM dev AS dev-gpu

RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates

# -----------------------------------------------------------------------------

FROM dev-gpu AS dev-gpu-arm

ARG CUDA_REPO=https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/sbsa
ARG ORT_INDEX_URL=https://pypi.jetson-ai-lab.io/sbsa/cu130
ARG ORT_VERSION=1.24.0
ARG TRT_VERSION=10.16.1.11-1+cuda13.2

RUN curl -fsSL ${CUDA_REPO}/cuda-keyring_1.1-1_all.deb -o /tmp/cuda-keyring.deb && \
dpkg -i /tmp/cuda-keyring.deb && rm /tmp/cuda-keyring.deb && \
apt-get update && apt-get install -y --no-install-recommends \
cuda-libraries-13-0 \
libcudnn9-cuda-13 \
libnvinfer10=${TRT_VERSION} \
libnvinfer-plugin10=${TRT_VERSION} \
libnvonnxparsers10=${TRT_VERSION} \
python3-libnvinfer=${TRT_VERSION} && \
rm -rf /var/lib/apt/lists/*

RUN pip3 uninstall -y --break-system-packages onnxruntime && \
pip3 install --no-cache-dir --break-system-packages \
--index-url ${ORT_INDEX_URL} onnxruntime-gpu==${ORT_VERSION}

# -----------------------------------------------------------------------------

FROM dev-gpu AS dev-gpu-x86

ARG CUDA_REPO=https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64
ARG ORT_VERSION=1.24.1
ARG TRT_VERSION=10.16.1.11-1+cuda12.9

RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates && \
curl -fsSL ${CUDA_REPO}/cuda-keyring_1.1-1_all.deb -o /tmp/cuda-keyring.deb && \
dpkg -i /tmp/cuda-keyring.deb && rm /tmp/cuda-keyring.deb && \
apt-get update && apt-get install -y --no-install-recommends \
cuda-libraries-12-9 \
libcudnn9-cuda-12 \
libnvinfer10=${TRT_VERSION} \
libnvinfer-plugin10=${TRT_VERSION} \
libnvinfer-vc-plugin10=${TRT_VERSION} \
libnvonnxparsers10=${TRT_VERSION} \
python3-libnvinfer=${TRT_VERSION} && \
rm -rf /var/lib/apt/lists/*

RUN pip3 uninstall -y --break-system-packages onnxruntime && \
pip3 install --no-cache-dir --break-system-packages \
onnxruntime-gpu==${ORT_VERSION}

# -----------------------------------------------------------------------------

FROM ros:${ROS_DISTRO}-ros-base AS runtime
SHELL ["/bin/bash", "-c"]
ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8
COPY --from=builder /turtlelima/install /opt/turtlelima/install
COPY --chmod=755 docker/entrypoint.sh /entrypoint.sh
WORKDIR /opt/turtlelima
ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]