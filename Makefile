.PHONY: rules p1 p2 cleanp1 cleanp2

rules:
	@echo "Welcome to Inception of Things"
	@echo "This Makefile has 3 rules to create each parts: make p1 / make p2 / make p3"
	@echo "Obviously there are make cleanp1/cleanp2/cleanp3 to destroy each parts"

p1:
	cd P1 && tr -dc A-Za-z0-9 </dev/urandom | head -c 13 | cat > Token_tmp
	cd P1 && vagrant up

p2:
	echo "192.168.56.110 app1.com" | sudo tee -a /etc/hosts
	echo "192.168.56.110 app2.com" | sudo tee -a /etc/hosts
	echo "192.168.56.110 app3.com" | sudo tee -a /etc/hosts
	cd P2 && vagrant up

p3:
	./P3/script_install.sh

cleanp1:
	cd P1 && vagrant destroy -f
	cd P1 && rm -rf .vagrant
	cd P1 && rm -f Token_tmp

cleanp2:
	cd P2 && vagrant destroy -f
	cd P2 && rm -rf .vagrant
	sudo sed -i '/app1\.com/d' /etc/hosts
	sudo sed -i '/app2\.com/d' /etc/hosts
	sudo sed -i '/app3\.com/d' /etc/hosts

cleanp3:
	./P3/script_uninstall.sh

