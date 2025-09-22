FROM git.jiaxing.website/ppqwqqq/arch-devel:1.2

WORKDIR /app 

COPY . /app

RUN mkdir -p build && \
    cd build && \
    cmake .. && \
    make 

CMD ["/bin/bash"]
