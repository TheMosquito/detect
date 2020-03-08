
-include env.check.mk

register-yolo:
	hzn register --pattern "${HZN_ORG_ID}/pattern-yolo" --input-file ./input.json

publish-pattern:


test-all:
	make -C mqtt
	make -C mqtt test-broker
	make -C cam
	make -C cam test-cam
	make -C watcher
	make -C watcher test-watcher
	make -C yolo
	make -C yolo test-yolo
	make -C mqtt2kafka
	make -C mqtt2kafka test-kafka

clean-docker-all:
	-docker rm -f `docker ps -aq` 2>/dev/null || :
	-docker rmi -f `docker images -aq` 2>/dev/null || :
	-docker network rm mqtt-net 2>/dev/null || :

add-business-policy:
	make -C src/cam add-business-policy
	make -C src/mqtt2kafka add-business-policy
	make -C src/watcher add-business-policy
	make -C src/yolo add-business-policy

publish-all:
	make -C src/mqtt
	make -C src/mqtt push
	make -C src/mqtt publish-service
	make -C src/cam
	make -C src/cam push
	make -C src/cam publish-service
	make -C src/mqtt2kafka
	make -C src/mqtt2kafka push
	make -C src/mqtt2kafka publish-service
	make -C src/watcher
	make -C src/watcher push
	make -C src/watcher publish-service
	make -C src/yolo
	make -C src/yolo push
	make -C src/yolo publish-service
#	make -C src/yologpu
#	make -C src/yologpu push
#	make -C src/yologpu publish-service

