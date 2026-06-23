install:
	sudo mkdir -p /etc/ssh/sshd_config.d
	sudo cp sshd_config.d/hermes-tunnel.conf /etc/ssh/sshd_config.d/
	sudo sshd -t
	sudo systemctl restart ssh || sudo systemctl restart sshd

uninstall:
	sudo rm /etc/ssh/sshd_config.d/hermes-tunnel.conf
	sudo sshd -t
	sudo systemctl restart ssh || sudo systemctl restart sshd

test-host:
	curl http://127.0.0.1:18642/health
	curl http://172.17.0.1:18642/health

test-container:
	@echo "curl http://host.docker.internal:18642/health"

show:
	sudo sshd -T | grep -Ei 'allowtcpforwarding|gatewayports|permitlisten|permitopen'
