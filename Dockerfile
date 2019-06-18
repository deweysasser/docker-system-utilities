FROM ubuntu:xenial

ADD packages.txt /root/packages.txt

RUN apt-get -y update && apt-get -y install $(cat /root/packages.txt)

COPY --from=lachlanevenson/k8s-kubectl:v1.11.9 /usr/local/bin/kubectl /usr/bin/kubectl-v1.11.9
COPY --from=lachlanevenson/k8s-kubectl:v1.12.9 /usr/local/bin/kubectl /usr/bin/kubectl-v1.12.9
COPY --from=lachlanevenson/k8s-kubectl:v1.13.7 /usr/local/bin/kubectl /usr/bin/kubectl-v1.13.7
COPY --from=lachlanevenson/k8s-kubectl:v1.14.2 /usr/local/bin/kubectl /usr/bin/kubectl-v1.14.2
RUN ln -s /usr/bin/kubectl-v1.14.2 /usr/bin/kubectl

CMD sh -c "test -r /run/secrets/kubernetes.io/serviceaccount/namespace && sleep 1d || bash"

