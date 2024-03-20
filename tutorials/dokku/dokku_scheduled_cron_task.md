# Dokku scheduled cron tasks

I'm not sure if this is the best idea (since the Dokku documentation itself says "Regularly scheduled tasks can be a bit of a pain in Dokku"), but in some cases where e.g. Sideqik is overkill for just one cron - it might work

## Define command and schedule in app.json file (create it if it doesn't exist)
The `app.json` file for a given app can define a special cron key that contains a list of commands to run on given schedules. The following is a simple example `app.json` that effectively runs the command `dokku run $APP bundle exec rake servers:check_status` every 2 minutes:
```
{
  "cron": [
    {
      "command": "bundle exec rake servers:check_status",
      "schedule": "*/2 * * * *"
    }
  ]
}
```

`command:` A command to be run within the built app image. Specified commands can also be Procfile entries.

`schedule:` A cron-compatible scheduling definition upon which to run the command. In place of `*/2 * * * *` you can use also `@weekly`, `@daily`, `@hourly`, etc.

After deploy dokku scheduler should be updated.

To verify cron, type: 
```
dokku cron:list your-appliaction-name
```
