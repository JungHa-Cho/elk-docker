#!/bin/bash

DOCKER_ES_NAME=es-single-test
DOCKER_LOGSTASH_NAME=st-single-test
DOCKER_BEATS_NAME=bt-single-test
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
  --net $DOCKER_ELASTIC_NETWORK_NAME \
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
  --net host \
  -v $(pwd)/logstash/config/logstash.yml:/usr/share/logstash/config/logstash.yml \
  -v $(pwd)/logstash/pipeline/:/usr/share/logstash/pipeline/ \
  -p 5044:5044 \
  docker.elastic.co/logstash/logstash:7.5.1

echo ""
echo "###################"
echo "# BEATS CONTAINER #"
echo "###################"
echo ""

docker pull docker.elastic.co/beats/metricbeat:7.5.1

docker stop $DOCKER_BEATS_NAME

docker rm $DOCKER_BEATS_NAME

docker run -itd --name $DOCKER_BEATS_NAME \
  --mount type=bind,source=/proc,target=/hostfs/proc,readonly \
  --mount type=bind,source=/sys/fs/cgroup,target=/hostfs/sys/fs/cgroup,readonly \
  --mount type=bind,source=/,target=/hostfs,readonly \
  --net=host \
  -v $(pwd)/beats/metric/metricbeat.yml/:/usr/share/metricbeat/metricbeat.yml \
  docker.elastic.co/beats/metricbeat:7.5.1 -e -system.hostfs=/hostfs -e
#  -E output.logstash.hosts=["localhost:5044"]
#  -E output.elasticsearch.hosts=["localhost:9200"]

echo ""
echo "####################"
echo "# KIBANA CONTAINER #"
echo "####################"
echo ""

docker pull docker.elastic.co/kibana/kibana:7.5.1

docker stop $DOCKER_KIBANA_NAME

docker rm $DOCKER_KIBANA_NAME

docker run -itd --name $DOCKER_KIBANA_NAME \
  --net $DOCKER_ELASTIC_NETWORK_NAME \
  -v $(pwd)/kibana/kibana.yml:/usr/share/kibana/config/kibana.yml \
  -p 5601:5601 \
  docker.elastic.co/kibana/kibana:7.5.1

echo ""

docker ps -a
