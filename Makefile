
register-yolo:
	hzn register --pattern "${HZN_ORG_ID}/pattern-yolo" --input-file ./input.json

publish-pattern:
	hzn exchange pattern publish -f pattern-yolo.json

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

