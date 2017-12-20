all: testbed

testbed: upstream
	docker build -t mkszuba/gentoo-testbed .
	docker push mkszuba/gentoo-testbed

upstream:
	docker pull gentoo/stage3-amd64-hardened:latest

