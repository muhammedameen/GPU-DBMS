//
// Created by gautam on 07/05/20.
//

#ifndef DBASE_SQL_UPDATE_CUH
#define DBASE_SQL_UPDATE_CUH

#include "myExpr.cuh"
#include "Data.cuh"
#include "deviceUtil.cuh"
#include "Metadata.cuh"
#include "ColType.cuh"

#include "../sql-parser/src/SQLParserResult.h"
#include "../sql-parser/src/SQLParser.h"
#include "../sql-parser/src/sqlhelper.h"
#include "../sql-parser/src/sql/Expr.h"

class sql_update {
public:
    static void execute(std::string &query);
};

typedef struct UpdateExpr {
    int colId;
    myExpr *expr;
} UpdateExpr;

__global__ void
updateKernel(void *data, int rowSize, int *offset, int offsetSize, ColType *types, myExpr *exprs, int numRows,
             int *pInt, myExpr *ptr, int *pInt1);
#endif //DBASE_SQL_UPDATE_CUH
