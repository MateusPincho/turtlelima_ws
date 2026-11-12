#!/usr/bin/env bash
set -e

if [ -f "/opt/ros/${ROS_DISTRO}/setup.bash" ]; then
  source "/opt/ros/${ROS_DISTRO}/setup.bash"
fi

if [ -f "/turtlelima/install/setup.bash" ]; then
  source "/turtlelima/install/setup.bash"
elif [ -f "/opt/turtlelima/install/setup.bash" ]; then
  source "/opt/turtlelima/install/setup.bash"
fi

exec "$@"