from moz_sql_parser import parse
import json

print(json.dumps(parse("SELECT count(1) FROM jobs")))
# print(json.dumps(parse("CREATE TABLE tablename (col1 INT(32), col2, VARCHAR(255), col3 VARCHAR(123), col4 BOOL, col5 FLOAT(24);")))
print(json.dumps(parse("CREATE TABLE table1")))
