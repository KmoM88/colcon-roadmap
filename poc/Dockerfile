FROM ros:jazzy-ros-core

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    python3-catkin-pkg-modules \
    python3-distlib \
    python3-editables \
    python3-empy \
    python3-hatchling \
    python3-packaging \
    python3-pip \
    python3-pytest \
    python3-pytest-cov \
    python3-setuptools \
    python3-venv \
    python3-wheel \
    python3-yaml \
    ros-jazzy-ament-copyright \
    ros-jazzy-ament-flake8 \
    ros-jazzy-ament-index-python \
    ros-jazzy-ament-pep257 \
    ros-jazzy-ament-xmllint \
    ros-jazzy-example-interfaces \
    ros-jazzy-geometry-msgs \
    ros-jazzy-ros2pkg \
    ros-jazzy-ros2run \
    && rm -rf /var/lib/apt/lists/*

# Create a virtual environment that inherits ROS 2 Jazzy system packages
# (rclpy, ament_*, hatchling, editables, setuptools, pytest) while isolating
# our modernized colcon-core (#750 + #751) and colcon-ros (#171) stack.
RUN python3 -m venv --system-site-packages /opt/colcon-venv \
    && /opt/colcon-venv/bin/pip install --no-cache-dir \
        "catkin_pkg>=0.4.14" \
        "flit_core>=3.4,<4" \
        pytest-repeat \
        pytest-rerunfailures \
    && /opt/colcon-venv/bin/pip install --no-cache-dir --no-deps \
        colcon-pkg-config

COPY submodules/kmom88-colcon-core /opt/colcon-src/kmom88-colcon-core
COPY submodules/colcon-library-path /opt/colcon-src/colcon-library-path
COPY submodules/colcon-test-result /opt/colcon-src/colcon-test-result
COPY submodules/colcon-cmake /opt/colcon-src/colcon-cmake
COPY submodules/colcon-python-setup-py /opt/colcon-src/colcon-python-setup-py
COPY submodules/colcon-package-selection /opt/colcon-src/colcon-package-selection
COPY submodules/colcon-package-information /opt/colcon-src/colcon-package-information
COPY submodules/colcon-recursive-crawl /opt/colcon-src/colcon-recursive-crawl
COPY submodules/colcon-output /opt/colcon-src/colcon-output
COPY submodules/colcon-parallel-executor /opt/colcon-src/colcon-parallel-executor
COPY submodules/colcon-defaults /opt/colcon-src/colcon-defaults
COPY submodules/colcon-metadata /opt/colcon-src/colcon-metadata
COPY submodules/colcon-bash /opt/colcon-src/colcon-bash
COPY submodules/colcon-ros /opt/colcon-src/colcon-ros

RUN /opt/colcon-venv/bin/pip install --no-cache-dir --no-build-isolation --no-deps \
        /opt/colcon-src/kmom88-colcon-core \
        /opt/colcon-src/colcon-library-path \
        /opt/colcon-src/colcon-test-result \
        /opt/colcon-src/colcon-cmake \
        /opt/colcon-src/colcon-python-setup-py \
        /opt/colcon-src/colcon-package-selection \
        /opt/colcon-src/colcon-package-information \
        /opt/colcon-src/colcon-recursive-crawl \
        /opt/colcon-src/colcon-output \
        /opt/colcon-src/colcon-parallel-executor \
        /opt/colcon-src/colcon-defaults \
        /opt/colcon-src/colcon-metadata \
        /opt/colcon-src/colcon-bash \
        /opt/colcon-src/colcon-ros \
    && /opt/colcon-venv/bin/pip check

ENV PATH="/opt/colcon-venv/bin:${PATH}"

COPY poc/container_poc.sh /usr/local/bin/container_poc.sh
RUN chmod +x /usr/local/bin/container_poc.sh

WORKDIR /poc_work
ENTRYPOINT ["/usr/local/bin/container_poc.sh"]
CMD ["--target", "demo_nodes_py"]
