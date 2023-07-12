# How to copy file form dokku container

## List all containers
```bash
sudo docker ps
```

## Find the container you want to copy file from

I want to copy file from container with name `bravekids.web.1`

## Enter the container
```bash
sudo docker exec -it bravekids.web.1 bash
```

## Find the file you want to copy

My file is in `/app/tmp` folder

```bash
ls /app/tmp/my_file.txt
```

## Exit container

```bash
exit
```

## Copy file from container to local machine

```bash
sudo docker cp bravekids.web.1:/app/tmp/my_file.txt .
```

## Exit vps

## Copy file from vps to local machine

```bash
scp root@vps_ip:/root/my_file.txt .
```
