# syntax = docker/dockerfile:1.2


# Collect up all the files from other containers/downloads, so we can put them in as a single layer
FROM ubuntu:20.10 as collector
# Select the docker client version
ENV DEBIAN_FRONTEND=noninteractive

ARG docker_url=https://download.docker.com/linux/static/stable/x86_64
ARG docker_version=20.10.5


WORKDIR /root
RUN mkdir bin; apt-get update && apt-get install --no-install-recommends -y curl ca-certificates
# fetch a bunch of kubectl
COPY --from=lachlanevenson/k8s-kubectl:v1.15.12 /usr/local/bin/kubectl bin/kubectl-v1.15
COPY --from=lachlanevenson/k8s-kubectl:v1.16.15 /usr/local/bin/kubectl bin/kubectl-v1.16
COPY --from=lachlanevenson/k8s-kubectl:v1.17.17 /usr/local/bin/kubectl bin/kubectl-v1.17
COPY --from=lachlanevenson/k8s-kubectl:v1.18.15 /usr/local/bin/kubectl bin/kubectl-v1.18
COPY --from=lachlanevenson/k8s-kubectl:v1.19.9 /usr/local/bin/kubectl bin/kubectl-v1.19
COPY --from=lachlanevenson/k8s-kubectl:v1.20.5 /usr/local/bin/kubectl bin/kubectl-v1.20

# bunch of cloud tools

RUN curl -fsSL "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" \
    | tar xz -C bin; \
    curl -fsSL https://github.com/digitalocean/doctl/releases/download/v1.57.0/doctl-1.57.0-linux-amd64.tar.gz \
    | tar xz -C bin ;\
    curl -fsSL $docker_url/docker-$docker_version.tgz | tar zxv --strip 1 -C bin docker/docker


# Activate the latest kubectl
RUN ln -s kubectl-v1.20 bin/kubectl


###################################################################################
FROM ubuntu:20.10
ARG DEBIAN_FRONTEND=noninteractive

# Prepare the system to be able to retrieve the google repo
# don't remove files after install -- we want to cache them
RUN --mount=type=cache,target=/var/cache/apt  \
    rm -f /etc/apt/apt.conf.d/docker-clean; \
    apt-get update \
    && apt-get -y install --no-install-recommends apt-transport-https ca-certificates gnupg add-apt-key curl \
    && rm -rf /var/lib/apt/lists/*

# Now add the gogole repo
ADD google-cloud-sdk.list /etc/apt/sources.list.d/google-cloud-sdk.list

# Prep *all* the packages
ADD packages.txt /root/packages.txt

# Update (yes, again) and install all the packages
RUN --mount=type=cache,target=/var/cache/apt  \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg |  apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - \
    && apt-get -y update \
    &&  apt-get -y install --no-install-recommends $(sed -e '/^#/d;/^$/d' < /root/packages.txt) \
    &&  rm -rf /var/lib/apt/lists/*

# fetch a bunch of kubectl
COPY --from=collector /root/bin/* /usr/bin/


ADD capture-all-interfaces /usr/sbin

# If we're in kubernetes, run a sleep command by default so we can exec in later.  If not, just run a shell.
CMD sh -c "test -r /run/secrets/kubernetes.io/serviceaccount/namespace && sleep 1d || bash"

