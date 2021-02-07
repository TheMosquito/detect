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
from datetime import datetime
import base64

# Configuration constants
MQTT_SUB_COMMAND = 'mosquitto_sub -h mqtt -p 1883 -C 1 '
#MQTT_CAM_TOPIC = '/cam'
MQTT_DETECT_TOPIC = '/detect'
FLASK_BIND_ADDRESS = '0.0.0.0'
FLASK_PORT = 5200
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

  # Loop forever collecting from the MQTT /detect feed (yolo output)
  class YoloThread(threading.Thread):
    def run(self):
      global last_detect
      # print("\nDetect topic monitor thread started!")
      DETECT_COMMAND = MQTT_SUB_COMMAND + '-t ' + MQTT_DETECT_TOPIC
      while True:
        last_detect = subprocess.check_output(DETECT_COMMAND, shell=True)
        # print("\n\nMessage received on detect topic...\n")
        # print(last_detect)
        # print("\nSleeping for " + str(1) + " seconds...\n")
        #time.sleep(1)

  @webapp.route("/images/detect.jpg")
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

  @webapp.route("/json")
  def get_json():
    if last_detect:
      return last_detect.decode("utf-8") + '\n'
    else:
      return '{}\n'

  @webapp.route("/")
  def get_cam():
    j = json.loads(last_detect)
    n = j['detect']['deviceid']
    c = len(j['detect']['entities'])
    ct = j['detect']['camtime']
    it = j['detect']['time']
    OUT = \
      '<html>\n' + \
      ' <head>\n' + \
      '   <title>Watcher</title>\n' + \
      ' </head>\n' + \
      ' <body>\n' + \
      '   <table>\n' + \
      '     <tr>\n' + \
      '       <th><h2>Darknet YoloV3 Example</h2></th>\n' + \
      '     </tr>\n' + \
      '     <tr>\n' + \
      '       <th>Device ID: ' + n + '</th>\n' + \
      '     </tr>\n' + \
      '     <tr>\n' + \
      '       <th><span id="when">&nbsp;</span></th>\n' + \
      '     </tr>\n' + \
      '     <tr>\n' + \
      '       <td><img id="detect" height="480px" width="640px" src="/images/detect.jpg" alt="Yolo Prediction Image" /></td>\n' + \
      '     </tr>\n' + \
      '     <tr><td> &nbsp; </td></tr>\n' + \
      '     <tr>\n' + \
      '       <td> &nbsp; Found entities in <span id="classes">' + str(c) + '</span> classes.</td>\n' + \
      '     </tr>\n' + \
      '     <tr>\n' + \
      '       <td> &nbsp; Camera time: <span id="camtime">' + str(ct) + '</span> seconds.</td>\n' + \
      '     </tr>\n' + \
      '     <tr>\n' + \
      '       <td> &nbsp; Inferencing time: <span id="inftime">' + str(it) + '</span> seconds.</td>\n' + \
      '     </tr>\n' + \
      '     <tr><td> &nbsp; </td></tr>\n' + \
      '     <tr>\n' + \
      '       <td> &nbsp; Example code: <a href="https://github.com/MegaMosquito/detect/">https://github.com/MegaMosquito/detect/</a></td>\n' + \
      '     </tr>\n' + \
      '     <tr>\n' + \
      '       <td> &nbsp; Darknet website: <a href="https://pjreddie.com/darknet/">https://pjreddie.com/darknet/</a></td>\n' + \
      '     </tr>\n' + \
      '     <tr>\n' + \
      '       <td> &nbsp; Darknet github: <a href="https://github.com/pjreddie/darknet">https://github.com/pjreddie/darknet</a></td>\n' + \
      '     </tr>\n' + \
      '   </table>\n' + \
      '   <script>\n' + \
      '     function refresh(d_image, d_date, d_classes, d_camtime, d_inftime) {\n' + \
      '       var t = 500;\n' + \
      '       (async function startRefresh() {\n' + \
      '         var address;\n' + \
      '         if(d_image.src.indexOf("?")>-1)\n' + \
      '           address = d_image.src.split("?")[0];\n' + \
      '         else\n' + \
      '           address = d_image.src;\n' + \
      '         d_image.src = address+"?time="+new Date().getTime();\n' + \
      '         const response = await fetch("/json");\n' + \
      '         const j = await response.json();\n' + \
      '         var when = new Date(j.detect.date * 1000);\n' +\
      '         var c = j.detect.entities.length;\n' +\
      '         var ct = j.detect.camtime;\n' +\
      '         var it = j.detect.time;\n' +\
      '         d_date.innerHTML = when;\n' +\
      '         d_classes.innerHTML = c;\n' +\
      '         d_camtime.innerHTML = ct;\n' +\
      '         d_inftime.innerHTML = it;\n' +\
      '         setTimeout(startRefresh, t);\n' + \
      '       })();\n' + \
      '     }\n' + \
      '     window.onload = function() {\n' + \
      '       var d_image = document.getElementById("detect");\n' + \
      '       var d_date = document.getElementById("when");\n' + \
      '       var d_classes = document.getElementById("classes");\n' + \
      '       var d_camtime = document.getElementById("camtime");\n' + \
      '       var d_inftime = document.getElementById("inftime");\n' + \
      '       refresh(d_image, d_date, d_classes, d_camtime, d_inftime);\n' + \
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
# watch_cam = CamThread()
# watch_cam.start()
  watch_yolo = YoloThread()
  watch_yolo.start()
  webapp.run(host=FLASK_BIND_ADDRESS, port=FLASK_PORT)

