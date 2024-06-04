
# DOKKU - cron job to export postgres database:

## 1. Create a directory for DB backups:
NOTE: remember that we do this using the `psbk` application as an example - in your own project you need to adjust the folder path accordingly


```mkdir /home/psbk/db_backups```

## 2. Prepare the script file:

- create a new shell script file in project directory (in this case e.g. `/home/psbk/db_backup_script.sh`)

```
# Assign the name of the database you want to back up (you can check the list of Postgres databases with the command "dokku postgres:list"):
DB_NAME="psbk-staging-db"

# Define a directory to store exported DB dumpes (you need to create such a directory- step 2):
EXPORT_DIR="/home/psbk/db_backups"

# Export the database
EXPORT_FILE="$EXPORT_DIR/$DB_NAME-$(date +\%Y\%m\%d\%H\%M\%S).dump"
dokku postgres:export "$DB_NAME" > "$EXPORT_FILE"

# Get the number of files in the export directory
num_files=$(find "$EXPORT_DIR" -maxdepth 1 -type f | wc -l)

# If there are more than three exports, remove the oldest ones
if [ "$num_files" -gt 3 ]; then
  files_to_remove=$(find "$EXPORT_DIR" -maxdepth 1 -type f | sort | head -n -3)
  for file in $files_to_remove; do
    if [ -e "$file" ]; then
      echo "Removing: $file"
      rm -- "$file"
    else
      echo "File not found: $file"
fi done
fi
```

- REMEMBER!!! you need to set DB_NAME and EXPORT_DIR according to the context of your application

## 3. Setup the CRON job:

- first check current con settings

```
 psbkstg@vps-405b6199:~$ crontab -l
no crontab for psbkstg
```

- add the script fromt step 2 to the config 

```
psbkstg@vps-405b6199:~$ crontab -e
- cron job to export postgres
 
  no crontab for psbkstg - using an empty one
Select an editor.  To change later, run 'select-editor'.
  1. /bin/nano        <---- easiest
  2. /usr/bin/vim.basic
  3. /usr/bin/mcedit
  4. /usr/bin/vim.tiny
  5. /bin/ed
Choose 1-5 [1]: 1
```

```
 0 0 * * * /home/psbk/db_backup_script.sh
```

- You should see something like this as a result:

``` crontab: installing new crontab ``` 

- Check the correct configuration is set

```
psbkstg@vps-405b6199:~$ crontab -l
# Edit this file to introduce tasks to be run by cron.
#
# Each task to run has to be defined through a single line
# indicating with different fields when the task will be run
# and what command to run for the task
#
# To define the time you can provide concrete values for
# minute (m), hour (h), day of month (dom), month (mon),
# and day of week (dow) or use '*' in these fields (for 'any').
#
# Notice that tasks will be started based on the cron's system
# daemon's notion of time and timezones.
#
# Output of the crontab jobs (including errors) is sent through
# email to the user the crontab file belongs to (unless redirected).
#
# For example, you can run a backup of all your user accounts
# at 5 a.m every week with:
# 0 5 * * 1 tar -zcf /var/backups/home.tgz /home/
#
# For more information see the manual pages of crontab(5) and cron(8)
#
# m h  dom mon dow   command
0 0 * * * /home/psbk/db_backup_script.sh
```


# DOKKU - restore dumped DB backup:
## 1. Go to the directory with dumped databases and check what database versions are possible to restore:
```
$ cd ~/backups/
$ ls
psbk-staging-db-20240603000002.dump  psbk-staging-db-20240604000001.dump  psbk-staging-db-20240605135354.dump
```
NOTE: please note that we only have 3 backups here - this is determined by the script we defined above

## 2. Restore the database from a backup file:
Command pattern:
```
dokku postgres:import dokku_db_service_name < path_to_dumped_file/file
```

So in our case it should look like this:
```
dokku postgres:import psbk-staging-db < ~/db_backups/psbk-staging-db-20240604000001.dump
```
And that's it
