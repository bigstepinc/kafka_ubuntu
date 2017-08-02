FROM ubuntu:14.04
 

ADD start-kafka-manager.sh /usr/bin/
ADD entrypoint.sh /opt/entrypoint.sh

RUN chmod 777 /opt/entrypoint.sh
RUN chmod 777 /usr/bin/start-kafka-manager.sh

#RUN /opt/entrypoint.sh
ADD version.json /opt

EXPOSE 2181 2888 3888 9092 9000

ENTRYPOINT ["/opt/entrypoint.sh"]
