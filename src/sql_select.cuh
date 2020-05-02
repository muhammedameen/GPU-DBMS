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
#include "ColType.cuh"

// #include "cudaOps.cuh"

#include "../sql-parser/src/SQLParserResult.h"
#include "../sql-parser/src/SQLParser.h"
#include "../sql-parser/src/sqlhelper.h"
#include "../sql-parser/src/sql/Expr.h"

class sql_select {
public:
    static void execute(std::string &query);

};

__global__ void selectKernel(void *data, int rowSize, int *offset, int offsetSize, ColType *types, whereExpr *exprs);
#endif //DBASE_SQL_SELECT_CUH
