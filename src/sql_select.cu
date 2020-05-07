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
joinKernel(void *left, void *right, void *join, myExpr *joinExpr, int *offset, int numCols, ColType *types, int rowSizeL, int rowSizeR, int numRowsL, int numRowsR,
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
        // printRowDevice(row, types, offsetSize);
        // Error in eval
        eval(row, offset, types, joinExpr, res, resType);
        flag = false;
        if (resType == RESTYPE_INT) {
            flag = *(int *)res != 0;
        } else if (resType == RESTYPE_FLT) {
            flag = *(float *)res != 0;
        }
        free(res);
        if (!flag) continue;
        // Add this row to new table
        printRowDevice(row, types, numCols);
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

                std::vector<myExpr> joinCondition;
                exprToVec(table->join->condition, joinCondition, d->mdata.columns);
                myExpr *joinCondition_d;
                cudaMalloc(&joinCondition_d, joinCondition.size() * sizeof(myExpr));
                cudaMemcpy(joinCondition_d, &joinCondition[0], sizeof(myExpr) * joinCondition.size(),
                           cudaMemcpyHostToDevice);

                std::vector<int> offsets(d->mdata.columns.size() + 1);
                offsets[0] = 0;
                for (int i = 1; i <= d->mdata.columns.size(); ++i) {
                    offsets[i] = offsets[i - 1] + d->mdata.datatypes[i - 1].size;
                }
                int *offsets_d;
                cudaMalloc(&offsets_d, sizeof(int) * ( d->mdata.columns.size() + 1));
                cudaMemcpy(offsets_d, &offsets[0], sizeof(int) * (d->mdata.columns.size() + 1), cudaMemcpyHostToDevice);

                ColType *type_d;
                cudaMalloc(&type_d, sizeof(ColType) *  d->mdata.columns.size());
                cudaMemcpy(type_d, &d->mdata.datatypes[0], sizeof(ColType) *  d->mdata.columns.size(), cudaMemcpyHostToDevice);

                Data dL(table->join->left->name);
                dL.chunkSize = d->chunkSize;
                Data dR(table->join->right->name);
                dR.chunkSize = d->chunkSize;
                void *join = malloc(d->chunkSize * d->chunkSize * d->mdata.rowSize), *join_d; // Upto n^2 rows can be stored
                void *dataL = malloc(d->chunkSize * dL.mdata.rowSize), *dataL_d;
                void *dataR = malloc(d->chunkSize * dR.mdata.rowSize), *dataR_d;
                cudaMalloc(&join_d, d->chunkSize * d->chunkSize * d->mdata.rowSize);
                cudaMalloc(&dataL_d, dL.chunkSize * dL.mdata.rowSize);
                cudaMalloc(&dataR_d, dR.chunkSize * dR.mdata.rowSize);
                int rowsReadL = dL.read(dataL), rowsReadR;
                cudaMemcpy(dataL_d, dataL, rowsReadL * dL.mdata.rowSize, cudaMemcpyHostToDevice);
                unsigned int numRowsJoin = 0;
                unsigned int *numRowsJoin_d;
                cudaMalloc(&numRowsJoin_d, sizeof(unsigned int));

                // for (auto leaf : joinCondition) {
                //     printf("TYPE: %d, ival: %ld, fval: %f, sval: %s, left: %d, right: %d\n", leaf.type, leaf.iVal, leaf.fVal,
                //            leaf.sVal, leaf.childLeft, leaf.childRight);
                // }
                // for (int i = 0; i <= d->mdata.columns.size(); ++i) {
                //     printf("%d ", offsets[i]);
                // }
                // printf("%zu\n", d->mdata.columns.size());
                // printf("\n");
                // for (int i = 0; i < d->mdata.columns.size(); ++i) {
                //     printf("(%d, %d)", d->mdata.datatypes[i].type, d->mdata.datatypes[i].size);
                // }
                // printf("\n");
                // printf("%d\n", dL.mdata.rowSize);
                // printf("%d\n", dR.mdata.rowSize);

                while (rowsReadL > 0) {
                    // TODO: implement resetRead()
                    dR.restartRead();
                    rowsReadR = dR.read(dataR);
                    cudaMemcpy(dataR_d, dataR, rowsReadR * dR.mdata.rowSize, cudaMemcpyHostToDevice);
                    while (rowsReadR > 0) {
                        joinKernel<<<1, 512>>>(dataL_d, dataR_d, join_d, joinCondition_d, offsets_d, d->mdata.columns.size(),
                                               type_d, dL.mdata.rowSize, dR.mdata.rowSize, rowsReadL, rowsReadR,
                                               numRowsJoin_d);
                        cudaDeviceSynchronize();
                        cudaError_t err = cudaGetLastError();
                        if (err != cudaSuccess) {
                            printf("Error at %d: %s\n", __LINE__, cudaGetErrorString(err));
                        }
                        cudaMemcpy(join, join_d, numRowsJoin, cudaMemcpyDeviceToHost);
                        cudaMemcpy(&numRowsJoin, numRowsJoin_d, sizeof(unsigned int), cudaMemcpyDeviceToHost);
                        d->write(join, (int)numRowsJoin * d->mdata.rowSize);
                        rowsReadR = dR.read(dataR);
                        cudaMemcpy(dataR_d, dataR, rowsReadR * dR.mdata.rowSize, cudaMemcpyHostToDevice);
                    }
                    rowsReadL = dL.read(dataL);
                    cudaMemcpy(dataL_d, dataL, rowsReadL * dL.mdata.rowSize, cudaMemcpyHostToDevice);
                }
                printf("_________________________________\n");
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
            printf("Where clause");
            std::vector<myExpr> tree;

            auto expr = stmt->whereClause;
            exprToVec(expr, tree, d->mdata.columns);
            free(expr);

            int rowSize = d->mdata.rowSize;
            void *data = malloc(d->chunkSize * rowSize);
            void *data_d;
            int numCols = d->mdata.columns.size();
            cudaSetDevice(0);
            cudaDeviceReset();

            ColType *type_d;
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
            d->~Data();
            free(d);
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