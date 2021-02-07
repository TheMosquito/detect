#!/bin/bash

# Defaults
if [ -z "${CAM_DEVICE:-}" ]; then CAM_DEVICE="V4L2:/dev/video0"; fi
if [ -z "${CAM_DELAY_SEC:-}" ]; then CAM_DELAY_SEC=0; fi
if [ -z "${CAM_OUT_WIDTH:-}" ]; then CAM_OUT_WIDTH=640; fi
if [ -z "${CAM_OUT_HEIGHT:-}" ]; then CAM_OUT_HEIGHT=480; fi

# Jsonify the settings
SETTINGS="{ \"device\":\"${CAM_DEVICE}\", \"delay\":\"${CAM_DELAY_SEC}\", \"width\":${CAM_OUT_WIDTH}, \"height\":${CAM_OUT_HEIGHT}, \"type\":\"jpg\", \"encoding\":\"base64\" }"

# Files (@@@ these should all be just in RAM)
MOCK="/mock.jpg"
JPG="/tmp/cam.jpg"
RTN_JSON="/tmp/rtn.json"
SCALE="${CAM_OUT_WIDTH}x${CAM_OUT_HEIGHT}"

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

# Use watchdog to publish encoded image to MQTT (qos=0, fire and forget)
RESPONSE="{ \"live\":${LIVE}, \"settings\":${SETTINGS}, \"image\":\"${IMAGE}\" }" > "${RTN_JSON}"

# Construct the HTTP response message
HEADERS="Content-Type: text/html; charset=ISO-8859-1"
BODY="{\"cam\":${RESPONSE}}"
HTTP="HTTP/1.1 200 OK\r\n${HEADERS}\r\n\r\n${BODY}\r\n"

# Emit the HTTP response
echo -en $HTTP
