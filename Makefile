
all:
	@echo ""

publish-yolo:
	hzn exchange pattern publish -f pattern-yolo.json

register-yolo:
	hzn register --pattern "mdye@us.ibm.com/pattern-yolo" --input-file ./input.json
