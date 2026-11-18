FROM alpine:3.19 AS test
WORKDIR /app
COPY . .
RUN test -f index.html && echo "✅ index.html trouvé"

FROM nginx:alpine-slim
COPY . /usr/share/nginx/html
EXPOSE 80
FROM ubuntu:24.04
LABEL maintainer="Legeni"
RUN apt-get update
RUN apt-get install -y nginx git
RUN rm -Rf /var/www/html/*
RUN git clone https://github.com/Legeni07/restaurant.git /var/www/html/
EXPOSE 80
ENTRYPOINT ["/usr/sbin/nginx", "-g", "daemon off;"]
