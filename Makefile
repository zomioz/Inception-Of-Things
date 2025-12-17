up:
	cd ./Server && vagrant up
	cd ./ServerWorker && vagrant up

down:
	cd ./Server && vagrant destroy -f
	cd ./ServerWorker && vagrant destroy -f

clean: down
	rm -rf ./Server/.vagrant
	rm -rf ./ServerWorker./vagrant

all: up