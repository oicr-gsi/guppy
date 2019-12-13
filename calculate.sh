#!/bin/bash

find . -type f -iname "*.fastq.gz" -exec md5sum {} \;