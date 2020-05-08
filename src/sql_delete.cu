//
// Created by ameen on 07/05/20.
//

#include "sql_delete.cuh"

#define NUM_THREADS 512

__global__ void
deleteKernel(void *data, int rowSize, int *offset, int offsetSize, ColType *types, myExpr *exprs, int numRows, bool *flag_d) {
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
        flag_d[i] = flag;
    }
}

void sql_delete::execute(std::string &query) {
    hsql::SQLParserResult *result = hsql::SQLParser::parseSQLString(query);
    std::vector<std::string> columnNames;
    std::string tableName;

    if (result->isValid()) {
        const auto *stmt = (const hsql::DeleteStatement *) result->getStatement(0);
        tableName = stmt->tableName;
        std::vector<myExpr> flattenedExpr;
        Data d(tableName);
        exprToVec(stmt->expr, flattenedExpr, d.mdata.columns, d);

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
        bool *flag = (bool *)malloc(numRows * sizeof(bool));
        bool *flag_d;
        cudaMalloc(&flag_d,numRows * sizeof(bool));
        d.mdata.rowCount = 0;
        while (numRows > 0) {
            cudaMemcpy(data_d, data, rowSize * numRows, cudaMemcpyHostToDevice);
            deleteKernel<<<1, NUM_THREADS>>>(data_d, rowSize, offsets_d, numCols, type_d, where_d, numRows, flag_d);
            cudaDeviceSynchronize();
            cudaError_t err = cudaGetLastError();
            if (err != cudaSuccess) {
                printf("Error at %d: %s\n", __LINE__, cudaGetErrorString(err));
            }
//            cudaMemcpy(data, data_d, rowSize * numRows, cudaMemcpyDeviceToHost);
//            d.write(data, numRows * d.mdata.rowSize);

            cudaMemcpy(flag, flag_d, numRows * sizeof(bool), cudaMemcpyDeviceToHost);
            for (int k=0;k<numRows;k++)
                if(flag[k])
                    d.writeRow((char *)data+k*rowSize);
            numRows = d.read(data);
        }
        d.mdata.commit();
        //write to file after checking flag
        // Free all the data
        free(data);
        free(offsets);
        free(flag);
        cudaFree(data_d);
        cudaFree(type_d);
        cudaFree(where_d);
        cudaFree(offsets_d);
        cudaFree(flag_d);
    } else {
        printf("QUERY is invalid\n");
    }
}
