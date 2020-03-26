## README

Must define following ENVIRONMENT variables to build application, add policies and register edge node.

Enviornment variables EDGE_OWNER, EDGE_DEPLOY provide flexiblity for different developers to use the same exchange without clobering over each other.

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

    Using policy

    hzn register --policy=node_policy.json --input-file ./user-input-yolo.json

    Using pattern

    hzn register --pattern "${HZN_ORG_ID}/pattern-${EDGE_OWNER}.${EDGE_DEPLOY}.yolo-$ARCH" --input-file ./user-input-yolo.json --policy=node_policy_privileged.json

### Architecture
A collection of Services to implement object detection for open-horizon

![architecture-diagram](https://raw.githubusercontent.com/TheMosquito/detect/7a989c9246399cc9fa7370ab59e69faf4b72acc5/architecture.png)
