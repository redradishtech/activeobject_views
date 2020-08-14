
-- Dump all our CSV into the 'allpluginhashes' table.
create temp table allpluginhashes(hash varchar(9), pluginkey varchar, fullname varchar, shortname varchar);
\copy allpluginhashes(hash, pluginkey, shortname, fullname) from 'jiraplugins.csv' delimiter ',' csv header;
\copy allpluginhashes(hash, pluginkey, shortname, fullname) from 'confluenceplugins.csv' delimiter ',' csv header;

-- The 'pluginhashes' view ignores duplicate hashes, which we may get from plugins that work in Jira and Confluence.
create temp view pluginhashes  AS select distinct on (hash) hash, pluginkey, fullname, shortname from allpluginhashes ;


-- Now get metadata for each AO table.
-- Sample records:
-- ┌───────────┬──────────────────────┬────────────────────────────────┬────────────────────────────────┬────────────────────────────────┐
-- │   hash    │         tbl          │           table_name           │              col               │          column_name           │
-- ├───────────┼──────────────────────┼────────────────────────────────┼────────────────────────────────┼────────────────────────────────┤
-- │ AO_2D3BEA │ folio_format         │ AO_2D3BEA_FOLIO_FORMAT         │ date_format                    │ DATE_FORMAT                    │
-- │ AO_88263F │ read_notifications   │ AO_88263F_READ_NOTIFICATIONS   │ id                             │ ID                             │
-- │ AO_ED4628 │ token                │ AO_ED4628_TOKEN                │ createdat                      │ CREATEDAT                      │
-- │ AO_F1B27B │ key_component        │ AO_F1B27B_KEY_COMPONENT        │ id                             │ ID                             │
-- │ AO_F1B27B │ history_record       │ AO_F1B27B_HISTORY_RECORD       │ event_time_millis              │ EVENT_TIME_MILLIS              │
-- ....
create temp table aotables AS
                select left(table_name, 9) AS hash
                , lower(regexp_replace(table_name, 'AO_.{6}_', '')) AS tbl
                , table_name
                , lower(column_name) as col
                , column_name
                from information_schema.columns JOIN information_schema.tables USING (table_name)
                WHERE table_name~'^AO_'
                order by columns.ordinal_position asc
;

-- Construct our final 'ourplugininfo' table, joining static plugin info ('pluginhashes') with our actual AO tables ('aotables').
-- This table is used in create_views.sql and drop_view.sql
-- Sample record:
-- ┌─[ RECORD 1 ]───────────────┬──────────────────────────────────────────────────────────────────┐
-- │ schema_qualified_tablename │ tempoplanner.folio_format                                        │
-- │ colclause                  │ "DATE_FORMAT" as date_format                                     │
-- │ hash                       │ AO_2D3BEA                                                        │
-- │ tbl                        │ folio_format                                                     │
-- │ table_name                 │ AO_2D3BEA_FOLIO_FORMAT                                           │
-- │ col                        │ date_format                                                      │
-- │ column_name                │ DATE_FORMAT                                                      │
-- │ pluginkey                  │ com.tempoplugin.tempo-plan-core                                  │
-- │ fullname                   │ System Plugin: Tempo Planning API                                │
-- │ shortname                  │ tempoplanner                                                     │
create temp table ourplugininfo AS
	select 
	shortname || '.' || tbl AS schema_qualified_tablename
	, '"' || column_name || '" as ' || col AS colclause
	, *
	FROM aotables JOIN pluginhashes USING (hash)
	WHERE shortname is not null;

