
register-yolo:
	hzn register --pattern "${HZN_ORG_ID}/pattern-yolo" --input-file ./input.json

publish-pattern:
	hzn exchange pattern publish -f pattern-yolo.json

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

publish-all:
	make -C mqtt
	make -C mqtt push
	make -C mqtt publish-service
	make -C cam
	make -C cam push
	make -C cam publish-service
	make -C watcher
	make -C watcher push
	make -C watcher publish-service
	make -C yolo
	make -C yolo push
	make -C yolo publish-service
	make -C mqtt2kafka
	make -C mqtt2kafka push
	make -C mqtt2kafka publish-service
	make publish-pattern

