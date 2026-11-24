# RealSense D415 with TurtleLima

Summary 

---

## How to install RealSense ROS2 Wrapper

The TurtleLima robot has a NVIDIA Jetson Orin Nano inside it. For installing and preparing the RealSense for usage, the first step is to install the RealSense 2.0 SDK. we will follow the [Jetson Installation Guide](https://github.com/realsenseai/librealsense/blob/master/doc/installation_jetson.md) for completing this task. 

### Installing librealsense SDK via Debian Packages

This part you must execute in the host PC (Jetson). Ensure that you registered the server's public key:

```
# Ensure the directory exists
sudo mkdir -p /etc/apt/keyrings

# Download and dearmor
curl -sSf https://librealsense.realsenseai.com/Debian/librealsenseai.asc | \
gpg --dearmor | sudo tee /etc/apt/keyrings/librealsenseai.gpg > /dev/null
```
Note: The keyring contains both the new RS public key and the Intel public key for old repos, ensuring compatibility with both new and existing packages.

- Make sure apt HTTPS support is installed:
`sudo apt-get install apt-transport-https`

- Add the server to the list of repositories:
```
echo "deb [signed-by=/etc/apt/keyrings/librealsenseai.gpg] https://librealsense.realsenseai.com/Debian/apt-repo `lsb_release -cs` main" | \
sudo tee /etc/apt/sources.list.d/librealsense.list
sudo apt-get update
```

After that, install the librealsense package

```
sudo apt-get install librealsense2-utils
sudo apt-get install librealsense2-dev
```

### Installing ROS2 Wrapper

The wrapper package is `realsense2_camera` — note there is no `lib` prefix. These 
packages are already baked into the `base` stage of `docker/Dockerfile`.

To add them to a container by hand:

```bash
sudo apt update
sudo apt install -y \
  ros-jazzy-realsense2-camera \
  ros-jazzy-realsense2-camera-msgs \
  ros-jazzy-realsense2-description
```

Verify inside the container:

```bash
source /opt/ros/jazzy/setup.bash
ros2 pkg prefix realsense2_camera   # -> /opt/ros/jazzy
```

## Using RealSense D415 with ROS2

### Setting stream profiles

A profile is a string `<width>x<height>x<fps>`, set per stream:

| Parameter | Stream |
| --- | --- |
| `rgb_camera.color_profile` | color |
| `depth_module.depth_profile` | depth |
| `depth_module.infra_profile` | infra1 / infra2 (shared) |

Pixel format is a separate parameter, not part of the profile string:
`rgb_camera.color_format`, `depth_module.depth_format`, `depth_module.infra1_format`.

```bash
ros2 launch realsense2_camera rs_launch.py \
  rgb_camera.color_profile:=1280x720x30 \
  depth_module.depth_profile:=848x480x30 \
  depth_module.infra_profile:=848x480x30
```

Note: wrapper versions before ~4.55 used `depth_module.profile` and `rgb_camera.profile`.
We are on 4.59.1, so use the `depth_profile` / `color_profile` names. Older examples
found online (including the "launch params from file" page on dev.intelrealsense.com)
use the stale names.

### Checking supported profiles

An unsupported profile does **not** raise an error. The stream fails to open, a warning
is logged, and the default configuration is used instead — which is easy to mistake for
the parameter being ignored. Always confirm what you actually got.

```bash
# every launch argument for the installed version
ros2 launch realsense2_camera rs_launch.py -s

# supported values, queried from the running node
ros2 param describe /camera/camera depth_module.depth_profile

# supported values, straight from the SDK
rs-enumerate-devices

# what the node actually negotiated
ros2 topic echo /camera/camera/color/camera_info --once | grep -E 'width|height'
```

The node is `/camera/camera` by default; it moves if `camera_name` or `camera_namespace`
is set. Check with `ros2 node list`.

On the D415, depth maxes out at 1280x720x30 while color reaches 1920x1080x30, so the
highest depth and colour settings are not a valid combination.

### Other useful launch arguments

```bash
enable_color:=true          enable_depth:=true
enable_infra1:=false        enable_infra2:=false
pointcloud.enable:=true     align_depth.enable:=true
```

