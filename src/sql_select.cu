//
// Created by gautam on 25/04/20.
//

#include "sql_select.cuh"

#define NUM_THREADS 512

__global__ void selectKernel(void *data, int rowSize, int *offset, int offsetSize, ColType *types, myExpr *exprs, int numRows, const int *dispCols, int numDispCols) {
    int rowsPerBlock = (numRows + NUM_THREADS - 1) / NUM_THREADS;
    unsigned int start = rowsPerBlock * threadIdx.x;
    unsigned int end = rowsPerBlock * (threadIdx.x + 1);

    void *res;
    int resType = 1;
    void *row;
    bool flag;
    for (unsigned int i = start; i < end; i++) {
        if (i < numRows) {
            row = (char *)data + i * rowSize;
            eval(row, offset, types, exprs, res, resType);
            flag = false;
            if (resType == RESTYPE_INT) {
                flag = *(int *) res != 0;
            } else if (resType == RESTYPE_FLT) {
                flag = *(float *) res != 0;
            }
            free(res);
            if (!flag) continue;
            // Condition is satisfied, write code here
            // printf("Row id: %d", i);
            printRowDevice(row, types, offsetSize, dispCols, numDispCols, offset);
        }
    }
}

__global__ void selectKernelRes(void *data, int rowSize, int *offset, int offsetSize, ColType *types, myExpr *exprs,
        int numRows, void *resData, unsigned int *top) {
    if (threadIdx.x == 0) {
        *top = 0;
    }
    __syncthreads();

    int rowsPerBlock = (numRows + NUM_THREADS - 1) / NUM_THREADS;
    unsigned int start = rowsPerBlock * threadIdx.x;
    unsigned int end = rowsPerBlock * (threadIdx.x + 1);

    void *res;
    int resType = 1;
    void *row;
    bool flag;
    unsigned int old;
    for (unsigned int i = start; i < end; i++) {
        if (i < numRows) {
            row = (char *)data + i * rowSize;
            eval(row, offset, types, exprs, res, resType);
            flag = false;
            if (resType == RESTYPE_INT) {
                flag = *(int *) res != 0;
            } else if (resType == RESTYPE_FLT) {
                flag = *(float *) res != 0;
            }
            free(res);
            if (!flag) continue;
            // Condition is satisfied, write code here
            // printRowDevice(row, types, offsetSize);
            old = atomicInc(top, numRows + 1);
            memcpy((char *) resData + old * rowSize, row, rowSize);
        }
    }
}

__global__ void
joinKernel(void *left, void *right, void *join, myExpr *joinExpr, int *offset, int numCols, ColType *types, int rowSizeL, int rowSizeR, int numRowsL, int numRowsR,
           unsigned int *numRowsRes, bool *matchedL) {
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

    unsigned l_prev = numRowsL + 1;
    unsigned l, r;
    for (unsigned i = start; i < end; ++i) {
        // row i in join is obtained from i / numRowsR from left and i % numRowsR in right
        l = i / numRowsR;
        r = i % numRowsR;
        if (l >= numRowsL || r >= numRowsR) break;
        // printf("[%d, %d, (%d, %d)]\n", threadIdx.x, i, l, r);
        row = malloc(rowSizeRes);
        memcpy(row, (char *)left + l * rowSizeL, rowSizeL);
        memcpy((char *) row + rowSizeL, (char *)right + r * rowSizeR, rowSizeR);
        eval(row, offset, types, joinExpr, res, resType);
        flag = false;
        if (resType == RESTYPE_INT) {
            flag = *(int *)res != 0;
        } else if (resType == RESTYPE_FLT) {
            flag = *(float *)res != 0;
        }
        free(res);
        if (!flag) continue;
        if (l != l_prev) {
            matchedL[l] = true;
            l_prev = l;
        }
        old = atomicInc(numRowsRes, numRowsL * numRowsR);
        memcpy((char *) join + old * rowSizeRes, row, rowSizeRes);
        // printRowDevice(row, types, numCols);
    }
}

__global__ void
getLeft(void *data, bool *matched, int numRows, ColType *typesNew, const int numColsOld, const int numColsNew,
        const int rowSizeOld, const int rowSizeNew, void *resData, unsigned int *top) {
    if (threadIdx.x == 0) {
        *top = 0;
    }
    __syncthreads();
    int rowsPerBlock = (numRows + NUM_THREADS - 1) / NUM_THREADS;
    unsigned int start = rowsPerBlock * threadIdx.x;
    unsigned int end = rowsPerBlock * (threadIdx.x + 1);
    void *rowOld, *row, *cell;
    row = malloc(rowSizeNew);
    cell = (char *)row + rowSizeOld;
    for (int j = numColsOld; j < numColsNew; ++j) {
        switch (typesNew[j].type) {
            case TYPE_INT: {
                int *x = (int *) cell;
                *x = getNullInt();
                break;
            }
            case TYPE_FLOAT: {
                float *x = (float *) cell;
                *x = getNullFlt();
                break;
            }
            case TYPE_VARCHAR: {
                getNullStr((char *)cell, typesNew[j].size);
                break;
            }
            default:
                printf("Not implemented\n");
                return;
        }
        cell = (char *) cell + typesNew[j].size;
    }
    unsigned int old;
    for (int i = start; i < end; ++i) {
        if (i >= numRows) break;
        if (!matched[i]) {
            rowOld = (char *) data + rowSizeOld * i;
            memcpy(row, rowOld, rowSizeOld);
            // printRowDevice(row, typesNew, numColsNew);
            old = atomicInc(top, numRows + 1);
            memcpy((char *) resData + old * rowSizeNew, row, rowSizeNew);
        }
    }
    free(row);
}

void sql_select::execute(std::string &query) {
    hsql::SQLParserResult *result = hsql::SQLParser::parseSQLString(query);
    std::vector<int> columnNames;

    if(!result->isValid()) {
        utils::invalidQuery(result->errorMsg());
        return;
    }

    cudaDeviceReset();

    const auto *stmt = (const hsql::SelectStatement *) result->getStatement(0);

    Data *d = getData(stmt->fromTable);

    for (hsql::Expr* expr : *stmt->selectList){
        switch (expr->type) {
            case hsql::kExprStar:
                // columnNames.emplace_back("*");
                columnNames.push_back(-1);
                break;
            case hsql::kExprColumnRef:
                // columnNames.emplace_back(expr->name);
                columnNames.push_back(d->mdata.colMap[expr->name]);
                break;
                // case hsql::kExprTableColumnRef:
                // inprint(expr->table, expr->name, numIndent);
                // break;
            case hsql::kExprLiteralFloat:
                // columnNames.push_back(std::to_string(expr->fval));
                columnNames.push_back(-2);
                break;
            case hsql::kExprLiteralInt:
                // columnNames.push_back(std::to_string(expr->ival));
                columnNames.push_back(-2);
                break;
            case hsql::kExprLiteralString:
                // columnNames.emplace_back(expr->name);
                columnNames.push_back(-2);
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


    std::vector<myExpr> whereExpr;
    if (stmt->whereClause != nullptr) {
        exprToVec(stmt->whereClause, whereExpr, d->mdata.columns, *d);
    } else {
        whereExpr.push_back(newExpr(CONSTANT_INT, (long) 1));
    }
    int rowSize = d->mdata.rowSize;
    void *data = malloc(d->chunkSize * rowSize);
    void *data_d;
    int numCols = d->mdata.columns.size();

    ColType *type_d;
    cudaMalloc(&type_d, sizeof(ColType) * numCols);
    cudaMemcpy(type_d, &d->mdata.datatypes[0], sizeof(ColType) * numCols, cudaMemcpyHostToDevice);

    myExpr *where_d;
    cudaMalloc(&where_d, sizeof(myExpr) * whereExpr.size());
    cudaMemcpy(where_d, &whereExpr[0], sizeof(myExpr) * whereExpr.size(), cudaMemcpyHostToDevice);

    std::vector<int> offsets(numCols + 1);
    offsets[0] = 0;
    for (int i = 1; i <= numCols; ++i) {
        offsets[i] = offsets[i - 1] + d->mdata.datatypes[i - 1].size;
    }
    int *offsets_d;
    cudaMalloc(&offsets_d, sizeof(int) * (numCols + 1));
    cudaMemcpy(offsets_d, &offsets[0], sizeof(int) * (numCols + 1), cudaMemcpyHostToDevice);

    int *dispCols_d;
    cudaMalloc(&dispCols_d, sizeof(int) * columnNames.size());
    cudaMemcpy(dispCols_d, &columnNames[0], sizeof(int) * columnNames.size(), cudaMemcpyHostToDevice);

    int rowsRead = d->read(data);
    // printf("HERE____________________%d\n", rowSize);
    // utils::printMultiple(data, d->mdata.datatypes, d->mdata.rowSize, d->mdata.rowCount);
    cudaMalloc(&data_d, d->chunkSize * rowSize);
    while (rowsRead > 0) {
        cudaMemcpy(data_d, data, rowSize * rowsRead, cudaMemcpyHostToDevice);
        // cudaMemcpy(data, data_d, rowSize * rowsRead, cudaMemcpyDeviceToHost);
        // printf("HERE____________________%d\n", rowSize);
        // utils::printMultiple(data, d->mdata.datatypes, d->mdata.rowSize, d->mdata.rowCount);
        selectKernel<<<1, NUM_THREADS>>>(data_d, rowSize, offsets_d, numCols, type_d, where_d, rowsRead, dispCols_d,
                                         columnNames.size());
        rowsRead = d->read(data);
        cudaDeviceSynchronize();
    }

    d->~Data();
    free(d);
    free(data);

    cudaFree(data_d);
    cudaFree(type_d);
    cudaFree(where_d);
    cudaFree(offsets_d);
}

Data *sql_select::getData(hsql::TableRef *fromTable) {
    switch (fromTable->type) {
        case hsql::kTableName:
            return new Data(fromTable->name);
        case hsql::kTableSelect:
            return selectData(fromTable->select);
        case hsql::kTableJoin: {
            Data *d, *dL, *dR;
            if (fromTable->join->type != hsql::kJoinRight) {
                dL = getData(fromTable->join->left);
                dR = getData(fromTable->join->right);
            } else {
                dL = getData(fromTable->join->right);
                dR = getData(fromTable->join->left);
            }
            d = new Data(dL, dR);
            dL->chunkSize = dR->chunkSize = d->chunkSize;

            std::vector<myExpr> joinCondition;
            exprToVec(fromTable->join->condition, joinCondition, d->mdata.columns, *d);
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
            cudaMalloc(&offsets_d, sizeof(int) * (d->mdata.columns.size() + 1));
            cudaMemcpy(offsets_d, &offsets[0], sizeof(int) * (d->mdata.columns.size() + 1), cudaMemcpyHostToDevice);

            ColType *type_d;
            cudaMalloc(&type_d, sizeof(ColType) * d->mdata.columns.size());
            cudaMemcpy(type_d, &d->mdata.datatypes[0], sizeof(ColType) * d->mdata.columns.size(),
                       cudaMemcpyHostToDevice);

            void *join = malloc(d->chunkSize * d->chunkSize * d->mdata.rowSize);
            void *dataL = malloc(d->chunkSize * dL->mdata.rowSize), *dataL_d;
            void *dataR = malloc(d->chunkSize * dR->mdata.rowSize), *dataR_d;
            void *join_d; // Upto n^2 rows can be stored
            cudaMalloc(&join_d, d->chunkSize * d->chunkSize * d->mdata.rowSize);
            cudaMalloc(&dataL_d, dL->chunkSize * dL->mdata.rowSize);
            cudaMalloc(&dataR_d, dR->chunkSize * dR->mdata.rowSize);
            unsigned int numRowsJoin = 0;
            unsigned int *numRowsJoin_d;
            cudaMalloc(&numRowsJoin_d, sizeof(unsigned int));

            std::vector<myExpr> whereClause;

            int rowsReadL = dL->read(dataL), rowsReadR;
            cudaMemcpy(dataL_d, dataL, rowsReadL * dL->mdata.rowSize, cudaMemcpyHostToDevice);

            bool *matched_d;
            cudaMalloc(&matched_d, sizeof(bool) * dL->chunkSize);
            while (rowsReadL > 0) {
                cudaMemset(matched_d, 0, sizeof(bool) * d->chunkSize);
                dR->restartRead();
                rowsReadR = dR->read(dataR);
                cudaMemcpy(dataR_d, dataR, rowsReadR * dR->mdata.rowSize, cudaMemcpyHostToDevice);
                while (rowsReadR > 0) {
                    joinKernel<<<1, NUM_THREADS>>>(dataL_d, dataR_d, join_d, joinCondition_d, offsets_d,
                                                   d->mdata.columns.size(),
                                                   type_d, dL->mdata.rowSize, dR->mdata.rowSize, rowsReadL, rowsReadR,
                                                   numRowsJoin_d, matched_d);
                    rowsReadR = dR->read(dataR);
                    cudaDeviceSynchronize();

                    cudaMemcpy(&numRowsJoin, numRowsJoin_d, sizeof(unsigned int), cudaMemcpyDeviceToHost);
                    cudaMemcpy(join, join_d, numRowsJoin * d->mdata.rowSize, cudaMemcpyDeviceToHost);
                    d->write(join, numRowsJoin * d->mdata.rowSize);
                    fflush(stdout);
                    // selectKernel<<<1, NUM_THREADS>>>(join_d, d->mdata.rowSize, offsets_d, d->mdata.columns.size(),
                    //                                  type_d, whereClause_d, numRowsJoin);
                    cudaDeviceSynchronize();
                    cudaMemcpy(dataR_d, dataR, rowsReadR * dR->mdata.rowSize, cudaMemcpyHostToDevice);
                }
                if (fromTable->join->type == hsql::kJoinLeft || fromTable->join->type == hsql::kJoinRight) {
                    getLeft<<<1, NUM_THREADS>>>(dataL_d, matched_d, rowsReadL, type_d, dL->mdata.columns.size(),
                                                d->mdata.columns.size(), dL->mdata.rowSize, d->mdata.rowSize, join_d,
                                                numRowsJoin_d);
                }
                rowsReadL = dL->read(dataL);
                cudaDeviceSynchronize();
                if (fromTable->join->type == hsql::kJoinLeft || fromTable->join->type == hsql::kJoinRight) {
                    cudaMemcpy(&numRowsJoin, numRowsJoin_d, sizeof(unsigned int), cudaMemcpyDeviceToHost);
                    cudaMemcpy(join, join_d, numRowsJoin * d->mdata.rowSize, cudaMemcpyDeviceToHost);
                    d->write(join, numRowsJoin * d->mdata.rowSize);
                }
                cudaMemcpy(dataL_d, dataL, rowsReadL * dL->mdata.rowSize, cudaMemcpyHostToDevice);
            }
            dL->~Data();
            dR->~Data();
            free(dL);
            free(dR);
            free(dataL);
            free(dataR);
            free(join);

            cudaFree(dataL_d);
            cudaFree(dataR_d);
            cudaFree(join_d);
            cudaFree(joinCondition_d);
            cudaFree(offsets_d);
            cudaFree(type_d);
            cudaFree(numRowsJoin_d);
            cudaFree(matched_d);

            d->switchToRead();
            return d;
        }
        case hsql::kTableCrossProduct:
            utils::invalidQuery("Cross Product is not Implemented.");
            return nullptr;
    }
    return nullptr;
}

Data *sql_select::selectData(hsql::SelectStatement *stmt) {
    std::vector<std::string> columnNames;
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
                return nullptr;
        }
    }
    Data *d = getData(stmt->fromTable);
    Data *result = new Data(d);
    std::vector<myExpr> whereExpr;
    if (stmt->whereClause != nullptr) {
        exprToVec(stmt->whereClause, whereExpr, d->mdata.columns, *d);
    } else {
        whereExpr.push_back(newExpr(CONSTANT_INT, (long) 1));
    }
    int rowSize = d->mdata.rowSize;
    void *data = malloc(d->chunkSize * rowSize);
    void *resData = malloc(d->chunkSize * rowSize);
    void *data_d, *resData_d;
    int numCols = d->mdata.columns.size();

    ColType *type_d;
    cudaMalloc(&type_d, sizeof(ColType) * numCols);
    cudaMemcpy(type_d, &d->mdata.datatypes[0], sizeof(ColType) * numCols, cudaMemcpyHostToDevice);

    myExpr *where_d;
    cudaMalloc(&where_d, sizeof(myExpr) * whereExpr.size());
    cudaMemcpy(where_d, &whereExpr[0], sizeof(myExpr) * whereExpr.size(), cudaMemcpyHostToDevice);

    std::vector<int> offsets(numCols + 1);
    offsets[0] = 0;
    for (int i = 1; i <= numCols; ++i) {
        offsets[i] = offsets[i - 1] + d->mdata.datatypes[i - 1].size;
    }
    int *offsets_d;
    cudaMalloc(&offsets_d, sizeof(int) * (numCols + 1));
    cudaMemcpy(offsets_d, &offsets[0], sizeof(int) * (numCols + 1), cudaMemcpyHostToDevice);

    int rowsRead = d->read(data);
    cudaMalloc(&data_d, d->chunkSize * rowSize);
    cudaMalloc(&resData_d, d->chunkSize * rowSize);
    unsigned int numMatches, *numMatches_d;
    cudaMalloc(&numMatches_d, sizeof(unsigned int));
    while (rowsRead > 0) {
        cudaMemcpy(data_d, data, rowSize * rowsRead, cudaMemcpyHostToDevice);
        selectKernelRes<<<1, NUM_THREADS>>>(data_d, rowSize, offsets_d, numCols, type_d, where_d, rowsRead, resData_d,
                                            numMatches_d);
        rowsRead = d->read(data);
        cudaDeviceSynchronize();
        cudaMemcpy(&numMatches, numMatches_d, sizeof(unsigned int), cudaMemcpyDeviceToHost);
        cudaMemcpy(resData, resData_d, rowSize * numMatches, cudaMemcpyDeviceToHost);
        result->write(resData, rowSize * numMatches);
        // utils::printMultiple(resData, d->mdata.datatypes, rowSize, numMatches);
    }

    d->~Data();
    free(d);
    free(data);
    free(resData);

    cudaFree(data_d);
    cudaFree(resData_d);
    cudaFree(type_d);
    cudaFree(where_d);
    cudaFree(offsets_d);
    result->switchToRead();
    result->restartRead();
    return result;
}

// void sql_select::execute(std::string &query) {
//
//     hsql::SQLParserResult *result;
//     std::vector<std::string> columnNames;
//
//     result = hsql::SQLParser::parseSQLString(query);
//     columnNames = std::vector<std::string>();
//
//     if(result->isValid()){
//         const auto *stmt = (const hsql::SelectStatement *) result->getStatement(0);
//         // Get column names
//         for (hsql::Expr* expr : *stmt->selectList){
//             switch (expr->type) {
//                 case hsql::kExprStar:
//                     columnNames.emplace_back("*");
//                     break;
//                 case hsql::kExprColumnRef:
//                     columnNames.emplace_back(expr->name);
//                     break;
//                 // case hsql::kExprTableColumnRef:
//                 // inprint(expr->table, expr->name, numIndent);
//                 // break;
//                 case hsql::kExprLiteralFloat:
//                     columnNames.push_back(std::to_string(expr->fval));
//                     break;
//                 case hsql::kExprLiteralInt:
//                     columnNames.push_back(std::to_string(expr->ival));
//                     break;
//                 case hsql::kExprLiteralString:
//                     columnNames.emplace_back(expr->name);
//                     break;
//                 // TODO: kExprFunctionRef (Distinct ?), kExprOperator (col1 + col2 ?)
//                 // case hsql::kExprFunctionRef:
//                 //     inprint(expr->name, numIndent);
//                 //     inprint(expr->expr->name, numIndent + 1);
//                 //     break;
//                 // case hsql::kExprOperator:
//                 //     printOperatorExpression(expr, numIndent);
//                 //     break;
//                 default:
//                     fprintf(stderr, "Unrecognized expression type %d\n", expr->type);
//                     return;
//             }
//         }
//         // Get tables reference
//         auto table = stmt->fromTable;
//         Data *d;
//         switch (table->type) {
//             case hsql::kTableName:
//                 // inprint(table->name, numIndent);
//                 d = new Data(table->name);
//                 break;
//             // case hsql::kTableSelect:
//             //     // printSelectStatementInfo(table->select, numIndent);
//             //     break;
//             case hsql::kTableJoin: {
//                 std::string leftTable, rightTable;
//                 if (table->join->type != hsql::kJoinRight) {
//                     d = new Data(table->join->left->name, table->join->right->name);
//                     leftTable = table->join->left->name;
//                     rightTable = table->join->right->name;
//                 } else {
//                     d = new Data(table->join->right->name, table->join->left->name);
//                     leftTable = table->join->right->name;
//                     rightTable = table->join->left->name;
//                 }
//                 Data dL(leftTable);
//                 dL.chunkSize = d->chunkSize;
//                 Data dR(rightTable);
//                 dR.chunkSize = d->chunkSize;
//
//                 std::vector<myExpr> joinCondition;
//                 exprToVec(table->join->condition, joinCondition, d->mdata.columns, *d);
//                 myExpr *joinCondition_d;
//                 cudaMalloc(&joinCondition_d, joinCondition.size() * sizeof(myExpr));
//                 cudaMemcpy(joinCondition_d, &joinCondition[0], sizeof(myExpr) * joinCondition.size(),
//                            cudaMemcpyHostToDevice);
//
//                 std::vector<int> offsets(d->mdata.columns.size() + 1);
//                 offsets[0] = 0;
//                 for (int i = 1; i <= d->mdata.columns.size(); ++i) {
//                     offsets[i] = offsets[i - 1] + d->mdata.datatypes[i - 1].size;
//                 }
//                 int *offsets_d;
//                 cudaMalloc(&offsets_d, sizeof(int) * (d->mdata.columns.size() + 1));
//                 cudaMemcpy(offsets_d, &offsets[0], sizeof(int) * (d->mdata.columns.size() + 1), cudaMemcpyHostToDevice);
//
//                 ColType *type_d;
//                 cudaMalloc(&type_d, sizeof(ColType) * d->mdata.columns.size());
//                 cudaMemcpy(type_d, &d->mdata.datatypes[0], sizeof(ColType) * d->mdata.columns.size(),
//                            cudaMemcpyHostToDevice);
//
//                 void *join = malloc(d->chunkSize * d->chunkSize * d->mdata.rowSize);
//                 void *dataL = malloc(d->chunkSize * dL.mdata.rowSize), *dataL_d;
//                 void *dataR = malloc(d->chunkSize * dR.mdata.rowSize), *dataR_d;
//                 void *join_d; // Upto n^2 rows can be stored
//                 cudaMalloc(&join_d, d->chunkSize * d->chunkSize * d->mdata.rowSize);
//                 cudaMalloc(&dataL_d, dL.chunkSize * dL.mdata.rowSize);
//                 cudaMalloc(&dataR_d, dR.chunkSize * dR.mdata.rowSize);
//                 unsigned int numRowsJoin = 0;
//                 unsigned int *numRowsJoin_d;
//                 cudaMalloc(&numRowsJoin_d, sizeof(unsigned int));
//
//                 std::vector<myExpr> whereClause;
//
//                 int rowsReadL = dL.read(dataL), rowsReadR;
//                 cudaMemcpy(dataL_d, dataL, rowsReadL * dL.mdata.rowSize, cudaMemcpyHostToDevice);
//
//                 bool *matched_d;
//                 cudaMalloc(&matched_d, sizeof(bool) * dL.chunkSize);
//                 while (rowsReadL > 0) {
//                     cudaMemset(matched_d, 0, sizeof(bool) * dL.chunkSize);
//                     dR.restartRead();
//                     rowsReadR = dR.read(dataR);
//                     cudaMemcpy(dataR_d, dataR, rowsReadR * dR.mdata.rowSize, cudaMemcpyHostToDevice);
//                     while (rowsReadR > 0) {
//                         joinKernel<<<1, NUM_THREADS>>>(dataL_d, dataR_d, join_d, joinCondition_d, offsets_d,
//                                                        d->mdata.columns.size(),
//                                                        type_d, dL.mdata.rowSize, dR.mdata.rowSize, rowsReadL, rowsReadR,
//                                                        numRowsJoin_d, matched_d);
//                         rowsReadR = dR.read(dataR);
//                         cudaDeviceSynchronize();
//
//                         cudaMemcpy(&numRowsJoin, numRowsJoin_d, sizeof(unsigned int), cudaMemcpyDeviceToHost);
//                         cudaMemcpy(join, join_d, numRowsJoin * d->mdata.rowSize, cudaMemcpyDeviceToHost);
//                         d->write(join, numRowsJoin * d->mdata.rowSize);
//                         fflush(stdout);
//                         // selectKernel<<<1, NUM_THREADS>>>(join_d, d->mdata.rowSize, offsets_d, d->mdata.columns.size(),
//                         //                                  type_d, whereClause_d, numRowsJoin);
//                         cudaDeviceSynchronize();
//                         cudaMemcpy(dataR_d, dataR, rowsReadR * dR.mdata.rowSize, cudaMemcpyHostToDevice);
//                     }
//                     if (table->join->type == hsql::kJoinLeft || table->join->type == hsql::kJoinRight) {
//                         getLeft<<<1, NUM_THREADS>>>(dataL_d, matched_d, rowsReadL, type_d, dL.mdata.columns.size(),
//                                                       d->mdata.columns.size(), dL.mdata.rowSize, d->mdata.rowSize);
//
//                     }
//                     rowsReadL = dL.read(dataL);
//                     cudaDeviceSynchronize();
//                     cudaMemcpy(dataL_d, dataL, rowsReadL * dL.mdata.rowSize, cudaMemcpyHostToDevice);
//                 }
//
//                 myExpr *whereClause_d;
//                 if (stmt->whereClause != nullptr) {
//                     exprToVec(stmt->whereClause, whereClause, d->mdata.columns, *d);
//                     cudaMalloc(&whereClause_d, sizeof(myExpr) * whereClause.size());
//                     cudaMemcpy(whereClause_d, &whereClause[0], sizeof(myExpr) * whereClause.size(),
//                                cudaMemcpyHostToDevice);
//                 }
//
//                 // change chunk size before select
//                 // d->chunkSize = 500 * 1024 * 1024 / d->mdata.rowSize;
//                 // if chunksize is changed, join and join_d might need to be reallocated
//                 d->chunkSize *= d->chunkSize;
//
//                 // printf("____________________________________________________\n");
//                 d->switchToRead();
//                 int numRowsRead;
//                 numRowsRead = d->read(join);
//                 while (numRowsRead > 0) {
//                     cudaMemcpy(join_d, join, numRowsRead * d->mdata.rowSize, cudaMemcpyHostToDevice);
//                     selectKernel<<<1, NUM_THREADS>>>(join_d, d->mdata.rowSize, offsets_d, d->mdata.columns.size(),
//                                                      type_d, whereClause_d, numRowsRead);
//                     cudaDeviceSynchronize();
//                     numRowsRead = d->read(join);
//                 }
//
//                 d->~Data();
//                 free(d);
//                 free(dataL);
//                 free(dataR);
//
//                 cudaFree(dataL_d);
//                 cudaFree(dataR_d);
//                 cudaFree(join_d);
//                 cudaFree(joinCondition_d);
//                 cudaFree(offsets_d);
//                 cudaFree(type_d);
//                 cudaFree(numRowsJoin_d);
//                 cudaFree(whereClause_d);
//                 cudaFree(offsets_d);
//                 cudaFree(matched_d);
//                 return;
//                 break;
//             }
//             // case hsql::kTableCrossProduct:
//             //     // for (TableRef* tbl : *table->list) printTableRefInfo(tbl, numIndent);
//             //     break;
//             default:
//                 printf("Will be handled later\n");
//                 return;
//         }
//         if (stmt->whereClause != nullptr) {
//             // Get where
//             std::vector<myExpr> tree;
//
//             auto expr = stmt->whereClause;
//             exprToVec(expr, tree, d->mdata.columns, *d);
//             free(expr);
//
//             int rowSize = d->mdata.rowSize;
//             void *data = malloc(d->chunkSize * rowSize);
//             void *data_d;
//             int numCols = d->mdata.columns.size();
//             cudaSetDevice(0);
//             cudaDeviceReset();
//
//             ColType *type_d;
//             cudaMalloc(&type_d, sizeof(ColType) * numCols);
//             cudaMemcpy(type_d, &d->mdata.datatypes[0], sizeof(ColType) * numCols, cudaMemcpyHostToDevice);
//             myExpr *where_d;
//             cudaMalloc(&where_d, sizeof(myExpr) * tree.size());
//             cudaMemcpy(where_d, &tree[0], sizeof(myExpr) * tree.size(), cudaMemcpyHostToDevice);
//             int *offsets = (int *) malloc(sizeof(int) * (numCols + 1));
//             offsets[0] = 0;
//             for (int i = 1; i <= numCols; i++) {
//                 offsets[i] = offsets[i - 1] + d->mdata.datatypes[i - 1].size;
//             }
//             int *offsets_d;
//             cudaMalloc(&offsets_d, sizeof(int) * (numCols + 1));
//             cudaMemcpy(offsets_d, offsets, sizeof(int) * (numCols + 1), cudaMemcpyHostToDevice);
//             int numRows = d->read(data);
//
//             // printing data in table
//             // utils::printMultiple(data, d.mdata.datatypes, d.mdata.rowSize, d.mdata.rowCount);
//
//             cudaMalloc(&data_d, d->chunkSize * rowSize);
//             while (numRows > 0) {
//                 cudaMemcpy(data_d, data, rowSize * numRows, cudaMemcpyHostToDevice);
//                 selectKernel<<<1, NUM_THREADS>>>(data_d, rowSize, offsets_d, numCols, type_d, where_d, numRows);
//                 numRows = d->read(data);
//                 cudaDeviceSynchronize();
//             }
//
//             // Free all the data
//             d->~Data();
//             free(d);
//             free(data);
//             free(offsets);
//             cudaFree(data_d);
//             cudaFree(type_d);
//             cudaFree(where_d);
//             cudaFree(offsets_d);
//         } else {
//             // RETURN ALL ROWS
//         }
//     } else {
//         fprintf(stderr, "Given string is not a valid SQL query.\n");
//         fprintf(stderr, "%s (L%d:%d)\n",
//                 result->errorMsg(),
//                 result->errorLine(),
//                 result->errorColumn());
//     }
//     free(result);
// }