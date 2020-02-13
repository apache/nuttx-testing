FROM px4io/px4-dev-nuttx:2020-01-08

RUN git clone https://github.com/apache/incubator-nuttx nuttx \
	&& git clone https://github.com/apache/incubator-nuttx-apps apps

RUN cd nuttx \
	&& git checkout nuttx-8.2

RUN cd apps \
	&& git checkout nuttx-8.2

RUN cd nuttx \
	&& tools/configure.sh lm3s6965-ek:nsh \
	&& mv .config .config_lm3s6965-ek_nsh

COPY config-lm3s6965evb nuttx/.config

RUN cd nuttx \
	&& make

RUN apt-get update \
	&& DEBIAN_FRONTEND=noninteractive apt-get -y --quiet --no-install-recommends install \
		qemu-system-arm \
	&& apt-get -y autoremove \
	&& apt-get clean autoclean \
	&& rm -rf /var/lib/apt/lists/{apt,dpkg,cache,log} /tmp/* /var/tmp/*

CMD ["/usr/bin/qemu-system-arm","-M","lm3s6965evb","-kernel","/nuttx/nuttx","-serial","mon:stdio","-append","'console=ttyS0'","-nographic"]
