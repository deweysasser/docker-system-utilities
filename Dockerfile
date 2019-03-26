FROM ubuntu:xenial

ADD packages.txt /root/packages.txt

RUN apt-get -y update && apt-get -y install $(cat /root/packages.txt)
