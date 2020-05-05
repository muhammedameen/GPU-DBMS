//
// Created by ameen on 01/05/20.
//

#ifndef DBASE_SQL_INSERT_CUH
#define DBASE_SQL_INSERT_CUH
#include <string>

#include "Metadata.cuh"
#include "Data.cuh"
#include "../sql-parser/src/sql/InsertStatement.h"
#include "../sql-parser/src/SQLParserResult.h"
#include "../sql-parser/src/SQLParser.h"
#include "../sql-parser/src/sqlhelper.h"
#include "../sql-parser/src/sql/Expr.h"

class sql_insert {
public:


    static void execute(std::string &query);

};


#endif //DBASE_SQL_INSERT_CUH
