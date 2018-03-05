# db-deidentify
Creates a local deidentified pg\_dump of a remote postgres database.

## Getting started
There are no prerequisites other than Ruby and the bundler gem.
* Clone the repo to your machine
* Run `bundle install`
* Create a file called `db_conf.yml` your target project directory, such as
`./projects/nautilus/db_conf.yml`. This file is ignored by git and has the following format. 
<pre>
host: <b><i>remote_host_name</i></b>
user: <b><i>remote_host_user</i></b>
db_name: <b><i>target_database_name</i></b>
</pre>
* run the program using the `get_dump` executable and provide the project name as an argument, like
`./get_dump nautilus`

## Postgres setup on the remote server (for db admins)
Assumes you are useing peer authentication
1. Create a distinct user on the target host for this application
1. Create role for this user name on the target host for this application
1. Grant that role createdb privileges
  <pre>
  ALTER ROLE <b><i>role_name</i></b> WITH createdb;
  </pre>
1. Grant that user select privileges for the target database<br />
  * must be connected to the target\_db
  * note the distinction between ***creating\_role*** and ***role***

  <pre>
  GRANT SELECT ON ALL TABLES IN SCHEMA public TO <b><i>role</i></b>;
  ALTER DEFAULT PRIVILEGES FOR ROLE <b><i>creating_role</i></b> IN SCHEMA public GRANT SELECT ON TABLES TO <b><i>role</i></b>;
  GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO <b><i>role</i></b>;
  ALTER DEFAULT PRIVILEGES FOR ROLE <b><i>creating_role</i></b> IN SCHEMA public GRANT SELECT ON SEQUENCES TO <b><i>role</i></b>;
  </pre>
