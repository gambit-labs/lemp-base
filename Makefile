IMAGE_REPO=gambitlabs/lemp-base
IMAGE_VERSION=0.5.0
IMAGE_REVISION=2
STAGE_DIR=$(shell pwd)/_stage

build: ./docker-ext-include.sh
	rm -rf $(STAGE_DIR)
	mkdir -p $(STAGE_DIR)
	./docker-ext-wget.sh Dockerfile $(STAGE_DIR)/Dockerfile.1
	./docker-ext-include.sh $(STAGE_DIR)/Dockerfile.1 $(STAGE_DIR)/Dockerfile
	cp -r nginx-conf sample docker-entrypoint.sh $(STAGE_DIR)/
	sed -e "\@/etc/nginx/conf.d/default.conf@d;\@/etc/nginx/nginx.conf@d" -i $(STAGE_DIR)/Dockerfile
	sed -e "s/--user=nginx/--user=www-data/g;s/--group=nginx/--group=www-data/g" -i $(STAGE_DIR)/Dockerfile
	sed -e '\@RUN set -x @d;\@&& addgroup@d;\@adduser -D -S@d;\@adduser -u 82@d;' -i $(STAGE_DIR)/Dockerfile
	docker build -t $(IMAGE_REPO):$(IMAGE_VERSION)-$(IMAGE_REVISION) $(STAGE_DIR)
	docker tag $(IMAGE_REPO):$(IMAGE_VERSION)-$(IMAGE_REVISION) $(IMAGE_REPO):$(IMAGE_VERSION)

./docker-ext-include.sh:
	curl -sSL https://raw.githubusercontent.com/gambit-labs/dockerfile-extensions/master/docker-ext-include.sh > docker-ext-include.sh
	curl -sSL https://raw.githubusercontent.com/gambit-labs/dockerfile-extensions/master/docker-ext-wget.sh > docker-ext-wget.sh
	chmod +x docker-ext-include.sh docker-ext-wget.sh
