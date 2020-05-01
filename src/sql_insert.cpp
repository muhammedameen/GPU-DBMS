//
// Created by ameen on 01/05/20.
//

#include "sql_insert.h"

sql_insert::sql_insert(std::string &query) {
    result = hsql::SQLParser::parseSQLString(query);
    columnNames = std::vector<std::string>();
}
