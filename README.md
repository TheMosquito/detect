## detect

Must define following ENVIRONMENT variables to build application, add policies and register edge node.

Enviornment variables EDGE_OWNER, EDGE_DEPLOY provide flexiblity for different developers to use the same exchange without clobering over each other. You may also use this to organize your dev, test, demo code. e.g  sg.dev sg.demo sg.test etc

    export EDGE_OWNER=<a-two-or-three-letter-distinctive-initial-of-your-name>  # sg gd 
    export EDGE_DEPLOY=<deploy-target> # e.g: dev demo test prod

    export DOCKER_BASE=<docker-base> # e.g. edgedock

    export HZN_ORG_ID=mycluster
    export HZN_EXCHANGE_USER_AUTH=iamapikey:<iam-api-key>
    export HZN_EXCHANGE_NODE_AUTH="<UNIQUE-NODE-ANME>:<node-token>"
    export DEVICENAME=<UNIQUE-NODE-ANME>

### Eventstream  

    export EVTSTREAMS_TOPIC=<your-event-stream-topic>
    export EVTSTREAMS_API_KEY=<your-event-stream-api-key>
    export EVTSTREAMS_BROKER_URL="your-event-stream-brokers"

### Create node

    hzn exchange node create -n $HZN_EXCHANGE_NODE_AUTH

### Register node

    hzn register --policy=node_policy.json --input-file ./user-input-yolo.json

### Add policy

    hzn exchange business addpolicy -f biz_policy_cam.json biz_policy_cam
    hzn exchange business addpolicy -f biz_policy_mqtt2kafka.json biz_policy_mqtt2kafka
    hzn exchange business addpolicy -f biz_policy_yolo.json biz_policy_yolo
    hzn exchange business addpolicy -f biz_policy_watcher.json  biz_policy_watcher

### Architecture
A collection of Services to implement object detection for open-horizon

![architecture-diagram](https://raw.githubusercontent.com/TheMosquito/detect/7a989c9246399cc9fa7370ab59e69faf4b72acc5/architecture.png)
