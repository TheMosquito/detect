#
# Debug client for watching/debugging the cam and yolo services
#
# Written by Glen Darling, October 2019.
#

import json
import os
import subprocess
import threading
import time
import base64

# Configuration constants
MQTT_SUB_COMMAND = 'mosquitto_sub -h mqtt -p 1883 -C 1 '
MQTT_CAM_TOPIC = '/cam'
MQTT_DETECT_TOPIC = '/detect'
FLASK_BIND_ADDRESS = '0.0.0.0'
FLASK_PORT = 5200
DUMMY_CAM_IMAGE='/dummy_live.jpg'
DUMMY_SOURCE_IMAGE='/dummy_source.jpg'
DUMMY_DETECT_IMAGE='/dummy_detect.jpg'

# Globals for the cached JSON data (last messages on these MQTT topics)
last_cam = None
last_detect = None

if __name__ == '__main__':

  from io import BytesIO
  from flask import Flask
  from flask import send_file
  webapp = Flask('watcher')                             
  webapp.config['SEND_FILE_MAX_AGE_DEFAULT'] = 0

  # Loop forever collecting from the camera feed
  class CamThread(threading.Thread):
    def run(self):
      global last_cam
      # print("\nCam topic monitor thread started!")
      CAM_COMMAND = MQTT_SUB_COMMAND + '-t ' + MQTT_CAM_TOPIC
      while True:
        last_cam = subprocess.check_output(CAM_COMMAND, shell=True)
        # print("\n\nMessage received on cam topic...\n")
        # print(last_cam)
        # print("\nSleeping for " + str(5) + " seconds...\n")
        time.sleep(5)

  # Loop forever collecting from the yolo feed
  class YoloThread(threading.Thread):
    def run(self):
      global last_detect
      # print("\nDetect topic monitor thread started!")
      DETECT_COMMAND = MQTT_SUB_COMMAND + '-t ' + MQTT_DETECT_TOPIC
      while True:
        last_detect = subprocess.check_output(DETECT_COMMAND, shell=True)
        # print("\n\nMessage received on detect topic...\n")
        # print(last_detect)
        # print("\nSleeping for " + str(5) + " seconds...\n")
        time.sleep(5)

  @webapp.route("/images/cam.jpg")
  def get_cam_image():
    if last_cam:
      j = json.loads(last_cam)
      i = base64.b64decode(j['cam']['image'])
      buffer = BytesIO()
      buffer.write(i)
      buffer.seek(0)
      return send_file(buffer, mimetype='image/jpg')
    else:
      return send_file(DUMMY_CAM_IMAGE)

  @webapp.route("/images/source.jpg")
  def get_yolo_source():
    if last_detect:
      j = json.loads(last_detect)
      i = base64.b64decode(j['detect']['source'])
      buffer = BytesIO()
      buffer.write(i)
      buffer.seek(0)
      return send_file(buffer, mimetype='image/jpg')
    else:
      return send_file(DUMMY_SOURCE_IMAGE)

  @webapp.route("/images/yolo.jpg")
  def get_yolo_image():
    if last_detect:
      j = json.loads(last_detect)
      i = base64.b64decode(j['detect']['image'])
      buffer = BytesIO()
      buffer.write(i)
      buffer.seek(0)
      return send_file(buffer, mimetype='image/jpg')
    else:
      return send_file(DUMMY_DETECT_IMAGE)

  @webapp.route("/")
  def get_cam():
    OUT = \
      '<html>\n' + \
      ' <head>\n' + \
      '   <title>Watcher</title>\n' + \
      ' </head>\n' + \
      ' <body>\n' + \
      '   <table>\n' + \
      '     <tr>\n' + \
      '       <th><h2>Live</h2></th>\n' + \
      '       <th><h2>Source</h2></th>\n' + \
      '       <th><h2>Prediction</h2></th>\n' + \
      '     </tr>\n' + \
      '     <tr>\n' + \
      '       <td><img id="live" width="160px" src="/images/cam.jpg" alt="Raw Camera Image" /></td>\n' + \
      '       <td><img id="source" src="/images/source.jpg" alt="Yolo Source Image" /></td>\n' + \
      '       <td><img id="detect" src="/images/yolo.jpg" alt="Yolo Prediction Image" /></td>\n' + \
      '     </tr>\n' + \
      '   </table>\n' + \
      '   <script>\n' + \
      '     function refresh(node) {\n' + \
      '       var t = 500;\n' + \
      '       (function startRefresh() {\n' + \
      '         var address;\n' + \
      '         if(node.src.indexOf("?")>-1)\n' + \
      '           address = node.src.split("?")[0];\n' + \
      '         else\n' + \
      '           address = node.src;\n' + \
      '         node.src = address+"?time="+new Date().getTime();\n' + \
      '         setTimeout(startRefresh, t);\n' + \
      '       })();\n' + \
      '     }\n' + \
      '     window.onload = function() {\n' + \
      '       var live = document.getElementById("live");\n' + \
      '       var source = document.getElementById("source");\n' + \
      '       var detect = document.getElementById("detect");\n' + \
      '       refresh(live);\n' + \
      '       refresh(source);\n' + \
      '       refresh(detect);\n' + \
      '     }\n' + \
      '   </script>\n' + \
      ' </body>\n' + \
      '</html>\n'
    return (OUT)

  # Prevent caching everywhere
  @webapp.after_request
  def add_header(r):
    r.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
    r.headers["Pragma"] = "no-cache"
    r.headers["Expires"] = "0"
    r.headers['Cache-Control'] = 'public, max-age=0'
    return r

  # Main program (instantiates and starts watcher threads and then web server)
  watch_cam = CamThread()
  watch_cam.start()
  watch_yolo = YoloThread()
  watch_yolo.start()
  webapp.run(host=FLASK_BIND_ADDRESS, port=FLASK_PORT)

