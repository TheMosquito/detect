### Personalization of build, publish and use of IEAM system in a shared environment
#### Introduction
Using a shared instance creates several challenges when services, patterns and policies need to be published in a common exchange without multiple developers clobbering over each other.  

#### Issues
- Developers need to identify their service, pattern and policies among many similar assets (concept of owner)
- Developers may have project for demo, dev, test and more ( group the assets)
- Developers need to use their own docker repository  (specify own docker account)

The tooling outlined below addresses these concerns and builds on top of existing infrastructure 

#### Automated Steps
Start with reviewing Makefile for targets. 

Build and publish images to docker and services to exchange. Can be executed again and again.  

    make publish-all 
 
Publish pattern

    make publish-pattern

Publish business-policy

    make add-business-policy

Must define following ENVIRONMENT variables to build application, add policies and register edge node.

Enviornment variables EDGE_OWNER, EDGE_DEPLOY provide flexiblity for different developers to use the same exchange without clobering over each other.

    export EDGE_OWNER=<a-two-or-three-letter-distinctive-initial-of-your-name>  # sg gd 
    export EDGE_DEPLOY=<deploy-target> # e.g: dev demo test prod

    export DOCKER_BASE=<docker-base> # e.g. edgedock

    export HZN_ORG_ID=mycluster
    export HZN_EXCHANGE_USER_AUTH=iamapikey:<iam-api-key>
    export HZN_EXCHANGE_NODE_AUTH="<UNIQUE-NODE-ANME>:<node-token>"
    export APP_NODE_NAME=<UNIQUE-NODE-ANME>

### Event Streams  

    export EVENTSTREAMS_BASIC_TOPIC=<your-event-stream-topic>
    export EVENTSTREAMS_ENHANCED_TOPIC=<your-event-stream-topic>
    export EVENTSTREAMS_API_KEY=<your-event-stream-api-key>
    export EVENTSTREAMS_BROKER_URLS="your-event-stream-brokers"

### Create node

    hzn exchange node create -n $HZN_EXCHANGE_NODE_AUTH

### Register node
Use script to register node

#### apprest (REST based yolov3) - NUC(amd64), Nvidia Jetson Nano(arm64) 
 
policy
    
    ./node_register_apprest.sh -e ~/agent/yolo/apprest/ieam-dev/ENV_YOLO_REST_DEV -r -l
    
pattern
    
    ./node_register_apprest.sh -e ~/agent/yolo/apprest/ieam-dev/ENV_YOLO_REST_DEV -r -p
    
#### appmqtt (MQTT based yolo) -  RPI(arm), NUC(amd64), Nvidia Jetson Nano(arm64) 

policy
   
    ./node_register_appmqtt.sh -e ~/agent/yolo/appmqtt/ieam-dev/ENV_YOLO_MQTT_DEV -r -l
    
pattern
    
    ./node_register_appmqtt.sh -e ~/agent/yolo/appmqtt/ieam-dev/ENV_YOLO_MQTT_DEV -r -p
   
### Architecture
A collection of Services to implement object detection for open-horizon

![architecture-diagram](https://raw.githubusercontent.com/TheMosquito/detect/7a989c9246399cc9fa7370ab59e69faf4b72acc5/architecture.png)
