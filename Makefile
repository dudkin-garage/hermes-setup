-include .env

VPS_SSH_USER ?= worker
VPS_SSH_PORT ?= 22
SSH_COMMON_OPTS ?= -o ExitOnForwardFailure=yes -o ServerAliveInterval=30 -o ServerAliveCountMax=3

HERMES_API_HOST_PORT ?= 8642
HERMES_DASHBOARD_HOST_PORT ?= 9119

HERMES_TUNNEL_LOCAL_HOST ?= 127.0.0.1
HERMES_TUNNEL_API_LOCAL_PORT ?= 18642
HERMES_TUNNEL_DASHBOARD_LOCAL_PORT ?= 19119
HERMES_TUNNEL_REMOTE_HOST ?= 127.0.0.1

HERMES_REVERSE_BIND_HOST ?= 172.17.0.1
HERMES_REVERSE_API_PORT ?= 18642
HERMES_REVERSE_DASHBOARD_PORT ?= 19119

.PHONY: install uninstall test-host test-container show check-vps-env tunnel tunnel-api tunnel-dashboard tunnel-reverse urls dashboard-url

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

check-vps-env:
	@test -n "$(VPS_HOST)" || { printf 'VPS_HOST is not set. Add it to .env, for example: VPS_HOST=h2.dudkin-garage.com\n'; exit 1; }

tunnel: check-vps-env urls
	ssh -N $(SSH_COMMON_OPTS) -p "$(VPS_SSH_PORT)" \
		-L "$(HERMES_TUNNEL_LOCAL_HOST):$(HERMES_TUNNEL_API_LOCAL_PORT):$(HERMES_TUNNEL_REMOTE_HOST):$(HERMES_API_HOST_PORT)" \
		-L "$(HERMES_TUNNEL_LOCAL_HOST):$(HERMES_TUNNEL_DASHBOARD_LOCAL_PORT):$(HERMES_TUNNEL_REMOTE_HOST):$(HERMES_DASHBOARD_HOST_PORT)" \
		"$(VPS_SSH_USER)@$(VPS_HOST)"

tunnel-api: check-vps-env
	ssh -N $(SSH_COMMON_OPTS) -p "$(VPS_SSH_PORT)" \
		-L "$(HERMES_TUNNEL_LOCAL_HOST):$(HERMES_TUNNEL_API_LOCAL_PORT):$(HERMES_TUNNEL_REMOTE_HOST):$(HERMES_API_HOST_PORT)" \
		"$(VPS_SSH_USER)@$(VPS_HOST)"

tunnel-dashboard: check-vps-env dashboard-url
	ssh -N $(SSH_COMMON_OPTS) -p "$(VPS_SSH_PORT)" \
		-L "$(HERMES_TUNNEL_LOCAL_HOST):$(HERMES_TUNNEL_DASHBOARD_LOCAL_PORT):$(HERMES_TUNNEL_REMOTE_HOST):$(HERMES_DASHBOARD_HOST_PORT)" \
		"$(VPS_SSH_USER)@$(VPS_HOST)"

tunnel-reverse: check-vps-env
	ssh -N $(SSH_COMMON_OPTS) -p "$(VPS_SSH_PORT)" \
		-R "$(HERMES_REVERSE_BIND_HOST):$(HERMES_REVERSE_API_PORT):127.0.0.1:$(HERMES_API_HOST_PORT)" \
		-R "$(HERMES_REVERSE_BIND_HOST):$(HERMES_REVERSE_DASHBOARD_PORT):127.0.0.1:$(HERMES_DASHBOARD_HOST_PORT)" \
		"$(VPS_SSH_USER)@$(VPS_HOST)"

urls:
	@printf 'Dashboard: http://%s:%s\n' "$(HERMES_TUNNEL_LOCAL_HOST)" "$(HERMES_TUNNEL_DASHBOARD_LOCAL_PORT)"
	@printf 'API:       http://%s:%s\n' "$(HERMES_TUNNEL_LOCAL_HOST)" "$(HERMES_TUNNEL_API_LOCAL_PORT)"

dashboard-url:
	@printf 'Dashboard: http://%s:%s\n' "$(HERMES_TUNNEL_LOCAL_HOST)" "$(HERMES_TUNNEL_DASHBOARD_LOCAL_PORT)"
