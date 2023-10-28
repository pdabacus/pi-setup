#disk cleaner dockerfile
FROM alpine:latest
USER root
RUN apk add bash bc
WORKDIR /app
COPY src/repeat.sh /app/
COPY src/clean_disk.sh /app/
CMD ["bash", "repeat.sh"]
