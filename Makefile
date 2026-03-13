.PHONY: rules p1 p2 p3 bonus cleanp1 cleanp2 cleanp3 cleanbonus

rules:
	@echo "Welcome to Inception of Things"
	@echo "This Makefile has 3 rules to create each parts: make p1 / make p2 / make p3"
	@echo "Obviously there are make cleanp1/cleanp2/cleanp3 to destroy each parts"

p1:
	cd p1 && tr -dc A-Za-z0-9 </dev/urandom | head -c 13 | cat > Token_tmp
	cd p1 && vagrant up

p2:
	echo "192.168.56.110 app1.com" | sudo tee -a /etc/hosts
	echo "192.168.56.110 app2.com" | sudo tee -a /etc/hosts
	echo "192.168.56.110 app3.com" | sudo tee -a /etc/hosts
	cd p2 && vagrant up

p3:
	./p3/scripts/script_install.sh

bonus:
	@echo "Checking that P3 is running before launching bonus..."
	@kubectl get namespace argocd >/dev/null 2>&1 || \
		(echo "ERROR: ArgoCD namespace not found. Run 'make p3' first." && exit 1)
	@echo "p3 is running. Starting bonus installation..."
	./bonus/scripts/script_install.sh
	
cleanp1:
	cd p1 && vagrant destroy -f
	cd p1 && rm -rf .vagrant
	cd p1 && rm -f Token_tmp

cleanp2:
	cd p2 && vagrant destroy -f
	cd p2 && rm -rf .vagrant
	sudo sed -i '/app1\.com/d' /etc/hosts
	sudo sed -i '/app2\.com/d' /etc/hosts
	sudo sed -i '/app3\.com/d' /etc/hosts

cleanp3:
	./p3/scripts/script_uninstall.sh

cleanbonus:
	./bonus/scripts/script_uninstall.sh
	./p3/scripts/script_uninstall.sh

