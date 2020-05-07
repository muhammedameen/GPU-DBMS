//
// Created by gautam on 07/05/20.
//

#include "sql_update.cuh"

#define NUM_THREADS 512

__global__ void
updateKernel(void *data, int rowSize, int *offset, int offsetSize, ColType *types, myExpr *exprs, int numRows,
             const int *uIds, myExpr *uExprs, int *uOffs, int numUpdates) {
    void *res;
    int resType = 1;
    int rowsPerBlock = (numRows + NUM_THREADS - 1) / NUM_THREADS;
    unsigned int start = rowsPerBlock * threadIdx.x;
    unsigned int end = rowsPerBlock * (threadIdx.x + 1);

    void *tempRow = malloc(rowSize);

    void *row;
    bool flag;
    for (unsigned int i = start; i < end; ++i) {
        if (i >= numRows) break;
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
        // update row here
        memcpy(tempRow, row, rowSize);
        for (int j = 0; j < numUpdates; ++j) {
            const int col = uIds[j];
            myExpr *uExpr = uExprs + uOffs[j];
            eval(tempRow, offset, types, uExpr, res, resType);
            switch (types[col].type) {
                case TYPE_INT:{
                    // ASSERT RESULT HAS TO BE INT
                    if (resType == RESTYPE_INT) {
                        int *x = (int *) ((char *) tempRow + offset[col]);
                        *x = *(int *) res;
                    }
                    break;
                }
                case TYPE_FLOAT: {
                    // RESULT CAN BE INT OR FLOAT
                    if (resType == RESTYPE_INT) {
                        float *x = (float *) ((char *) tempRow + offset[col]);
                        *x = *(int *) res;
                    } else if (resType == RESTYPE_FLT) {
                        float *x = (float *) ((char *) tempRow + offset[col]);
                        *x = *(float *) res;
                    }
                    break;
                }
                case TYPE_VARCHAR: {
                    // RESULT HAS TO BE VARCHAR
                    if (resType < 0 && -resType <= types[col].size) {
                        char *x = (char *) tempRow + offset[col];
                        int resEnd = appendStr(x, (char *) res);
                        x[resEnd] = 0;
                    }
                    break;
                }
                default:
                    printf("Not implemented");
                    break;
            }
        }
        memcpy(row, tempRow, rowSize);
    }
}

void sql_update::execute(std::string &query) {
    hsql::SQLParserResult *result = hsql::SQLParser::parseSQLString(query);
    std::vector<std::string> columnNames;
    std::string tableName;

    if (result->isValid()) {
        const auto *stmt = (const hsql::UpdateStatement *) result->getStatement(0);
        tableName = stmt->table->name;
        std::vector<myExpr> flattenedExpr;
        Data d(tableName);
        exprToVec(stmt->where, flattenedExpr, d.mdata.columns);

        cudaSetDevice(0);
        cudaDeviceReset();

        int rowSize = d.mdata.rowSize;
        void *data = malloc(d.chunkSize * rowSize);
        void *data_d;
        int numCols = d.mdata.columns.size();
        ColType *type_d;

        cudaMalloc(&type_d, sizeof(ColType) * numCols);
        cudaMemcpy(type_d, &d.mdata.datatypes[0], sizeof(ColType) * numCols, cudaMemcpyHostToDevice);
        myExpr *where_d;
        cudaMalloc(&where_d, sizeof(myExpr) * flattenedExpr.size());
        cudaMemcpy(where_d, &flattenedExpr[0], sizeof(myExpr) * flattenedExpr.size(), cudaMemcpyHostToDevice);
        int *offsets = (int *) malloc(sizeof(int) * (numCols + 1));
        offsets[0] = 0; //d.mdata.datatypes[0].size;
        for (int i = 1; i <= numCols; i++) {
            offsets[i] = offsets[i - 1] + d.mdata.datatypes[i - 1].size;
        }
        int *offsets_d;
        cudaMalloc(&offsets_d, sizeof(int) * (numCols + 1));
        cudaMemcpy(offsets_d, offsets, sizeof(int) * (numCols + 1), cudaMemcpyHostToDevice);
        int numRows = d.read(data);
        cudaMalloc(&data_d, d.chunkSize * rowSize);
        std::vector<std::vector<myExpr>> updateExprs(stmt->updates->size());
        std::vector<int> colIds(stmt->updates->size());
        for (int i = 0; i < stmt->updates->size(); ++i) {
            hsql::UpdateClause *clause = stmt->updates->at(i);
            colIds[i] = d.mdata.colMap[clause->column];
            exprToVec(clause->value, updateExprs[i], d.mdata.columns);
        }
        int *updateIds_d;
        cudaMalloc(&updateIds_d, sizeof(int) * colIds.size());
        cudaMemcpy(updateIds_d, &colIds[0], sizeof(int) * colIds.size(), cudaMemcpyHostToDevice);

        myExpr *updateExprs_d;
        int total = 0;
        std::vector<int> updateOffsets(updateExprs.size());
        for (int i = 0; i < updateExprs.size(); ++i) {
            updateOffsets[i] = total;
            total += updateExprs[i].size();
        }
        cudaMalloc(&updateExprs_d, sizeof(myExpr) * total);
        for (int i = 0; i < updateExprs.size(); ++i) {
            cudaMemcpy(updateExprs_d + updateOffsets[i], &updateExprs[i][0], sizeof(myExpr) * updateExprs[i].size(),
                       cudaMemcpyHostToDevice);
        }
        int *updateOffsets_d;
        cudaMalloc(&updateOffsets_d, sizeof(int) * updateOffsets.size());
        cudaMemcpy(updateOffsets_d, &updateOffsets[0], sizeof(int) * updateOffsets.size(), cudaMemcpyHostToDevice);
        while (numRows > 0) {
            cudaMemcpy(data_d, data, rowSize * numRows, cudaMemcpyHostToDevice);
            updateKernel<<<1, NUM_THREADS>>>(data_d, rowSize, offsets_d, numCols, type_d, where_d, numRows, updateIds_d,
                                             updateExprs_d, updateOffsets_d, colIds.size());
            cudaDeviceSynchronize();
            cudaError_t err = cudaGetLastError();
            if (err != cudaSuccess) {
                printf("Error at %d: %s\n", __LINE__, cudaGetErrorString(err));
            }
            cudaMemcpy(data, data_d, rowSize * numRows, cudaMemcpyDeviceToHost);
            d.write(data, numRows * d.mdata.rowSize);
            numRows = d.read(data);
        }
        // Free all the data
        free(data);
        free(offsets);
        cudaFree(data_d);
        cudaFree(type_d);
        cudaFree(where_d);
        cudaFree(offsets_d);
    } else {
        printf("QUERY is invalid\n");
    }
}