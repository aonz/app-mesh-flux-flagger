FROM node:12.4.0

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

RUN apt-get update && apt-get install -y apt-utils apt-transport-https dnsutils nano \
    && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
    && apt-get update && apt-get install -y yarn

COPY package.json /usr/src/app/
RUN yarn

COPY . /usr/src/app

ENV PORT 80
EXPOSE 80

CMD ["npm", "start"]