ARG ROS_DISTRO=jazzy

FROM ros:${ROS_DISTRO}-ros-base
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
      vim \
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

WORKDIR /turtlima
COPY requirements.txt ./requirements.txt
RUN pip3 install --no-cache-dir --ignore-installed -r requirements.txt \
    --extra-index-url https://download.pytorch.org/whl/cu129 \
    --break-system-packages

ARG ROS_DISTRO
COPY . /turtlima
RUN mkdir -p src && vcs import src < dependencies.repos
RUN apt-get update && \
    rosdep update && \
    rosdep install --from-paths src --ignore-src -r -y --rosdistro ${ROS_DISTRO} && \
    rm -rf /var/lib/apt/lists/*
RUN source /opt/ros/${ROS_DISTRO}/setup.bash && colcon build --merge-install --symlink-install

COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
RUN echo 'source /opt/ros/${ROS_DISTRO}/setup.bash' >> ~/.bashrc && \
    echo '[ -f /turtlima/install/setup.sh ] && source /turtlima/install/setup.sh' >> ~/.bashrc
ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
