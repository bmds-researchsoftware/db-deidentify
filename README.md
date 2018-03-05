# db-deidentify
Creates a local deidentified pg\_dump of a remote postgres database.

## Installing
There are no prerequisites other than Ruby and the bundler gem.
* Clone the repo to your machine

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
