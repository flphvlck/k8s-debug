FROM debian:stable-slim

RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    dnsutils \
    iputils-ping \
    net-tools \
    nodejs \
    openssl \
    vim-nox \
    whois \
&& rm -rf /var/lib/apt/lists/*

COPY server.js .
EXPOSE 8080

CMD nodejs server.js
