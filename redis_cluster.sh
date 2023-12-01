#!/bin/bash
#This script creates 1 master, 2 slaves and 3 sentinels services in docker swarm.

docker network create \
  --driver overlay \
  testes_network

SWARM_MASTER=192.168.205.125

#Master
docker service create  \
--name redis-master \
--network=testes_network \
--publish 6379:6379 \
--replicas 1 \
redis:alpine redis-server  \
--port 6379;

#Slave1
docker service create  \
--name redis-slave-1 \
--network=testes_network \
--publish 6380:6380 \
--replicas 1 \
redis:alpine redis-server \
 --slaveof redis-master 6379  \
 --port 6380 \
 --slave-announce-ip $SWARM_MASTER

#Slave2
docker service create  \
--name redis-slave-2 \
--network=testes_network \
--publish 6381:6381 \
--replicas 1 \
redis:alpine redis-server  \
--slaveof redis-master 6379  \
--port 6381 \
--slave-announce-ip $SWARM_MASTER

#sentinels:
docker service create \
--replicas 3 \
 --name redis-sentinel \
 --publish 26379:26379 \
redis:alpine \
sh -c "\
echo -e 'port 26379\n\
dir /tmp \n\
sentinel monitor mymaster  $SWARM_MASTER 6379 2\n\
sentinel down-after-milliseconds mymaster 5000\n\
sentinel parallel-syncs mymaster 1\n\
sentinel failover-timeout mymaster 10000\n\
sentinel announce-ip $SWARM_MASTER\n\
' >  sentinel.conf; \
redis-server \
sentinel.conf \
--sentinel \
";
