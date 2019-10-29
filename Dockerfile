FROM nvidia/cuda:9.0-cudnn7-devel-ubuntu16.04
ADD https://mirror.oxfordnanoportal.com/software/analysis/ont-guppy_3.2.4_linux64.tar.gz ./
RUN tar -xzf ont-guppy_3.2.4_linux64.tar.gz \
 && rm ont-guppy_3.2.4_linux64.tar.gz
ENV PATH="/ont-guppy/bin:${PATH}"
