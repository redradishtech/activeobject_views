-- Define our tables
\i common.sql

select distinct 'drop schema ' || shortname || ' cascade;' from ourplugininfo group by shortname;
