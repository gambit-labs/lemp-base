IMAGE_AUTHOR=gambitlabs
IMAGE_VERSION=v0.4.0
TARGET_DIR=$(shell pwd)/_output

lemp-base: env $(TARGET_DIR)/lemp-base
$(TARGET_DIR)/lemp-base:
	./docker-wget-include.sh Dockerfile $@/Dockerfile
	sed -e "/COPY nginx.conf/d;/COPY nginx.vh.default.conf/d" -i $@/Dockerfile
	docker build -t $(IMAGE_AUTHOR)/lemp-base:$(IMAGE_VERSION) .

php7: $(TARGET_DIR)/php7
$(TARGET_DIR)/php7:
	echo $@
	exit
	./docker-wget-include.sh php7/Dockerfile $@/Dockerfile
	docker build -t $(IMAGE_AUTHOR)/php7:$(IMAGE_VERSION) .

