//
// Created by gautam on 25/04/20.
//

#ifndef DBASE_SQL_SELECT_H
#define DBASE_SQL_SELECT_H

#include <string>

#include "whereExpr.h"
#include "../sql-parser/src/SQLParserResult.h"
#include "../sql-parser/src/SQLParser.h"
#include "../sql-parser/src/sqlhelper.h"
#include "../sql-parser/src/sql/Expr.h"

class sql_select {
public:
    explicit sql_select(std::string &query);

    static void execute(std::string &query);

    hsql::SQLParserResult *result;

    std::vector<std::string> columnNames;
    std::vector<std::string> tableNames;

    static void exprToVec(hsql::Expr *pExpr, std::vector<whereExpr> &vector);

    static whereExprType getOpType(hsql::Expr::OperatorType type, char opChar);
};


#endif //DBASE_SQL_SELECT_H
