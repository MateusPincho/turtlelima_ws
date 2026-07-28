#!/usr/bin/env bash
set -e

if [ -f "/opt/ros/${ROS_DISTRO}/setup.bash" ]; then
  source "/opt/ros/${ROS_DISTRO}/setup.bash"
fi

if [ -f "/turtlima/install/setup.bash" ]; then
  source "/turtlima/install/setup.bash"
fi

exec "$@"
