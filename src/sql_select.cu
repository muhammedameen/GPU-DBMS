//
// Created by gautam on 25/04/20.
//

#include "sql_select.cuh"

#define NUM_THREADS 512

__global__ void selectKernel(void *data, int rowSize, int *offset, int offsetSize, ColType *types, myExpr *exprs, int numRows) {
    int rowsPerBlock = (numRows + NUM_THREADS - 1) / NUM_THREADS;
    unsigned int start = rowsPerBlock * threadIdx.x;
    unsigned int end = rowsPerBlock * (threadIdx.x + 1);

    void *res;
    int resType = 1;
    void *row;
    bool flag;
    for (unsigned int i = start; i < end; i++) {
        row = (char *)data + i * rowSize;
        eval(row, offset, types, exprs, res, resType);
        if (i < numRows) {
            flag = false;
            if (resType == RESTYPE_INT) {
                flag = *(int *) res != 0;
            } else if (resType == RESTYPE_FLT) {
                flag = *(float *) res != 0;
            }
            free(res);
            if (!flag) continue;
            // Condition is satisfied, write code here
            printRowDevice(row, types, offsetSize);
        }
    }
}

__global__ void
joinKernel(void *left, void *right, void *join, int joinType, myExpr *joinExpr, int *offset, int offsetSize, ColType *types, int rowSizeL, int rowSizeR, int numRowsL, int numRowsR,
           unsigned int *numRowsRes) {
    if (threadIdx.x == 0) {
        *numRowsRes = 0;
    }
    __syncthreads();
    int rowsPerThread = (numRowsL * numRowsR + NUM_THREADS - 1) / NUM_THREADS;
    const unsigned start = rowsPerThread * threadIdx.x;
    const unsigned end = rowsPerThread * (threadIdx.x + 1);
    const int rowSizeRes = rowSizeL + rowSizeR;

    void *res;
    int resType = 0;
    void *row;
    bool flag;
    unsigned old;
    for (unsigned i = start; i < end; ++i) {
        // row i in join is obtained from i / numRowsR from left and i % numRowsR in right
        unsigned l = i / numRowsR, r = i % numRowsR;
        if (l >= numRowsL || r >= numRowsR) break;
        row = malloc(rowSizeRes);
        memcpy(row, left, rowSizeL);
        memcpy((char *) row + rowSizeL, right, rowSizeR);
        eval(row, offset, types, joinExpr, res, resType);
        flag = false;
        if (resType == RESTYPE_INT) {
            flag = *(int *)res == 0;
        } else if (resType == RESTYPE_FLT) {
            flag = *(float *)res == 0;
        }
        free(res);
        if (!flag) continue;
        // Add this row to new table
        old = atomicInc(numRowsRes, numRowsL * numRowsR);
        memcpy((char *) join + old * rowSizeRes, row, rowSizeRes);
    }
}


void sql_select::execute(std::string &query) {

    hsql::SQLParserResult *result;
    std::vector<std::string> columnNames;

    result = hsql::SQLParser::parseSQLString(query);
    columnNames = std::vector<std::string>();

    if(result->isValid()){
        const auto *stmt = (const hsql::SelectStatement *) result->getStatement(0);
        // Get column names
        for (hsql::Expr* expr : *stmt->selectList){
            switch (expr->type) {
                case hsql::kExprStar:
                    columnNames.emplace_back("*");
                    break;
                case hsql::kExprColumnRef:
                    columnNames.emplace_back(expr->name);
                    break;
                // case hsql::kExprTableColumnRef:
                // inprint(expr->table, expr->name, numIndent);
                // break;
                case hsql::kExprLiteralFloat:
                    columnNames.push_back(std::to_string(expr->fval));
                    break;
                case hsql::kExprLiteralInt:
                    columnNames.push_back(std::to_string(expr->ival));
                    break;
                case hsql::kExprLiteralString:
                    columnNames.emplace_back(expr->name);
                    break;
                // TODO: kExprFunctionRef (Distinct ?), kExprOperator (col1 + col2 ?)
                // case hsql::kExprFunctionRef:
                //     inprint(expr->name, numIndent);
                //     inprint(expr->expr->name, numIndent + 1);
                //     break;
                // case hsql::kExprOperator:
                //     printOperatorExpression(expr, numIndent);
                //     break;
                default:
                    fprintf(stderr, "Unrecognized expression type %d\n", expr->type);
                    return;
            }
        }
        // Get tables reference
        auto table = stmt->fromTable;
        Data *d;
        switch (table->type) {
            case hsql::kTableName:
                // inprint(table->name, numIndent);
                d = new Data(table->name);
                break;
            // case hsql::kTableSelect:
            //     // printSelectStatementInfo(table->select, numIndent);
            //     break;
            case hsql::kTableJoin: {
                //     // inprint("Join Table", numIndent);
                //     // inprint("Left", numIndent + 1);
                //     // printTableRefInfo(table->join->left, numIndent + 2);
                //     // inprint("Right", numIndent + 1);
                //     // printTableRefInfo(table->join->right, numIndent + 2);
                //     // inprint("Join Condition", numIndent + 1);
                //     // printExpression(table->join->condition, numIndent + 2);
                d = new Data(table->join->left->name, table->join->right->name);
                Data dL(table->join->left->name);
                dL.chunkSize = d->chunkSize;
                Data dR(table->join->right->name);
                dR.chunkSize = d->chunkSize;
                void *join = malloc(d->chunkSize * d->chunkSize * d->mdata.rowSize); // Upto n^2 rows can be stored
                void *dataL = malloc(d->chunkSize * dL.mdata.rowSize);
                void *dataR = malloc(d->chunkSize * dR.mdata.rowSize);
                int bytesReadL = dL.read(dataL), bytesReadR;
                // while (bytesReadL > 0) {
                //
                //     bytesReadR = dR.read(dataR);
                //     while (bytesReadR > 0) {
                //
                //     }
                // }
                break;
            }
            // case hsql::kTableCrossProduct:
            //     // for (TableRef* tbl : *table->list) printTableRefInfo(tbl, numIndent);
            //     break;
            default:
                printf("Will be handled later\n");
                return;
        }
        if (stmt->whereClause != nullptr) {
            // Get where
            std::vector<myExpr> tree;
            // printf("%s\n", tableNames[0].c_str());
            // Data d(tableNames[0]);

            auto expr = stmt->whereClause;
            exprToVec(expr, tree, d->mdata.columns);
            free(expr);

            int rowSize = d->mdata.rowSize;
            void *data = malloc(d->chunkSize * rowSize);
            void *data_d;
            int numCols = d->mdata.columns.size();
            ColType *type_d;
            cudaSetDevice(0);
            cudaDeviceReset();

            cudaMalloc(&type_d, sizeof(ColType) * numCols);
            cudaMemcpy(type_d, &d->mdata.datatypes[0], sizeof(ColType) * numCols, cudaMemcpyHostToDevice);
            myExpr *where_d;
            cudaMalloc(&where_d, sizeof(myExpr) * tree.size());
            cudaMemcpy(where_d, &tree[0], sizeof(myExpr) * tree.size(), cudaMemcpyHostToDevice);
            int *offsets = (int *) malloc(sizeof(int) * (numCols + 1));
            offsets[0] = 0;
            for (int i = 1; i <= numCols; i++) {
                offsets[i] = offsets[i - 1] + d->mdata.datatypes[i - 1].size;
            }
            int *offsets_d;
            cudaMalloc(&offsets_d, sizeof(int) * (numCols + 1));
            cudaMemcpy(offsets_d, offsets, sizeof(int) * (numCols + 1), cudaMemcpyHostToDevice);
            int numRows = d->read(data);

            // printing data in table
            // utils::printMultiple(data, d.mdata.datatypes, d.mdata.rowSize, d.mdata.rowCount);

            cudaMalloc(&data_d, d->chunkSize * rowSize);
            while (numRows > 0) {
                // printf("Inside\n");
                // fflush(stdout);
                cudaMemcpy(data_d, data, rowSize * numRows, cudaMemcpyHostToDevice);
                selectKernel<<<1, NUM_THREADS>>>(data_d, rowSize, offsets_d, numCols, type_d, where_d, numRows);
                // eval(data, offsets, &d.mdata.datatypes, &tree[0], , , 0);
                cudaDeviceSynchronize();
                cudaError_t err = cudaGetLastError();
                if (err != cudaSuccess) {
                    printf("Error at %d: %s\n", __LINE__, cudaGetErrorString(err));
                }
                numRows = d->read(data);
            }

            // Free all the data
            free(data);
            free(offsets);
            cudaFree(data_d);
            cudaFree(type_d);
            cudaFree(where_d);
            cudaFree(offsets_d);
        } else {
            // RETURN ALL ROWS
        }
    } else {
        fprintf(stderr, "Given string is not a valid SQL query.\n");
        fprintf(stderr, "%s (L%d:%d)\n",
                result->errorMsg(),
                result->errorLine(),
                result->errorColumn());
    }
    free(result);
}