#!/bin/bash

rm -rf pdd_resource_*.zip
zip -r pdd_resource_$(date +%Y%m%d%H%M%S).zip . -x *.DS_Store* -x *.git* -x *.sh 
