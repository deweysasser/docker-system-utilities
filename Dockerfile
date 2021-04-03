# syntax = docker/dockerfile:1.2
FROM ubuntu:focal
ENV DEBIAN_FRONTEND=noninteractive

# Select the docker client version
ARG docker_url=https://download.docker.com/linux/static/stable/x86_64
ARG docker_version=20.10.5


# don't remove files after install -- we want to cache them
RUN rm -f /etc/apt/apt.conf.d/docker-clean

# Prepare the system to be able to retrieve the google repo
RUN --mount=type=cache,target=/var/cache/apt  apt-get update && apt-get -y install --no-install-recommends apt-transport-https ca-certificates gnupg

# Fetch and install the google GPG key
ADD https://packages.cloud.google.com/apt/doc/apt-key.gpg /root/google-key.gpg
RUN cat /root/google-key.gpg |  apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -

# Now add the gogole repo
ADD google-cloud-sdk.list /etc/apt/sources.list.d/google-cloud-sdk.list

# Prep *all* the packages
ADD packages.txt /root/packages.txt

# Update (yes, again) and install all the packages
RUN --mount=type=cache,target=/var/cache/apt  apt-get -y update && \
    apt-get -y install --no-install-recommends $(sed -e '/^#/d;/^$/d' < /root/packages.txt)

# fetch a bunch of kubectl
COPY --from=lachlanevenson/k8s-kubectl:v1.15.12 /usr/local/bin/kubectl /usr/bin/kubectl-v1.15
COPY --from=lachlanevenson/k8s-kubectl:v1.16.15 /usr/local/bin/kubectl /usr/bin/kubectl-v1.16
COPY --from=lachlanevenson/k8s-kubectl:v1.17.17 /usr/local/bin/kubectl /usr/bin/kubectl-v1.17
COPY --from=lachlanevenson/k8s-kubectl:v1.18.15 /usr/local/bin/kubectl /usr/bin/kubectl-v1.18
COPY --from=lachlanevenson/k8s-kubectl:v1.19.9 /usr/local/bin/kubectl /usr/bin/kubectl-v1.19
COPY --from=lachlanevenson/k8s-kubectl:v1.20.5 /usr/local/bin/kubectl /usr/bin/kubectl-v1.20

# Activate the latest kubectl
RUN ln -s /usr/bin/kubectl-v1.20 /usr/bin/kubectl

# AWS eksctl

RUN curl -fsSL "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" \
    | tar xz -C /usr/bin
# doctl
RUN curl -fsSL https://github.com/digitalocean/doctl/releases/download/v1.57.0/doctl-1.57.0-linux-amd64.tar.gz \
    | tar xz -C /usr/bin

ADD capture-all-interfaces /usr/sbin


# Install just the docker CLI
RUN curl -fsSL $docker_url/docker-$docker_version.tgz | tar zxv --strip 1 -C /usr/bin docker/docker


# If we're in kubernetes, run a sleep command by default so we can exec in later.  If not, just run a shell.
CMD sh -c "test -r /run/secrets/kubernetes.io/serviceaccount/namespace && sleep 1d || bash"

