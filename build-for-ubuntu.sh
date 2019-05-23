#!/bin/bash
#Title       :build-for-ubuntu.sh
#Description :This script will use Docker to create an FFmpeg build which is compatible with Ubuntu 18.04.
#==============================================================================

set -e

rm -f ffmpeg
docker build -t exmg-lls .
docker run --name exmg-lls-container exmg-lls /bin/true
docker cp exmg-lls-container:/app/ffmpeg ffmpeg
docker rm exmg-lls-container