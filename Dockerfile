ARG BUILD_FROM=alpine:latest
FROM $BUILD_FROM

# Setup base
ARG DEHYDRATED_VERSION=0.7.0
RUN apk add --update curl && \
    rm -rf /var/cache/apk/*

RUN apk add --no-cache openssl curl bash \
  && curl -s -o /usr/bin/dehydrated \
    "https://raw.githubusercontent.com/lukas2511/dehydrated/v${DEHYDRATED_VERSION}/dehydrated" \
  && chmod a+x /usr/bin/dehydrated

# Copy datadedd
COPY data/*.sh /

RUN chmod +x /run.sh
CMD [ "/run.sh" ]
