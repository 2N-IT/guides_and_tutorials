# Nginx file size

Often case with first deploy of a new app is that QA/client thats tests file upload, uploads files much larger than nginx default allows for or you were expecting to.

Since dokku uses nginx, but through a proxy, and you should not modify its nginx file directly, you can change that size by using:

```bash
dokku nginx:set my-app-name client-max-body-size 50m
```

`m` is for megabytes

default value restoration:

```bash
dokku nginx:set node-js-app client-max-body-size
```

stop and start after making those changes
