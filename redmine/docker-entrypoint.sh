#!/bin/bash

until mysqladmin ping -h fj_db --silent; do
  echo 'waiting for mysqld to be connectable...'
  sleep 2
done

sudo -u www-data bin/rake generate_secret_token
sudo -u www-data RAILS_ENV=production bin/rake db:migrate
bundle exec rake redmine:plugins:migrate RAILS_ENV=production

exec "$@"
