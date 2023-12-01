#!/bin/bash
# Este script crea 1 maestro, 2 esclavos y 3 servicios de sentinelas en Docker Swarm.

docker network create \
  --driver overlay \
  testes_network

SWARM_MASTER=192.168.205.125
REDIS_VOLUME=redis-data

# Crea un volumen para persistencia compartida
docker volume create $REDIS_VOLUME

# Maestro
docker service create  \
  --name redis-master \
  --network=testes_network \
  --publish 6379:6379 \
  --replicas 1 \
  --mount type=volume,source=$REDIS_VOLUME,target=/data \
  redis:alpine redis-server --port 6379 --dir /data;

# Esclavo 1
docker service create  \
  --name redis-slave-1 \
  --network=testes_network \
  --publish 6380:6380 \
  --replicas 1 \
  --mount type=volume,source=$REDIS_VOLUME,target=/data \
  redis:alpine redis-server --slaveof $SWARM_MASTER 6379 --port 6380 --dir /data --slave-announce-ip $SWARM_MASTER;

# Esclavo 2
docker service create  \
  --name redis-slave-2 \
  --network=testes_network \
  --publish 6381:6381 \
  --replicas 1 \
  --mount type=volume,source=$REDIS_VOLUME,target=/data \
  redis:alpine redis-server --slaveof $SWARM_MASTER 6379 --port 6381 --dir /data --slave-announce-ip $SWARM_MASTER;

# Sentinels
docker service create \
  --replicas 3 \
  --name redis-sentinel \
  --publish 26379:26379 \
  --mount type=volume,source=$REDIS_VOLUME,target=/data \
  redis:alpine \
  sh -c "\
  echo -e 'port 26379\n\
  dir /data \n\
  sentinel monitor mymaster $SWARM_MASTER 6379 2\n\
  sentinel down-after-milliseconds mymaster 5000\n\
  sentinel parallel-syncs mymaster 1\n\
  sentinel failover-timeout mymaster 10000\n\
  sentinel announce-ip $SWARM_MASTER\n\
  ' > sentinel.conf; \
  redis-server sentinel.conf --sentinel --dir /data";
