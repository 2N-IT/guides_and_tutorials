# Github Actions Deploy

The basic idea is to use Github Actions to deploy to Dokku. This is a simple example of how to do it. It will push a deploy whenever `staging` branch gets an update

A private ssh key that has push access to the Dokku instance is required. Store it in GitHub secrets.

This is how a key might look like:

```bash
-----BEGIN OPENSSH PRIVATE KEY-----
MIIEogIBAAKCAQEAjLdCs9kQkimyfOSa8IfXf4gmexWWv6o/IcjmfC6YD9LEC4He
qPPZtAKoonmd86k8jbrSbNZ/4OBelbYO0pmED90xyFRLlzLr/99ZcBtilQ33MNAh
...
SvhOFcCPizxFeuuJGYQhNlxVBWPj1Jl6ni6rBoHmbBhZCPCnhmenlBPVJcnUczyy
zrrvVLniH+UTjreQkhbFVqLPnL44+LIo30/oQJPISLxMYmZnuwudPN6O6ubyb8MK
-----END OPENSSH PRIVATE KEY-----
```

So generate it, place it on the server in file called for example `github-actions` in `.ssh` folder, and place it as a secret in github. Alongside the public key (just add `.pub` to the name of the publci key).


`12.34.567.890` is the IP address of the Dokku instance.

```yaml
name: Staging deploy
on:
  push:
    branches: [ staging ]

jobs:
  deploy:
    name: Deploy to staging
    runs-on: ubuntu-latest
    steps:
      - name: Cloning repo
        uses: actions/checkout@v2
        with:
          fetch-depth: 0
      - name: Push to dokku
        uses: dokku/github-action@master
        with:
          git_remote_url: 'ssh://dokku@12.34.567.890:22/my-app-staging'
          ssh_private_key: ${{ secrets.SSH_PRIVATE_KEY_STAGING }}
          branch: main
```

More info: https://github.com/marketplace/actions/dokku
