#!/bin/bash

# Defaults
if [ -z "${CAM_DEVICE:-}" ]; then CAM_DEVICE="V4L2:/dev/video0"; fi
if [ -z "${CAM_DELAY_SEC:-}" ]; then CAM_DELAY_SEC=0; fi
if [ -z "${CAM_OUT_WIDTH:-}" ]; then CAM_OUT_WIDTH=320; fi
if [ -z "${CAM_OUT_HEIGHT:-}" ]; then CAM_OUT_HEIGHT=240; fi
if [ -z "${CAM_PAUSE_SEC:-}" ]; then CAM_PAUSE_SEC=5; fi
if [ -z "${CAM_TOPIC:-}" ]; then CAM_TOPIC="/cam"; fi

# Log the settings
SETTINGS="{ \"device\":\"${CAM_DEVICE}\", \"delay\":\"${CAM_DELAY_SEC}\", \"pause\":\"${CAM_PAUSE_SEC}\", \"width\":${CAM_OUT_WIDTH}, \"height\":${CAM_OUT_HEIGHT}, \"topic\":\"${CAM_TOPIC}\", \"type\":\"jpg\", \"encoding\":\"base64\" }"
echo "${SETTINGS}"

MOCK="/mock.jpg"
JPG="/tmp/cam.jpg"
SCALE="${CAM_OUT_WIDTH}x${CAM_OUT_HEIGHT}"

# Loop forever...
while true; do

  # Remove any existing image
  rm -f "${JPG}"

  # Capture image from /dev/video0 and grab file attributes for later use
  fswebcam --device "${CAM_DEVICE}" --delay "${CAM_DELAY_SEC}" --scale "${SCALE}" --no-banner "${JPG}" 2>/dev/null

  # test image
  if [ ! -s "${JPG}" ]; then
    cp "${MOCK}" "${JPG}"
    LIVE=false
  else
    LIVE=true
  fi

  # BASE64 encode the image (live or mock.jpg)
  IMAGE=$(base64 -w 0 -i "${JPG}")

  # Publish the encoded image to the MQTT broker (qos=0, fire and forget)
  # echo "mosquitto_pub -h mqtt -p 1883 -t ${CAM_TOPIC} --qos 0 -m \"{\"cam\":{ \"live\":${LIVE}, \"settings\":${SETTINGS}, \"image\":\"${IMAGE}\" } }\""
  mosquitto_pub -h mqtt -p 1883 -t ${CAM_TOPIC} --qos 0 -m "{\"cam\":{ \"live\":${LIVE}, \"settings\":${SETTINGS}, \"image\":\"${IMAGE}\" } }"

  # Pause for some number of seconds before going again
  sleep ${CAM_PAUSE_SEC}

done

