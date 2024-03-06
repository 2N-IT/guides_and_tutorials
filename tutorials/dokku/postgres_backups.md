
# DOKKU - cron job to export postgres

## 1. Prepare the script file:

- create a new .sh file

```
# Define your database name e.g. bellow
DB_NAME="psbk-pre-prod"
# Directory to store the exports e.g. bellow
EXPORT_DIR="/home/abramowicza/exports"
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

- REMEMBER!!! you need to customise DB_NAME and EXPORT_DIR

## 2. Create the bakup directory:

```mkdir /home/abramowicza/exports```

## 3. Setup the CRON job:

- first check current con settings

```
 psbkstg@vps-405b6199:~$ crontab -l
no crontab for psbkstg
```

- add the script fromt step 1 to the config 

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

```path_to_script
 /home/abramowicza/export_db.sh
 0 0 * * * path_to_script
```

- You should see something liek this as a result:

``` crontab: installing new crontab ``` 

- Check the correct configuration is set

``````
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
0 0 * * * /home/psbkstg/export_db.sh
```
