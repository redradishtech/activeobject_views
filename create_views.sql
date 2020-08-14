-- Define our tables
\i common.sql

-- Generate 'create schema' SQL
select distinct 'create schema ' || shortname || '; comment on schema ' || shortname || ' is ''' || coalesce(fullname,'') || ' (' || pluginkey || ') plugin table views mirroring the ' || hash || '.* tables.'';' from ourplugininfo;

-- Generate 'create view' SQL
select 'create view ' || schema_qualified_tablename || ' AS SELECT ' || colclauses || ' FROM "' || table_name || '"; comment on view ' || schema_qualified_tablename || ' is ''View of ' || table_name || ''';' from 
(
select 
schema_qualified_tablename
, table_name
, string_agg(colclause, ', ') AS colclauses
from ourplugininfo
group by 1, 2
) xxx;
