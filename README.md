ELK 스택 싱글 노드로 테스트 환경 구성 가능한 쉘 스크립트 입니다.

## DOCKER COMPOSE 통일

## 스펙
- Bash Shell Script
- Docker
- Docker Elastic Search Container
- Docker Kibana Container
- Docker Beats Host Monitor Container
- Docker Beats Docker Monitor Container
- ELK STACK의 버전은 모두 7.5.1로 통일

## Elastic Search

- port 9200, 9300

## Beats

- Docker Server의 호스트 시스템 모니터링

## Logstash

- port 5044

## Kibana

- Docker Name으로 Elastic Search Link

## deploy.sh
```shell
#!/bin/bash

DOCKER_ES_NAME=es-single-test
DOCKER_LOGSTASH_NAME=st-single-test
DOCKER_HOST_BEATS_NAME=bt-single-test-host-monitor
DOCKER_CONTAINER_BEATS_NAME=bt-single-test-docker-monitor
DOCKER_KIBANA_NAME=ki-single-test

DOCKER_ELASTIC_NETWORK_NAME=elastic-network

# ES PORT IS localhost:9200 or localhost:9300
# BEATS is net = host means host metric send to localhost:9200
# KIBANA link means connect docker container ES
#
# KIBANA connect port is hostip:5601

# docker volume rm $(docker volume ls -q)

docker network create --driver bridge $DOCKER_ELASTIC_NETWORK_NAME

echo ""
echo "################"
echo "# ES CONTAINER #"
echo "################"
echo ""

docker pull docker.elastic.co/elasticsearch/elasticsearch:7.5.1

docker stop $DOCKER_ES_NAME

docker rm $DOCKER_ES_NAME

docker run -itd --name $DOCKER_ES_NAME \
  --network=$DOCKER_ELASTIC_NETWORK_NAME \
  -p 9200:9200 \
  -p 9300:9300 \
  -e "discovery.type=single-node" \
  -v $(pwd)/elasticsearch/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml \
  docker.elastic.co/elasticsearch/elasticsearch:7.5.1

# container logs view
#docker logs -f $PROCESS_NAME

# container bash shell connect
#docker exec -it $PROCESS_NAME /bin/bash

echo ""
echo "######################"
echo "# LOGSTASH CONTAINER #"
echo "######################"
echo ""

docker pull docker.elastic.co/logstash/logstash:7.5.1

docker stop $DOCKER_LOGSTASH_NAME

docker rm $DOCKER_LOGSTASH_NAME

docker run -itd --name $DOCKER_LOGSTASH_NAME \
  --network=$DOCKER_ELASTIC_NETWORK_NAME \
  -v $(pwd)/logstash/config/logstash.yml:/usr/share/logstash/config/logstash.yml \
  -v $(pwd)/logstash/pipeline/:/usr/share/logstash/pipeline/ \
  -p 5044:5044 \
  docker.elastic.co/logstash/logstash:7.5.1

echo ""
echo "####################"
echo "# KIBANA CONTAINER #"
echo "####################"
echo ""

docker pull docker.elastic.co/kibana/kibana:7.5.1

docker stop $DOCKER_KIBANA_NAME

docker rm $DOCKER_KIBANA_NAME

docker run -itd --name $DOCKER_KIBANA_NAME \
  --network=$DOCKER_ELASTIC_NETWORK_NAME \
  -v $(pwd)/kibana/kibana.yml:/usr/share/kibana/config/kibana.yml \
  -p 5601:5601 \
  docker.elastic.co/kibana/kibana:7.5.1

echo ""
echo "BEATS RUNNING BEFORE SLEEP"
echo ""

SET=$(seq 1 30)
for i in $SET
do
	echo "$i seconds"
	sleep 1s
done

echo ""
echo "###################"
echo "# BEATS CONTAINER #"
echo "###################"
echo ""

docker pull docker.elastic.co/beats/metricbeat:7.5.1

docker stop $DOCKER_HOST_BEATS_NAME

docker rm $DOCKER_HOST_BEATS_NAME

docker run -itd --name $DOCKER_HOST_BEATS_NAME \
  --user=root \
  --network=host \
  --cap-add sys_ptrace \
  --cap-add dac_read_search \
  --mount type=bind,source=/proc,target=/hostfs/proc,readonly \
  --mount type=bind,source=/sys/fs/cgroup,target=/hostfs/sys/fs/cgroup,readonly \
  --mount type=bind,source=/,target=/hostfs,readonly \
  -v $(pwd)/beats/metric/metricbeat.yml/:/usr/share/metricbeat/metricbeat.yml \
  docker.elastic.co/beats/metricbeat:7.5.1 -e -system.hostfs=/hostfs -e

echo ""
echo "#####################"
echo "# DOCKER MONITORING #"
echo "#####################"
echo ""

docker stop $DOCKER_CONTAINER_BEATS_NAME

docker rm $DOCKER_CONTAINER_BEATS_NAME

docker run -itd --name=$DOCKER_CONTAINER_BEATS_NAME \
  --user=root \
  --volume="$(pwd)/beats/metric/metricbeat.docker.yml:/usr/share/metricbeat/metricbeat.yml:ro" \
  --volume="/var/run/docker.sock:/var/run/docker.sock:ro" \
  --volume="/sys/fs/cgroup:/hostfs/sys/fs/cgroup:ro" \
  --volume="/proc:/hostfs/proc:ro" \
  --volume="/:/hostfs:ro" \
  docker.elastic.co/beats/metricbeat:7.5.1 metricbeat -e \
  -E output.elasticsearch.hosts=["172.19.0.1:9200"]  

echo ""

docker ps -a
```
