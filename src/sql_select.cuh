//
// Created by gautam on 25/04/20.
//

#ifndef DBASE_SQL_SELECT_CUH
#define DBASE_SQL_SELECT_CUH

#include <string>

#include "whereExpr.cuh"
#include "Data.cuh"
#include "deviceUtil.cuh"
#include "Metadata.cuh"
// #include "cudaOps.cuh"

#include "../sql-parser/src/SQLParserResult.h"
#include "../sql-parser/src/SQLParser.h"
#include "../sql-parser/src/sqlhelper.h"
#include "../sql-parser/src/sql/Expr.h"

class sql_select {
public:
    static void execute(std::string &query);

    static void exprToVec(hsql::Expr *pExpr, std::vector<whereExpr> &vector);

    static whereExprType getOpType(hsql::Expr::OperatorType type, char opChar);
};
#endif //DBASE_SQL_SELECT_CUH
