FROM node:16-alpine3.16
RUN apk update
COPY ./src /opt/app
WORKDIR /opt/app
CMD ["npm", "start"]