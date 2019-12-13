FROM nvidia/cuda:9.0-cudnn7-devel-ubuntu16.04
RUN apt-get update
RUN apt-get install -y tabix python3-pip zip zlib1g-dev libbz2-dev liblzma-dev
RUN pip3 install --upgrade pip
RUN pip install NanoPlot
ADD https://mirror.oxfordnanoportal.com/software/analysis/ont-guppy_3.2.4_linux64.tar.gz ./
RUN tar -xzf ont-guppy_3.2.4_linux64.tar.gz \
 && rm ont-guppy_3.2.4_linux64.tar.gz
ENV PATH="/ont-guppy/bin:${PATH}"
