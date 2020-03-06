#!/bin/bash

# Defaults
if [ -z "${YOLO_DEVICENAME:-}" ]; then YOLO_DEVICENAME=""; fi
if [ -z "${YOLO_ENTITY:-}" ]; then YOLO_ENTITY="person"; fi
if [ -z "${YOLO_PERIOD:-}" ]; then YOLO_PERIOD=5; fi
if [ -z "${YOLO_IN_TOPIC:-}" ]; then YOLO_IN_TOPIC="/cam"; fi
if [ -z "${YOLO_OUT_TOPIC:-}" ]; then YOLO_OUT_TOPIC="/detect"; fi

# Consts
MQTT_SUB_COMMAND='mosquitto_sub -h mqtt -p 1883 '
MQTT_PUB_COMMAND='mosquitto_pub -h mqtt -p 1883 '
IN_JPG="/tmp/in.jpg"
OUT_JPG="/darknet/predictions.jpg"
OUT_DATA="/tmp/out.txt"
RTN_JPG="/tmp/return.jpg"
RTN_JSON="/tmp/return.json"

cd /darknet
while true; do

  # Start fresh (remove any existing artifacts)
  rm -f "${IN_JPG}" "${OUT_JPG}" "${OUT_DATA}" "${RTN_JPG}" "${RTN_JSON}" 

  # Using the watchdog, pull image from mqtt (-C 1 means pull only one message)
  JSON=$(/watchdog.sh ${MQTT_SUB_COMMAND} -C 1 -t ${YOLO_IN_TOPIC})
  if [ "" != "${JSON}" ]; then
    SETTINGS=$(echo "${JSON}" | jq ".cam.settings")
    WIDTH=$(echo "${SETTINGS}" | jq ".width")
    HEIGHT=$(echo "${SETTINGS}" | jq ".height")
    IN_IMAGE_B64=$(echo "${JSON}" | jq --raw-output --join-output ".cam.image")
    $(echo -n "${IN_IMAGE_B64}" | base64 -d > "${IN_JPG}")

    # Identify from tiny set
#    /darknet/darknet detector test cfg/voc.data cfg/yolov2-tiny-voc.cfg yolov2-tiny-voc.weights "${IN_JPG}" > "${OUT_DATA}" 2>/dev/null
    /darknet/darknet detect cfg/yolov3-tiny.cfg yolov3-tiny.weights "${IN_JPG}" > "${OUT_DATA}" 2>/dev/null
#    /darknet/darknet detect cfg/yolov3.cfg yolov3.weights "${IN_JPG}" > "${OUT_DATA}" 2>/dev/null

    # Retain the annotated image
    cp "${OUT_JPG}" "${RTN_JPG}"

    # Extract processing time in seconds
    TIME=$(cat "${OUT_DATA}" | egrep "Predicted" | sed 's/.*Predicted in \([^ ]*\).*/\1/')
    # Zero indicates failure
    if [ -z "${TIME}" ]; then
      TIME=0;
      echo "Detection failed."
    fi

    # Count specified entity
    COUNT=$(egrep '^'"${YOLO_ENTITY}" "${OUT_DATA}" | wc -l)

    # Base64-encode the annotated image
    OUT_IMAGE_B64=$(base64 -w 0 -i "${OUT_JPG}")

    # Publish the encoded images to the MQTT broker (qos=0, fire and forget)
    echo -n "{ \"detect\": { \"devicename\":\"${YOLO_DEVICENAME}\", \"tool\":\"yologpu\", \"date\":\"$(date +%s)\", \"time\":\"${TIME}\", \"entity\":\"${YOLO_ENTITY}\", \"count\":${COUNT}, " > "${RTN_JSON}"
    echo -n "\"source\":\"${IN_IMAGE_B64}\", " >> "${RTN_JSON}"
    echo "\"image\":\"${OUT_IMAGE_B64}\" } }" >> "${RTN_JSON}"
    ${MQTT_PUB_COMMAND} --qos 0 -t ${YOLO_OUT_TOPIC} -f "${RTN_JSON}"

 fi

 # Pause for some number of seconds before going again
  sleep "${YOLO_PERIOD}"
done
