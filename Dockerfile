FROM ubuntu:xenial

ADD packages.txt /root/packages.txt

RUN apt-get -y update && apt-get -y install $(cat /root/packages.txt)

COPY --from=lachlanevenson/k8s-kubectl:v1.11.9 /usr/local/bin/kubectl /usr/bin/kubectl-v1.11.9
COPY --from=lachlanevenson/k8s-kubectl:v1.12.9 /usr/local/bin/kubectl /usr/bin/kubectl-v1.12.9
COPY --from=lachlanevenson/k8s-kubectl:v1.13.7 /usr/local/bin/kubectl /usr/bin/kubectl-v1.13.7
COPY --from=lachlanevenson/k8s-kubectl:v1.14.2 /usr/local/bin/kubectl /usr/bin/kubectl-v1.14.2
RUN ln -s /usr/bin/kubectl-v1.14.2 /usr/bin/kubectl

ADD capture-all-interfaces /usr/sbin


# Select the docker client version
ARG docker_url=https://download.docker.com/linux/static/stable/x86_64
ARG docker_version=18.03.1-ce

# Install just the docker CLI
RUN curl -fsSL $docker_url/docker-$docker_version.tgz | tar zxvf - --strip 1 -C /usr/bin docker/docker


# If we're in kubernetes, run a sleep command by default so we can exec in later.  If not, just run a shell.
CMD sh -c "test -r /run/secrets/kubernetes.io/serviceaccount/namespace && sleep 1d || bash"

