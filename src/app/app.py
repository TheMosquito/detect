#
# The pump that calls the yolov3 REST API, then pushes the results to kafka.
# It can also (optionally) push the data to the local MQTT for debug purposes).
#
# Written by Glen Darling, December 2019.
#

import json
import os
import subprocess
import threading
import time
from datetime import datetime
import base64
import requests

# Configuration from the environment
HZN_DEVICE_ID = os.environ['HZN_DEVICE_ID']
EVENTSTREAMS_BROKER_URLS = os.environ['EVENTSTREAMS_BROKER_URLS']
EVENTSTREAMS_API_KEY = os.environ['EVENTSTREAMS_API_KEY']
EVENTSTREAMS_PUB_TOPIC = os.environ['EVENTSTREAMS_PUB_TOPIC']

# Additional configuration constants
TEMP_FILE = '/tmp/yolov3.json'
YOLO_URL = 'http://yolov3:80/detect?kind=json&url=http%3A%2F%2Frestcam'
MQTT_PUB_TOPIC = '/detect'
MQTT_PUB_COMMAND = 'mosquitto_pub -h mqtt -p 1883'
DEBUG_PUB_COMMAND = MQTT_PUB_COMMAND + ' -t ' + MQTT_PUB_TOPIC + ' -f '
KAFKA_PUB_COMMAND = 'kafkacat -P -b ' + EVENTSTREAMS_BROKER_URLS + ' -X api.version.request=true -X security.protocol=sasl_ssl -X sasl.mechanisms=PLAIN -X sasl.username=token -X sasl.password="' + EVENTSTREAMS_API_KEY + '" -t ' + EVENTSTREAMS_PUB_TOPIC + ' '
SLEEP_BETWEEN_CALLS = 0.1

# To log or not to log, that is the question
LOG_STATS = False
LOG_ALL = False

if __name__ == '__main__':

  while True:

    # Request one run from yolov3...
    if LOG_ALL:
      print('\nInitiating a request...')
      print('--> URL: ' + YOLO_URL)
    r = requests.get(YOLO_URL)
    if (r.status_code > 299):
        print('ERROR: Yolo request failed: ' + str(r.status_code))
        time.sleep(10)
        continue
    if LOG_ALL: print('Successful response received!')
    j = r.json()

    # Optionally log some data
    if LOG_ALL or LOG_STATS:
      d = datetime.fromtimestamp(j['detect']['date']).strftime('%Y-%m-%d %H:%M:%S')
      print('Date: %s, Cam: %0.2f sec, YoloV3: %0.2f msec.' % (d, j['detect']['camtime'], j['detect']['time'] * 1000.0))

    # Push JSON to a file so we can publish it from a file (it overflows CLI)
    with open(TEMP_FILE, 'w') as temp_file:
      json.dump(j, temp_file)

    # (Optionally) publish to the debug topic
    if '' != MQTT_PUB_TOPIC:
      if LOG_ALL: print('--> MQTT: ' + DEBUG_PUB_COMMAND + TEMP_FILE)
      discard = subprocess.run(DEBUG_PUB_COMMAND + TEMP_FILE, shell=True)

    # Publish to kafka
    if LOG_ALL: print('--> Kafka: ' + KAFKA_PUB_COMMAND + TEMP_FILE)
    discard = subprocess.run(KAFKA_PUB_COMMAND + TEMP_FILE, shell=True)

    # Pause briefly (to not hog the CPU too much)
    if LOG_ALL: print('Sleeping for ' + str(SLEEP_BETWEEN_CALLS) + ' seconds...')
    time.sleep(SLEEP_BETWEEN_CALLS)


