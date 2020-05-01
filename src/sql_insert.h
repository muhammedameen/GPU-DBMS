//
// Created by ameen on 01/05/20.
//

#ifndef DBASE_SQL_INSERT_H
#define DBASE_SQL_INSERT_H
#include <string>

#include "Metadata.h"
#include "Data.h"
#include "../sql-parser/src/sql/InsertStatement.h"
#include "../sql-parser/src/SQLParserResult.h"
#include "../sql-parser/src/SQLParser.h"
#include "../sql-parser/src/sqlhelper.h"
#include "../sql-parser/src/sql/Expr.h"

class sql_insert {
public:
    explicit sql_insert(std::string &query);

    static void execute(std::string &query);

    hsql::SQLParserResult *result;
    std::vector<std::string> columnNames;
    std::vector<hsql::Expr*> values;
    std::string tableName;
    Metadata mdata;

};


#endif //DBASE_SQL_INSERT_H
