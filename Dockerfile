FROM  ubuntu:16.10

RUN apt-get update && \
      apt-get -y install sudo

RUN useradd -m docker && echo "docker:docker" | chpasswd && adduser docker sudo
USER docker
CMD /bin/bash

RUN sudo apt-get install -y git

RUN git clone https://github.com/facebookincubator/beringei.git
WORKDIR beringei
RUN sudo ./setup_ubuntu.sh
RUN mkdir build && cd build && cmake .. && make
RUN ./beringei/tools/beringei_configuration_generator --host_names $(hostname) --file_path /tmp/beringei.json
RUN ./beringei/service/beringei_main \
    -beringei_configuration_path /tmp/beringei.json \
    -create_directories \
    -sleep_between_bucket_finalization_secs 60 \
    -allowed_timestamp_behind 300 \
    -bucket_size 600 \
    -buckets $((86400/600)) \
    -logtostderr \
    -v=2
    
RUN while [[ 1 ]]; do \
     ./beringei/tools/beringei_put \
        -beringei_configuration_path /tmp/beringei.json \
        testkey ${RANDOM} \
        -logtostderr -v 3 \
    sleep 30 \
  done

RUN ./beringei/tools/beringei_get \
    -beringei_configuration_path /tmp/beringei.json \
    testkey \
    -logtostderr -v 3
    

# overwrite this with 'CMD []' in a dependent Dockerfile
CMD ["/bin/bash"]
