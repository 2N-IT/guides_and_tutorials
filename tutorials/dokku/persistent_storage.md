# Persistent storage

Dokku rebuilds the container after each deploy. This means that all files that are not in the repository will be lost. To avoid this, we need to use persistent storage.

Ensure directory that will hold the persistent storage exists (will create it if it doesn't):

```bash
dokku storage:ensure-directory my-app-name
```

```bash
# dokku storage:mount <server_path>:<path_inside_docker_image>
# dokku by default is mounting rails application in path: /app
dokku storage:mount my-app-name /var/lib/dokku/data/storage/my-app-name-storage:/app/storage
```

Then just restart

```bash
dokku ps:restart bravekids
```

Your uploaded files won't disappear after deploy.

### DockerFile Warning!

the default /app used in all examples may not work if you use dockerfile
instead of starting the path with /app use the folder specified in WORKDIR
