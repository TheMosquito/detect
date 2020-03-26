
# Checks required environment variables
-include env.check.mk

# You must always use the Horizon name for architecture (`hzn architecture`)
export ARCH ?= $(shell hzn architecture)

# build, push, publish service all
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

publish-pattern:
	hzn exchange pattern publish -f pattern/pattern-yolo-arch.json

# add all policies 
add-business-policy:
	make -C src/cam add-business-policy
	make -C src/mqtt2kafka add-business-policy
	make -C src/watcher add-business-policy
	make -C src/yolo add-business-policy

