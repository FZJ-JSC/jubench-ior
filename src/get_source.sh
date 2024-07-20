#!/usr/bin/env bash

BRANCHNAME="3.3.0"
COMMITID="9959a61"

if [ ! -d "ior" ]; then
    git clone -b $BRANCHNAME --recursive https://github.com/hpc/ior.git && cd ior && git checkout -b $BRANCHNAME $COMMITID 
else
    echo "Directory ior already exists"
fi
