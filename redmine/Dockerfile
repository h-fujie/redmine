FROM ubuntu:24.04

# install packages
RUN apt update \
    && apt install -y sudo unzip \
    && apt install -y language-pack-ja-base language-pack-ja \
    && apt install -y build-essential zlib1g-dev libssl-dev libreadline-dev libyaml-dev libcurl4-openssl-dev libffi-dev \
    && apt install -y libmysqlclient-dev mariadb-client \
    && apt install -y apache2 apache2-dev \
    && apt install -y imagemagick fonts-takao-pgothic \
    && apt install -y subversion git

# set jp locale
RUN locale-gen ja_JP.UTF-8

# copy sources
WORKDIR /tmp
COPY ./source/ruby-3.2.6.tar.gz .
COPY ./source/redmine-5.1.5.tar.gz .
COPY ./plugins ./plugins

# install ruby
RUN tar xvf ./ruby-3.2.6.tar.gz \
    && cd ruby-3.2.6 \
    && ./configure --disable-install-doc \
    && make \
    && make install

# install redmine
RUN tar xvf ./redmine-5.1.5.tar.gz \
    && mv -f ./redmine-5.1.5 /var/lib/redmine \
    && chown -R www-data /var/lib/redmine

# copy configs
WORKDIR /var/lib/redmine
COPY ./config ./config

# copy plugins
RUN cd ./plugins \
    && unzip '/tmp/plugins/*.zip'

# setup redmine & plugins
RUN bundle config set --local without 'development test' \
    && bundle install

# setup passenger
RUN gem install passenger -v '6.0.22' -N \
    && passenger-install-apache2-module --auto --languages ruby

# setup apache
COPY ./apache/redmine.conf /etc/apache2/sites-available/redmine.conf
COPY ./apache/passenger.conf /etc/apache2/conf-available/passenger.conf
RUN echo ServerName 127.0.0.1 > /etc/apache2/conf-available/fqdn.conf \
    && a2enconf passenger \
    && a2enconf fqdn \
    && a2ensite redmine \
    && service apache2 restart

# delete temporary files
RUN rm -rf /tmp/ruby-3.2.6* /tmp/redmine-5.1.5* /tmp/plugins

COPY ./docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 80
CMD ["apachectl", "-D", "FOREGROUND"]
