local dsn = "pgsql://hostaddr=127.0.0.1 dbname=freeswitch user=freeswitch password='' options='-c client_min_messages=NOTICE' application_name='freeswitch'";


local dbh = freeswitch.Dbh(hsn);
assert(dbh:connected());

dbh:query("INSERT INTO my_table VALUES(1, 'foo')") -- populate the table
