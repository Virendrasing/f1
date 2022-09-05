#!/usr/bin/env bash
# Author : Manas Kale (manas@infinite-uptime.com)

# Assumptions :
    # - Docker is installed
    # - Docker-compose is installed
    # - Java and Maven are installed
    # - Run on a Linux based system

# 1. Build the docker image
# 2. Run docker-compose images
# 3. Using the Flink runtime present in the custom docker image, submit all 6 jobs

# See https://ci.apache.org/projects/flink/flink-docs-stable/deployment/resource-providers/standalone/docker.html#flink-with-docker-compose
# for reference. Access web UI at localhost:8081

# If class or package names are changed in the source code these also need to be changed.
readonly BASIC_PRE="feature_summarization.iu.basic_features.pre.BasicPreProcessJob"
readonly BASIC_POST="feature_summarization.iu.basic_features.post.BasicPostProcessJob"
readonly ADV_PRE="feature_summarization.iu.advanced_features.pre.AdvPreProcessJob"
readonly ADV_POST="feature_summarization.iu.advanced_features.post.AdvPostProcessJob"
readonly KAFKA_CONNECTOR="flink-sql-connector-kafka_2.11-1.11.0.jar"

# Helper command string to execute commands in the docker container
readonly DOCKER_EXEC="docker exec -it summarization-jobmanager"

echo "Starting docker-compose in background..."
#docker-compose -f data-pipeline-services.yml up -d
# use docker-compose stop to stop containers

# Launch java jobs from within docker container
echo "Summarization pipeline properties: "
#$DOCKER_EXEC cat usrlib/pipeline.properties

# ********************** BASIC FEATURES *****************************
# Submit basic_features preprocessor
echo "Submitting $BASIC_PRE..."
$DOCKER_EXEC bin/flink run -c $BASIC_PRE -d usrlib/flink_summarization-0.1.jar

# Submit basic_features postprocessor
echo "Submitting $BASIC_POST..."
$DOCKER_EXEC bin/flink run -c $BASIC_POST -d usrlib/flink_summarization-0.1.jar

# Submit basic_features summarizer
echo "Submitting basic features streaming job..."
$DOCKER_EXEC bin/flink run -d -py pyFlink/basic_streaming_job.py -j pyFlink/$KAFKA_CONNECTOR
# ********************************************************************

# ********************** ADVANCED FEATURES *****************************
# Submit advanced_features preprocessor
echo "Submitting $ADV_PRE..."
$DOCKER_EXEC bin/flink run -c $ADV_PRE -d usrlib/flink_summarization-0.1.jar

# Submit advanced_features postprocessor
echo "Submitting $ADV_POST..."
$DOCKER_EXEC bin/flink run -c $ADV_POST -d usrlib/flink_summarization-0.1.jar

# Submit advanced_features summarizer
echo "Submitting advanced features streaming job..."
$DOCKER_EXEC bin/flink run -d -py pyFlink/advanced_streaming_job.py -j pyFlink/$KAFKA_CONNECTOR

echo "Finished!"

# ********************************************************************
