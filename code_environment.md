# Local environment requirements

Goals:
- Faster onboarding
- Easier bug replication
- Better testing

## Local code execution

The less sofisticated method is to have a readme file with the steps and programs to install needed to run the application. Some tools can be used to handle different versions of ruby on the same machine but still issues may happen if you jump from project to project.

To both automate the process and avoid conflicts docker is a great solution. While not witout flaws it's worth to spend the effort to maintain a docker config.

[Docker setup tutorial](https://www.2n.pl/blog/using-docker-for-rails-development)

## Local data seeding
  
You should not be afraid of deleting your local database and resetting it. This happen commonly when working on the app requires a lot of data population done manually. We want to be able to easly dispose of any broken or corrupted local databases to be able to test multiple variants and scenarios witout hindering our ability to then work on the next task.

Note: clearly separate local test seeds and application seeds used on production (like seeding values for some drop lists etc)

## Mocking external services

We need to somehow handle the external dependencies of an application (emails, payment services...) Some ways are:

- use sandbox env account if available
- use mocked services
- simply disable when possible
