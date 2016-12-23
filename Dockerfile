FROM resin/raspberrypi2-python:3.5

# https://resin.io/blog/building-arm-containers-on-any-x86-machine-even-dockerhub/
# https://github.com/resin-io-projects/armv7hf-debian-qemu.git
COPY qemu-arm-static /usr/bin/
COPY resin-xbuild /usr/bin/
RUN [ "qemu-arm-static", "/bin/sh", "-c", "ln -s resin-xbuild /usr/bin/cross-build-start; ln -s resin-xbuild /usr/bin/cross-build-end; ln /bin/sh /bin/sh.real" ]

RUN [ "cross-build-start" ]

VOLUME /config

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

RUN pip3 install --no-cache-dir colorlog cython

# For the nmap tracker, bluetooth tracker, Z-Wave, tellstick
RUN echo "deb http://download.telldus.com/debian/ stable main" >> /etc/apt/sources.list.d/telldus.list && \
    wget -qO - http://download.telldus.se/debian/telldus-public.key | apt-key add - && \
    apt-get update && \
    apt-get install -y --no-install-recommends nmap net-tools cython3 libudev-dev sudo libglib2.0-dev bluetooth libbluetooth-dev \
            libtelldus-core2 && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY script/build_python_openzwave script/build_python_openzwave
RUN script/build_python_openzwave && \
  mkdir -p /usr/local/share/python-openzwave && \
  ln -sf /usr/src/app/build/python-openzwave/openzwave/config /usr/local/share/python-openzwave/config

COPY requirements_all.txt requirements_all.txt
RUN pip3 install --no-cache-dir -r requirements_all.txt && \
    pip3 install mysqlclient psycopg2 uvloop

# Copy source
COPY . .

RUN [ "cross-build-end" ]

CMD [ "python", "-m", "homeassistant", "--config", "/config" ]
