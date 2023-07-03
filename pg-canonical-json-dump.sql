create table tmp_canonical_dump as
select jsonb_object_agg(s.schema_name, to_jsonb(s.*) - '{catalog_name,schema_name}'::text[]
    || jsonb_build_object('tables', 
      (select jsonb_object_agg(t.table_name, to_jsonb(t.*) - '{table_catalog,table_schema,table_name}'::text[]
          || jsonb_build_object('columns', 
            (select jsonb_object_agg(c.column_name, to_jsonb(c.*) - '{udt_catalog,table_catalog,table_schema,table_name,column_name,ordinal_position}'::text[])
              from information_schema.columns c
              where c.table_schema = t.table_schema and c.table_name = t.table_name)
	      )
        )
        from information_schema.tables t
        where t.table_schema = s.schema_name
      )
    ))
    from information_schema.schemata s
    where schema_name not in ('pg_catalog', 'information_schema');
  
copy tmp_canonical_dump to 'c:\temp\canonical-dump.json';

drop table tmp_canonical_dump;
