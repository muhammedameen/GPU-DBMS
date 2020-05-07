//
// Created by ameen on 07/05/20.
//

#ifndef DBASE_SQL_DELETE_CUH
#define DBASE_SQL_DELETE_CUH

#include "myExpr.cuh"
#include "Data.cuh"
#include "deviceUtil.cuh"
#include "Metadata.cuh"
#include "ColType.cuh"

#include "../sql-parser/src/SQLParserResult.h"
#include "../sql-parser/src/SQLParser.h"
#include "../sql-parser/src/sqlhelper.h"
#include "../sql-parser/src/sql/Expr.h"

class sql_delete {
public:
    static void execute(std::string &query);
};

__global__ void deleteKernel(void *data, int rowSize, int *offset, int offsetSize, ColType *types, myExpr *exprs, int numRows,
             int *pInt, myExpr *ptr, int *pInt1);

#endif //DBASE_SQL_DELETE_CUH
