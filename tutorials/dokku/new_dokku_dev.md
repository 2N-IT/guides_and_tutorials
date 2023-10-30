# Add new dev to dokku access

**You will ofc. need an ssh key from the user. The server that hosts dokku and dokku itself will need to know the public key**

Once the user has access to the server, dokku access itself can be given by:

```bash
dokku ssh-keys:add developer_name file_with_his_key.pub
```

You can create a tempfile in which you input the dev's pub key, so that dokku can read it and copy it into its internals.

Dokku ssh is needed for **deployments**

Server ssh authorization is needed if you want to **manually enter the machine that hosts dokku**

If you **do not** want someone to have access to enter the server and run stuff on dokku, only give them dokku access

More at: https://dokku.com/docs/deployment/user-management/
