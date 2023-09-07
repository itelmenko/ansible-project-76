all:
	@ ansible-galaxy install -r requirements.yml && ansible-playbook playbook.yml --ask-vault-pass -i inventory.ini
prepare:
	@ ansible-galaxy install -r requirements.yml && ansible-playbook playbook.yml --ask-vault-pass -i inventory.ini -t prepare
deploy:
	@ ansible-galaxy install -r requirements.yml && ansible-playbook playbook.yml --ask-vault-pass -i inventory.ini -t deploy
datadog:
	@ ansible-galaxy install -r requirements.yml && ansible-playbook playbook.yml --ask-vault-pass -i inventory.ini -t datadog
config:
	@ env EDITOR=nano ansible-vault edit group_vars/webservers/vault.yml


