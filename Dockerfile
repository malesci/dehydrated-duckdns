ARG BUILD_FROM=alpine:latest
FROM $BUILD_FROM

# Setup base
ARG DEHYDRATED_VERSION=0.7.0

RUN apk add --no-cache curl openssl bash jq\
  && curl -s -o /usr/bin/dehydrated \
    "https://raw.githubusercontent.com/lukas2511/dehydrated/v${DEHYDRATED_VERSION}/dehydrated" \
  && chmod a+x /usr/bin/dehydrated

# Copy datadedd
COPY data/*.sh /

RUN chmod +x /hooks.sh /run.sh
CMD [ "/run.sh" ]
