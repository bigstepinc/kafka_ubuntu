#!/bin/bash

#Setup environment
ifconfig | grep -oE "\b(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b" >> output
local_ip=$(head -n1 output)
rm output

# Retrieve the instances in the Kafka cluster
mkdir /tmp/zookeeper && mkdir /tmp/kafka-logs

cd $KAFKA_HOME && \
cd ./config 
touch hosts

sleep 15
nslookup $HOSTNAME_ZOOKEEPER > zk.cluster

# Configure Zookeeper
NO_ZK=$(($(wc -l < zk.cluster) - 2))

while [ $NO_ZK -le $NO_ZOOKEEPER ] ; do
        rm -rf zk.cluster
        nslookup $HOSTNAME_ZOOKEEPER > zk.cluster
        NO_ZK=$(($(wc -l < zk.cluster) - 2))#
	NO_ZK=$(($NO_ZK + 1))
done

# Configure Zookeeper
#NO_ZK=$(($(wc -l < zk.cluster) - 2))#

#if [ $NO_ZK -ge 1 ] ; then#
#	while read line; do                                                                                                        
#                ip=$(echo $line | grep -oE "\b(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b")
#                echo "$ip" >> zk.cluster.tmp                                                                                       
#        done < 'zk.cluster' 
#else#
#	while [ $NO_ZK -lt 1 ] ; do
#		while read line; do
#			ip=$(echo $line | grep -oE "\b(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b")
#echo "$ip" >> zk.cluster.tmp
#		done < 'zk.cluster'	
#		sleep 5
#		nslookup $HOSTNAME_ZOOKEEPER > zk.cluster

		# Configure Zookeeper
#		NO_ZK=$(($(wc -l < zk.cluster) - 2))
#	done
#fi	

while read line; do                                                                                                        
      ip=$(echo $line | grep -oE "\b(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b")
      echo "$ip" >> zk.cluster.tmp                                                                                       
done < 'zk.cluster'

#rm zk.cluster
	
#while read line; do                                                                                                        
#                ip=$(echo $line | grep -oE "\b(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b")
#                echo "$ip" >> zk.cluster.tmp                                                                                       
#        done < 'zk.cluster'

sort -n zk.cluster.tmp > zk.cluster.tmp.sort
mv zk.cluster.tmp.sort zk.cluster.tmp

tail --lines $NO_ZOOKEEPER zk.cluster.tmp > zk.cluster.new

no_instances=1
while read line; do
        if [ "$line" != "" ]; then
		myindex=$(echo $line | sed -e 's/\.//g')
		echo "server.$myindex=$line:2888:3888" >> $KAFKA_HOME/config/zookeeper.properties
		echo "$(cat hosts) $line:2181" >  hosts
		no_instances=$(($no_instances + 1))
	fi
done < 'zk.cluster.new'

index=0

nslookup $HOSTNAME_KAFKA > kafka.cluster

NO_K=$(($(wc -l < kafka.cluster) - 2))

#This section is completely commented
#if [ $NOK -ge 1 ] ; then#
#	while read line; do                                                                                                        
#                ip=$(echo $line | grep -oE "\b(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b")
#                echo "$ip" >> kafka.cluster.tmp                                                                                    
#        done < 'kafka.cluster'
#else#
#	while [ $NOK -lt 1 ] ; do
#		while read line; do
#			ip=$(echo $line | grep -oE "\b(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b")
#			echo "$ip" >> kafka.cluster.tmp
#		done < 'kafka.cluster'
#
#		nslookup $HOSTNAME_KAFKA > kafka.cluster
#
#		NOK=$(($(wc -l < kafka.cluster) - 2))
#	done
#fi

while [ $NO_K -le $NO ] ; do
        rm -rf kafka.cluster
        nslookup $HOSTNAME_KAFKA > kafka.cluster
        NO_K=$(($(wc -l < kafka.cluster) - 2))
	NO_K=$(($NO_K + 1))
done

while read line; do
	ip=$(echo $line | grep -oE "\b(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b")
	echo "$ip" >> kafka.cluster.tmp
done < 'kafka.cluster'

rm kafka.cluster

sort -n kafka.cluster.tmp > kafka.cluster.tmp.sort
mv kafka.cluster.tmp.sort kafka.cluster.tmp

tail --lines $NO kafka.cluster.tmp > kafka.cluster.new

index=1

while read line; do
	if [ "$line" != "" ]; then
		if [ "$line" == "$local_ip" ]; then
			oct3=$(echo $line | tr "." " " | awk '{ print $3 }')
			oct4=$(echo $line | tr "." " " | awk '{ print $4 }')
			index=$oct3$oct4
			current_index=$index
			cp $KAFKA_HOME/config/server.properties $KAFKA_HOME/config/server-$index.properties
			sed "s/broker.id=0/broker.id=$index/" $KAFKA_HOME/config/server-$index.properties >> $KAFKA_HOME/config/server-$index.properties.tmp
			mv $KAFKA_HOME/config/server-$index.properties.tmp $KAFKA_HOME/config/server-$index.properties
			
			sed "s/#advertised.listeners=PLAINTEXT:\/\/your.host.name:9092/advertised.listeners=PLAINTEXT:\/\/$local_ip:9092/" $KAFKA_HOME/config/server-$index.properties >> $KAFKA_HOME/config/server-$index.properties.tmp
			mv $KAFKA_HOME/config/server-$index.properties.tmp $KAFKA_HOME/config/server-$index.properties
		else
			index=$(($index + 1))
		fi
	fi
done < 'kafka.cluster.new'

# configure all the hosts in the cluster in the server.properties file
sed -i 's/^ *//' hosts 
sed -e 's/\s/,/g' hosts > hosts.txt

content=$(cat $KAFKA_HOME/config/hosts.txt)

rm hosts.txt

touch hosts 

if [ "$HOSTNAME_ZOOKEEPER" != "" ]; then
	#sleep 5
	#nslookup $HOSTNAME_ZOOKEEPER >> zk.cluster

	#echo "the zookeeper cluster is the following one"
	#cat zk.cluster

	# Configure Zookeeper
	NO=$(($(wc -l < zk.cluster) - 2))

	while read line; do
		ip=$(echo $line | grep -oE "\b(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b")
		echo "$ip" >> zk.cluster.tmp
	done < 'zk.cluster'
	rm zk.cluster

	sort -n zk.cluster.tmp > zk.cluster.tmp.sort
	mv zk.cluster.tmp.sort zk.cluster.tmp
	
	tail --lines $NO_ZOOKEEPER zk.cluster.tmp > zk.cluster.new

	no_instances=1
	while read line; do
        	if [ "$line" != "" ]; then
			echo "$(cat hosts) $line:2181" >  hosts
			no_instances=$(($no_instances + 1))
		fi
	done < 'zk.cluster.new'

fi

sed -i 's/^ *//' hosts 
sed -e 's/\s/,/g' hosts > hosts.txt

content=$(cat hosts.txt)
ZKHOSTS=$content

rm hosts
rm hosts.txt

while read line; do
	
	oct3=$(echo $line | tr "." " " | awk '{ print $3 }')
	oct4=$(echo $line | tr "." " " | awk '{ print $4 }')
	index=$oct3$oct4
	
	if [ "$index" == "$current_index" ] ; then
		sed "s/zookeeper.connect=localhost:2181/zookeeper.connect=$content/" $KAFKA_HOME/config/server-$index.properties >> $KAFKA_HOME/config/server-$index.properties.tmp && \
		mv  $KAFKA_HOME/config/server-$index.properties.tmp  $KAFKA_HOME/config/server-$index.properties
		
		sed "s/zookeeper.connect=127.0.0.1:2181/zookeeper.connect=$content/" $KAFKA_HOME/config/consumer.properties >> $KAFKA_HOME/config/consumer.properties.tmp
		mv $KAFKA_HOME/config/consumer.properties.tmp $KAFKA_HOME/config/consumer.properties
		
		if [ "$KAFKA_PATH" != "" ]; then
			path1=$(echo $KAFKA_PATH | tr "\\" " " | awk '{ print $1 }')
			path2=$(echo $KAFKA_PATH | tr "\\" " " | awk '{ print $2 }')
			path3=$(echo $KAFKA_PATH | tr "\\" " " | awk '{ print $3 }')
			path=$path1$path2$path3
			#cd $path && mkdir kafka-logs-$HOSTNAME_KAFKA
			cd $path && mkdir kafka-logs-$index
			#sed "s/log.dirs.*/log.dirs=$KAFKA_PATH\/kafka-logs-$HOSTNAME_KAFKA/"  $KAFKA_HOME/config/server-$index.properties >>  $KAFKA_HOME/config/server-$index.properties.tmp &&
        		sed "s/log.dirs.*/log.dirs=$KAFKA_PATH\/kafka-logs-$index/"  $KAFKA_HOME/config/server-$index.properties >>  $KAFKA_HOME/config/server-$index.properties.tmp &&
			mv  $KAFKA_HOME/config/server-$index.properties.tmp  $KAFKA_HOME/config/server-$index.properties
			
			#to be deleted
			sed "s/dataDir.*/dataDir=$KAFKA_PATH"  $KAFKA_HOME/config/zookeeper.properties >>  $KAFKA_HOME/config/zookeeper.properties.tmp &&
        		mv  $KAFKA_HOME/config/zookeeper.properties.tmp  $KAFKA_HOME/config/zookeeper.properties
		fi
		
		#path=$path"/kakfa-logs-$HOSTNAME_KAFKA/.lock"
		path=$path"/kafka-logs-$index/.lock"
		rm $path
	fi
done < '/opt/kafka_2.11-0.10.1.0/config/kafka.cluster.new'

cp /opt/kafka_2.11-0.10.1.0/config/kafka.cluster.new /opt/kafka_2.11-0.10.1.0/config/kafka.cluster
cp /opt/kafka_2.11-0.10.1.0/config/zk.cluster.new /opt/kafka_2.11-0.10.1.0/config/zk.cluster

rm /opt/kafka_2.11-0.10.1.0/config/zk.cluster.new
rm /opt/kafka_2.11-0.10.1.0/config/zk.cluster.tmp
rm /opt/kafka_2.11-0.10.1.0/config/kafka.cluster.new
rm /opt/kafka_2.11-0.10.1.0/config/kafka.cluster.tmp

echo "akka.logger-startup-timeout = 30s" >> /opt/kafka-manager-1.3.3.7/conf/application.conf
echo "akka.logger-startup-timeout = 30s" >> /tmp/kafka-manager/conf/application.conf

sed "s/basicAuthentication.enabled=false/basicAuthentication.enabled=true/" /tmp/kafka-manager/conf/application.conf >> /tmp/kafka-manager/conf/application.conf.tmp
mv /tmp/kafka-manager/conf/application.conf.tmp /tmp/kafka-manager/conf/application.conf

sed "s/basicAuthentication.enabled=false/basicAuthentication.enabled=true/" /opt/kafka-manager-1.3.3.7/conf/application.conf >> /opt/kafka-manager-1.3.3.7/conf/application.conf.tmp
mv /opt/kafka-manager-1.3.3.7/conf/application.conf.tmp /opt/kafka-manager-1.3.3.7/conf/application.conf

sed "s/bootstrap.servers=localhost:9092/bootstrap.servers=$local_ip:9092/" $KAFKA_HOME/config/producer.properties >> $KAFKA_HOME/config/producer.properties.tmp
mv $KAFKA_HOME/config/producer.properties.tmp $KAFKA_HOME/config/producer.properties

# Start Kafka Manager Service
$KAFKA_MANAGER_HOME/bin/kafka-manager -Dkafka-manager.zkhosts=$ZKHOSTS -Dapplication.home=$path  > /dev/null &

# Start Kafka servicE
$KAFKA_HOME/bin/kafka-server-start.sh $KAFKA_HOME/config/server-$current_index.properties
