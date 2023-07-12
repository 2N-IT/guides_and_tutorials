# Deploying a Ruby on Rails Application on Dokku

Dokku is an open-source Platform as a Service that you can self-host. It's similar to Heroku but allows you to maintain control of your own infrastructure. This guide will show you how to deploy a Ruby on Rails application to Dokku.

## Prerequisites
- Access to a virtual private server.
- A Ruby on Rails application that you'd like to deploy.
- Knowledge of Git. You'll need to push your application to Dokku using Git.


## Step 1: Install Dokku
Install the latest stable version of Dokku. [Here is the snippet.](https://dokku.com/docs/getting-started/installation/#1-install-dokku) Follow 1-2 points from the link. 

## Step 2: Install PostgreSQL
```bash
sudo dokku plugin:install https://github.com/dokku/dokku-postgres.git
```


## Step 3: Install Redis
```bash
sudo dokku plugin:install https://github.com/dokku/dokku-redis.git redis
```

## Step 4: Install letsencrypt
1. Download dokku plugin
```bash
dokku plugin:install https://github.com/dokku/dokku-letsencrypt.git
```
2. Config letsencrypt
```bash
dokku config:set --global DOKKU_LETSENCRYPT_EMAIL=your-email@domain.tld
```
3. Enable auto-renewal
```bash
dokku letsencrypt:cron-job --add
```
## Step 5: Creat dokku app
```bash
dokku apps:create app_name
```

## Step 6: Creat a PostgreSQL service
1. Create PostgreSQL service
```bash
dokku postgres:create app_name
```
2. Set DATABASE_URL env variable by linking the service
```bash
dokku postgres:link app_name app_name
```

## Step 7: Creat a Redis service
1. Create a Redis service
```bash
dokku redis:create app_name
```
2. Set REDIS_URL env variable by linking the service
```bash
dokku redis:link app_name app_name
```

## Step 8: Set other ENV variables
For example you can set RAILS_MASTER_KEY env
```bash
dokku config:set app_name RAILS_MASTER_KEY=221341234123421342134
```
You can also change RAILS_ENV
```
dokku config:set app_name RAILS_ENV=staging
dokku config:set app_name RACK_ENV=staging
```
## Step 9: Setup Procfile
To instruct dokku on deploying the Rails application, generate a Procfile in the app's root directory.

1. Create Procfile in you root app folder
```bash
touch Procfile
```
2. Now populate this file with the necessary commands:
```
web: bundle exec puma -C config/puma.rb
release: bundle exec rails db:migrate
worker: bundle exec sidekiq
```
3. Enable the worker

We want to run Rails web server and Sidekiq worker. By default, there is only one process - web: 1

```bash
dokku ps:scale app_name worker=1
```
## Step 10: Deploy the app
1. Add remote to git
git remote add <custom remote name> dokku@<server IP>:<dokku app name>
```bash
git remote add <alias> dokku@<server IP>:<app_name>
examples:
- git remote add staging dokku@51.83.134.198:app_name
- git remote add production dokku@51.83.134.118:app_name
```
2. Push to remote git
```
git checkout main
git push staging
```
or
```
git checkout 'feature/task_1'
git push staging 'feature/task_1':main
```

## Step 11: Add SSL Certificate
You can enable ssl certifivate only for domains.
1. Setup DNS record `A` for the domain, with the value of the IP address of the VPS
2. Add domain for you app
```
dokku domains:add app_name example.com
```
3. Enable letsencrypt for you domain:
```bash
dokku letsencrypt:enable app_name
```
  
# Conclusion
Deploying to Dokku involves a few more steps than deploying to Heroku, but it gives you much more control over your infrastructure. This guide should get you up and running, but Dokku has many more features to explore. For more information, check out the [Dokku documentation](https://dokku.com).
  
# Handy commands
- Open the container with the app
```bash
dokku enter app_name web/worker
```
- Run rails console
```bash
dokku enter app_name web/worker
rails console
```
 
- Nginx logs
```bash
dokku nginx:access-logs app_name -t
```
  
- Rails logs
```bash
dokku logs app_name -t
```
  
# Others
- [Adding new developer to access dokku]()
- [Changing Nginx limit for uploading files]()
- [Persistent storage]()
- [Deploy app with Github Actions]()
- [Other plugings]()
- [How to copy file from dokku container to local machine](./dokku/how_to_copy_file_from_dokku_container.md)
