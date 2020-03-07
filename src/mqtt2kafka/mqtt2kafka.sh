#!/bin/sh

# For development
if [ -z "${HZN_DEVICE_ID:-}" ]; then HZN_DEVICE_ID="unnamed"; fi
if [ -z "${MQTT_HOST:-}" ]; then MQTT_HOST=""; fi

# The command to subscribe and get one message from the local MQTT broker
MQTT_COMMAND="mosquitto_sub -h ${MQTT_HOST} -p 1883 -C 1 "

# Verify required environment variables are set
checkRequiredEnvVar() {
  varname=$1
  if [ -z $(eval echo \$$varname) ]; then
    echo "Error: Environment variable $varname must be set; exiting."
    exit 2
  else
    echo "  $varname="$(eval echo \$$varname)
  fi
}

# Check the exit status of the previously run command and exit if nonzero (unless 'continue' is passed in)
checkrc() {
  if [[ $1 -ne 0 ]]; then
    echo "Error: exit code $1 from $2"
    # Sometimes it is useful to not exit on error, because if you do the container restarts so quickly it is hard to get in it a debug
    if [[ "$3" != "continue" ]]; then
      exit $1
    fi
  fi
}

echo "Checking environment variables required to publish to IBM Event Streams:"
checkRequiredEnvVar "MQTT_TOPIC"
checkRequiredEnvVar "EVTSTREAMS_TOPIC"
checkRequiredEnvVar "EVTSTREAMS_API_KEY"
checkRequiredEnvVar "EVTSTREAMS_BROKER_URL"
#EVTSTREAMS_USERNAME="${EVTSTREAMS_API_KEY:0:16}"
#EVTSTREAMS_PASSWORD="${EVTSTREAMS_API_KEY:16}"
EVTSTREAMS_USERNAME="token"
EVTSTREAMS_PASSWORD="${EVTSTREAMS_API_KEY}"

# The only special chars allowed in the topic are: -._
EVTSTREAMS_TOPIC="${EVTSTREAMS_TOPIC//[@#%()+=:,<>]/_}"
# Translating slashes doesn't work in this bash substitute in alpine, so use tr
EVTSTREAMS_TOPIC=$(echo "$EVTSTREAMS_TOPIC" | tr / _)
echo "Will publish to topic: $EVTSTREAMS_TOPIC"

echo 'Starting infinite loop to read from MQTT and publish to Kafka...'
while true; do

  # Pull data from MQTT
  IN_JSON=$(${MQTT_COMMAND} -t "${MQTT_TOPIC}")
  checkrc $? "mqtt" "continue"

  # Modify IN_JSON into OUT_JSON to work with the existing backend IBM function
  TMP_JSON=$(echo "${IN_JSON}" | sed 's/"detect":/"yolo":/')
  OUT_JSON="{\"hzn\":{\"device_id\":\"${HZN_DEVICE_ID}\"},\"yolo2msghub\":${TMP_JSON}}"
  
  # Send JSON data to IBM Cloud Event Streams
  #echo "${OUT_JSON}"
  echo "${OUT_JSON}" | kafkacat -P -b $EVTSTREAMS_BROKER_URL -X api.version.request=true -X security.protocol=sasl_ssl -X sasl.mechanisms=PLAIN -X sasl.username=$EVTSTREAMS_USERNAME -X sasl.password=$EVTSTREAMS_PASSWORD -t $EVTSTREAMS_TOPIC
  checkrc $? "kafkacat" "continue"

done

