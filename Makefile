.PHONY: rules p1 p2 cleanp1 cleanp2

rules:
	@echo "Welcome to Inception of Things"
	@echo "This Makefile has 3 rules to create each parts: make p1 / make p2 / make p3"
	@echo "Obviously there are make cleanp1/cleanp2/cleanp3 to destroy each parts"

p1:
	cd P1 && vagrant up

p2:
	cd P2 && vagrant up

#p3:
#	cd P3 && vagrant up

cleanp1:
	cd P1 && vagrant destroy -f
	cd P1 && rm -rf .vagrant

cleanp2:
	cd P2 && vagrant destroy -f
	cd P2 && rm -rf .vagrant

#cleanp3:
#	cd P3 && vagrant destroy -f

