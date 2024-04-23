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

1. Generate new ssh key locally, e.q.: `ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_app_name_staging -C "gh_actions"`
2. Copy "private" key version: `cat ~/.ssh/id_rsa_app_name_staging`
3. Place copied "private" key version as a secret (e.g. as `SSH_PRIVATE_KEY_STAGING`) in Github (Settings -> Secrets and variables -> Actions -> New repository secret). 
4. Copy "public" key version: `cat ~/.ssh/id_rsa_app_name_staging.pub`
5. Place copied "public" key on server: 
   - go to .ssh folder: `cd ~/.ssh`
   - create file: `nano github_actions` (file name can be anything)
   - paste "public" key contents -> save and quit.
6. Then we need to add this key also to dokku:
   - (command: dokku ssh_keys:add key_name_in_dokku path_to_key) so in this case `sudo dokku ssh-keys:add gh_actions ~/.ssh/github_actions`

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
