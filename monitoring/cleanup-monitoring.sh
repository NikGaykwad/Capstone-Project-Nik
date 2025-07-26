#!/bin/bash
docker stop prometheus blackbox_exporter sonarqube grafana
docker rm prometheus blackbox_exporter sonarqube grafana
