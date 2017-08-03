#!/bin/bash

# Prepare the environment
apt-get update && apt-get -y install wget tar curl curl git unzip dnsutils  net-tools && apt-get clean 

# Application download and install
cd /opt && wget http://apache.mirror.anlx.net/kafka/0.10.1.0/kafka_2.11-0.10.1.0.tgz 
cd /opt && tar xzvf /opt/kafka_2.11-0.10.1.0.tgz 
rm -rf /opt/kafka_2.11-0.10.1.0.tgz

export KAFKA_HOME=/opt/kafka_2.11-0.10.1.0 

# Install Kafka and Kafka Manager
export SBT_VERSION=0.13.11
export SBT_HOME=/usr/local/sbt
export PATH=${PATH}:${SBT_HOME}/bin

# Install sbt
curl -sL "http://dl.bintray.com/sbt/native-packages/sbt/$SBT_VERSION/sbt-$SBT_VERSION.tgz" | gunzip | tar -x -C /usr/local && \
echo -ne "- with sbt $SBT_VERSION\n" >> /root/.built

cd /tmp && \
curl -sL "http://dl.bintray.com/sbt/native-packages/sbt/$SBT_VERSION/sbt-$SBT_VERSION.tgz" | gunzip | tar -x -C /usr/local && \
echo -ne "- with sbt $SBT_VERSION\n" >> /root/.built &&\
git clone https://github.com/yahoo/kafka-manager.git && \
cd kafka-manager && \
sbt clean dist && \
mv ./target/universal/kafka-manager*.zip /opt && \
cd /opt && \
unzip kafka-manager*.zip
#ln -s $(find kafka-manager* -type d -prune) kafka-manager
    
#rm /opt/kafka-manager*.zip
