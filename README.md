# ActiveObject Table Views

Create easily queryable views over Jira/Confluence activeobjects tables in Postgres.

## Background


If you've ever poked around in a Jira or Confluence database, you will notice hundreds of table names beginning with `AO_`

```sql
                                 List of relations
┌────────┬─────────────────────────────────────────────┬──────────┬──────┐
│ Schema │                    Name                     │   Type   │ Owner│
├────────┼─────────────────────────────────────────────┼──────────┼──────┤
│ public │ AO_013613_ACTIVITY_SOURCE                   │ table    │ jira │
│ public │ AO_013613_ACTIVITY_SOURCE_ID_seq            │ sequence │ jira │
│ public │ AO_013613_EXPENSE                           │ table    │ jira │
│ public │ AO_013613_EXPENSE_ID_seq                    │ sequence │ jira │
│ public │ AO_013613_EXP_CATEGORY                      │ table    │ jira │
│ public │ AO_013613_EXP_CATEGORY_ID_seq               │ sequence │ jira │
│ public │ AO_013613_FAVORITES                         │ table    │ jira │
│ public │ AO_013613_FAVORITES_ID_seq                  │ sequence │ jira │
│ public │ AO_013613_HD_SCHEME                         │ table    │ jira │
│ public │ AO_013613_HD_SCHEME_DAY                     │ table    │ jira │
│ public │ AO_013613_HD_SCHEME_DAY_ID_seq              │ sequence │ jira │
│ public │ AO_013613_HD_SCHEME_ID_seq                  │ sequence │ jira │
```
These tables are storing data for plugins (aka 'apps' or add-ons).

These are table names only a Java developer could love. Writing SQL queries is a royal pain because:
* It is not obvious which tables apply to which plugin. The 6 character code is [derived from the plugin key](https://developer.atlassian.com/server/framework/atlassian-sdk/table-names/) and is necessary to prevents naming conflicts, but obscures the table's origin.
* Both table names and column names are uppercase, requiring (in Postgres) everything to be quoted in SQL (`select "NAME", "PROGRAM_ID" from "AO_AEFED0_TEAM_V2" ...`).



## Nicer AO Views


The solution is to generate SQL views shadowing each AO table. Given a database with tables:

```
public.AO_AEFED0_LOCATION
public.AO_AEFED0_MEMBERSHIP
public.AO_AEFED0_PGP_GROUP
public.AO_AEFED0_PGP_GROUP_TO_TEAM
```

we generate a much more readable set of tables:
```
tempo.location
tempo.membership
tempo.pgp_group
tempo.pgp_group_to_team
```

Specifically:
* The prefix is stripped
* names of tables and columns are downcased
* tables for each plugin are grouped in a schema (`tempo`)


## How to use

### Creating the views


Log into your Jira/Confluence server, and switch to a user able to create tables, e.g. the `postgres` account:
```bash
jturner@jturner-desktop:~$ sudo su - postgres
postgres@jturner-desktop:~$ 
```
Ensure you can connect to your database (Jira or Confluence):
```
postgres@jturner-desktop:~$ psql -tAq jira -c "select 'It works';"
It works
```

Download this repository:

```bash
postgres@jturner-desktop:~$ git clone https://github.com/redradishtech/activeobject_views
Cloning into 'activeobject_views'...
postgres@jturner-desktop:~$ cd activeobject_views/
postgres@jturner-desktop:~/activeobject_views$ 
```

Run `create_views.sql`. This will generate SQL:

```
postgres@jturner-desktop:~/activeobject_views$ cat create_views.sql | psql jira -tAXq  > views.sql
```
Check the contents of `views.sql`, which should contain SQL creating a bunch of schemas and tables for the plugins found in your database:

```
create schema jiramobile; comment on schema jiramobile is 'Mobile Plugin for Jira (com.atlassian.jira.mobile.jira-mobile-rest) plugin table views mirroring the AO_0A5972.* tables.';
create schema jiraprojects; comment on schema jiraprojects is 'Jira Projects Plugin (com.atlassian.jira.jira-projects-plugin) plugin table views mirroring the AO_550953.* tables.';
create schema jiramail; comment on schema jiramail is 'Atlassian Jira - Plugins - Mail Plugin (com.atlassian.jira.jira-mail-plugin) plugin table views mirroring the AO_3B1893.* tables.';
create schema inform; comment on schema inform is 'Jira inform - event plugin (com.atlassian.jira.plugins.inform.event-plugin) plugin table views mirroring the AO_733371.* tables.';
create schema simplifiedplanner; comment on schema simplifiedplanner is 'Simplified Planner for JIRA (com.jtricks.simplified-planner) plugin table views mirroring the AO_3BA132.* tables.';
create schema issueactionstodo; comment on schema issueactionstodo is 'Issue Actions Todo (com.redmoon.jira.issue-actions-todo) plugin table views mirroring the AO_9701C1.* tables.';
....
create view portfolioteam.team AS SELECT "AVATAR_URL" as avatar_url, "ID" as id, "SHAREABLE" as shareable, "TITLE" as title FROM "AO_82B313_TEAM"; comment on view portfolioteam.team is 'View of AO_82B313_TEAM';
create view dvcs.pr_participant AS SELECT "APPROVED" as approved, "DOMAIN_ID" as domain_id, "ID" as id, "PULL_REQUEST_ID" as pull_request_id, "ROLE" as role, "USERNAME" as username FROM "AO_E8B6CC_PR_PARTICIPANT"; comment on view dvcs.pr_participant is 'View of AO_E8B6CC_PR_PARTICIPANT';
create view jsd.customglobaltheme AS SELECT "HEADER_BADGE_BGCOLOR" as header_badge_bgcolor, "HEADER_BGCOLOR" as header_bgcolor, "HEADER_LINK_COLOR" as header_link_color, "HEADER_LINK_HOVER_BGCOLOR" as header_link_hover_bgcolor, "HEADER_LINK_HOVER_COLOR" as header_link_hover_color, "ID" as id, "LOGO_ID" as logo_id, "CONTENT_LINK_COLOR" as content_link_color, "HELP_CENTER_TITLE" as help_center_title, "CONTENT_TEXT_COLOR" as content_text_color, "CUSTOM_CSS" as custom_css FROM "AO_54307E_CUSTOMGLOBALTHEME"; comment on view jsd.customglobaltheme is 'View of AO_54307E_CUSTOMGLOBALTHEME';
...
```

If you are happy with the result, run `views.sql` against your database:

```bash
postgres@jturner-desktop:~/activeobject_views$ psql jira < views.sql
```

Alternatively you could have combined the steps with:
```
postgres@jturner-desktop:~/activeobject_views$ cat create_views.sql | psql jira -tAXq | psql jira
```

In Postgres you can now list the new schemas with `\dn`:

```sql
postgres@jturner-desktop:~/activeobject_views$ psql jira
jira=# \dn
            List of schemas
	    ┌────────────────────┬──────┐
	    │        Name        │ Owner│
	    ├────────────────────┼──────┤
	    │ agile              │ jira │
	    │ agilepoker         │ jira │
	    │ api                │ jira │
	    │ atlnotifications   │ jira │
	    │ automation         │ jira │
	    │ backbonesync       │ jira │
	    │ betterpdf          │ jira │
	    │ configmanagercore  │ jira │
	    .....
```
It is also sometimes useful to limit psql to just tables on a particular schema with `set search_path=<plugin>`. E.g:

```sql
jira=# set search_path='tempo';
SET
jira=# \d
                   List of relations
		   ┌────────┬─────────────────────┬──────┬──────┐
		   │ Schema │        Name         │ Type │ Owner│
		   ├────────┼─────────────────────┼──────┼──────┤
		   │ tempo  │ account_v1          │ view │ jira │
		   │ tempo  │ activity_source     │ view │ jira │
		   │ tempo  │ budget              │ view │ jira │
		   │ tempo  │ category_type       │ view │ jira │
		   │ tempo  │ category_v1         │ view │ jira │
		   │ tempo  │ customer_permission │ view │ jira │
		   │ tempo  │ customer_v1         │ view │ jira │
		   ....

```

### Deleting the views

To drop all the created views, run the SQL generated by `drop_views.sql`:
```
postgres@jturner-desktop:~/activeobject_views$ cat drop_views.sql | psql jira -tAXq | psql jira
```

:warning: Do not leave views permanently present in your database, as views prevent schema modifications, and later when you update Jira or its plugins you would get errors:

```
org.postgresql.util.PSQLException: ERROR: cannot alter type of a column used by a view or rule
```

You can drop and recreate the views at any time, e.g. after installing a new plugin.



# Addendums

### Safety

Jira and Confluence do not care at all about new schemas, or even new tables in the `public` schema.

However if you were to upgrade a plugin, and that upgrade happens to drop a plugin table (something [Atlassian recommends against](https://developer.atlassian.com/server/framework/atlassian-sdk/upgrading-your-plugin-and-handling-data-model-updates/), that would break, as the table now has a view dependency (and no `CASCADE` was given). For this reason I suggest not leaving these views defined in a production database. Run `drop_views.sql` after you're done to remove them.

### Plugin names

The [jiraplugins.csv](jiraplugins.csv) mapping of `AO_` hashes to plugin keys was originally scraped from https://confluence.atlassian.com/jirakb/list-of-jira-server-ao-table-names-and-vendors-973498988.html. The equivalent [confluenceplugins.csv](confluenceplugins.csv) is constructed from scratch. If you use a plugin without a mapping, please submit a ticket and I'll add it.


### Database support

The above is Postgres-specific; however I understand `information_schema` is part of the SQL standard, as is double quotes to delimit identifiers, and so the whole thing might work in other databases too.
