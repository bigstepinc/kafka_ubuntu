FROM ubuntu:14.04

ADD init-docker.sh /opt
ADD start-kafka-manager.sh /usr/bin/
ADD entrypoint.sh /opt/entrypoint.sh
ADD version.json /opt

RUN ./opt/init-docker.sh && chmod 777 /opt/entrypoint.sh && chmod 777 /usr/bin/start-kafka-manager.sh

EXPOSE 2181 2888 3888 9092 9000

ENTRYPOINT ["/opt/entrypoint.sh"]
