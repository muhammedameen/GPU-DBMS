//
// Created by gautam on 28/04/20.
//

#include <float.h>
#include "myExpr.cuh"

#define NUM_THREADS 512


myExpr *newExpr(myExprType type, long intVal) {
    auto *expr = new myExpr;
    expr->type = type;
    expr->iVal = (int)intVal;
    expr->fVal = 0.0f;
    expr->sVal[0] = 0;
    expr->childLeft = -1;
    expr->childRight = -1;
    return expr;
}

myExpr * newExpr(myExprType type, float fVal){
    auto *expr = new myExpr;
    expr->type = type;
    expr->iVal = 0;
    expr->fVal = fVal;
    expr->sVal[0] = 0;
    expr->childLeft = -1;
    expr->childRight = -1;
    return expr;
}

myExpr * newExpr(myExprType type, char *sVal){
    auto *expr = new myExpr;
    expr->type = type;
    expr->iVal = 0;
    expr->fVal = 0.0f;
    // expr->sVal = new char[strlen(sVal) + 1];
    stpcpy(expr->sVal, sVal);
    expr->childLeft = -1;
    expr->childRight = -1;
    return expr;
}

myExpr *newExpr(myExprType type){
    auto *expr = new myExpr;
    expr->type = type;
    expr->iVal = 0;
    expr->fVal = 0.0f;
    expr->sVal[0] = 0;
    expr->childLeft = -1;
    expr->childRight = -1;
    return expr;
}

void freeExpr(myExpr *expr){
    free(expr);
}

__global__ void minKernel(void *data, const int colPos, const int rowSize, const int numRows, int *min) {
    int rowsPerBlock = (numRows + NUM_THREADS - 1) / NUM_THREADS;
    unsigned int start = rowsPerBlock * threadIdx.x;
    unsigned int end = rowsPerBlock * (threadIdx.x + 1);
    int threadMin = *min;
    int *currVal;
    for (unsigned int i = start; i < end; ++i) {
        if (i >= numRows) break;
        currVal = (int *)((char *)data + i * rowSize + colPos);
        threadMin = threadMin < *currVal ? threadMin : *currVal;
    }
    atomicMin(min, threadMin);
}

__device__ float atomicMax(float* address, float val)
{
    int* address_as_i = (int*) address;
    int old = *address_as_i, assumed;
    do {
        assumed = old;
        old = ::atomicCAS(address_as_i, assumed,
                          __float_as_int(::fmaxf(val, __int_as_float(assumed))));
    } while (assumed != old);
    return __int_as_float(old);
}

__device__ float atomicMin(float* address, float val)
{
    int* address_as_i = (int*) address;
    int old = *address_as_i, assumed;
    do {
        assumed = old;
        old = ::atomicCAS(address_as_i, assumed,
                          __float_as_int(::fminf(val, __int_as_float(assumed))));
    } while (assumed != old);
    return __int_as_float(old);
}

__global__ void minKernel(void *data, const int colPos, const int rowSize, const int numRows, float *min) {
    int rowsPerBlock = (numRows + NUM_THREADS - 1) / NUM_THREADS;
    unsigned int start = rowsPerBlock * threadIdx.x;
    unsigned int end = rowsPerBlock * (threadIdx.x + 1);
    float threadMin = *min;
    float *currVal;
    for (unsigned int i = start; i < end; ++i) {
        if (i >= numRows) break;
        currVal = (float *)((char *)data + i * rowSize + colPos);
        threadMin = threadMin < *currVal ? threadMin : *currVal;
    }
    atomicMin(min, threadMin);
}

void exprToVec(hsql::Expr *expr, std::vector<myExpr> &vector, const std::vector<std::string>& colNames, Data &d) {
    switch (expr->type) {
        case hsql::kExprLiteralFloat:
            vector.push_back(*newExpr(CONSTANT_FLT, expr->fval));
            break;
        case hsql::kExprLiteralString:
            vector.push_back(*newExpr(CONSTANT_STR, expr->name));
            break;
        case hsql::kExprLiteralInt:
            vector.push_back(*newExpr(CONSTANT_INT, expr->ival));
            break;
        case hsql::kExprStar:
            printf("Why is there a `*` here?");
            break;
        case hsql::kExprPlaceholder:
            printf("What is this?");
            break;
        case hsql::kExprColumnRef:{
            int i;
            for (i = 0; i < colNames.size(); i++) {
                if (colNames[i] == expr->name) break;
            }
            vector.push_back(*newExpr(COL_NAME, (long)i));
            break;
        }
        case hsql::kExprFunctionRef: {
            // printf("%s\n", expr->name);
            int oldChunkSize = d.chunkSize;
            d.chunkSize *= 10;
            void *data = malloc(d.chunkSize * d.mdata.rowSize);
            void *data_d;
            cudaMalloc(&data_d, d.chunkSize * d.mdata.rowSize);
            int rowsRead = d.read(data);
            cudaMemcpy(data_d, data, rowsRead * d.mdata.rowSize, cudaMemcpyHostToDevice);
            std::string colName = expr->exprList->at(0)->name;
            // printf("Col for agg function is %s:%d\n", colName.c_str(), d.mdata.colMap[colName]);
            fflush(stdout);
            int colPos = 0;
            int resType = TYPE_INT;

            for (int i = 0; i < colNames.size(); ++i) {
                if (colNames[i] == colName) {
                    resType = d.mdata.datatypes[i].type;
                    break;
                }
                colPos += d.mdata.datatypes[i].size;
            }

            if (strcmp(expr->name, "min") == 0) {
                if (resType == TYPE_INT) {
                    int min_h = INT_MAX;
                    int *min;
                    cudaMalloc(&min, sizeof(int));
                    cudaMemcpy(min, &min_h, sizeof(int), cudaMemcpyHostToDevice);
                    while (rowsRead > 0) {
                        minKernel<<<1, NUM_THREADS>>>(data_d, colPos, d.mdata.rowSize, rowsRead, min);
                        rowsRead = d.read(data);
                        cudaDeviceSynchronize();
                        cudaMemcpy(data_d, data, rowsRead * d.mdata.rowSize, cudaMemcpyHostToDevice);
                    }
                    cudaMemcpy(&min_h, min, sizeof(int), cudaMemcpyDeviceToHost);
                    cudaFree(min);
                    printf("Min value is: %d\n", min_h);
                    vector.push_back(*newExpr(CONSTANT_INT, (long) min_h));
                } else if (resType == TYPE_FLOAT) {
                    float min_h = FLT_MAX;
                    float *min;
                    cudaMalloc(&min, sizeof(float));
                    cudaMemcpy(min, &min_h, sizeof(float), cudaMemcpyHostToDevice);
                    while (rowsRead > 0) {
                        minKernel<<<1, NUM_THREADS>>>(data_d, colPos, d.mdata.rowSize, rowsRead, min);
                        rowsRead = d.read(data);
                        cudaDeviceSynchronize();
                        cudaMemcpy(data_d, data, rowsRead * d.mdata.rowSize, cudaMemcpyHostToDevice);
                    }
                    cudaMemcpy(&min_h, min, sizeof(float), cudaMemcpyDeviceToHost);
                    cudaFree(min);
                    vector.push_back(*newExpr(CONSTANT_FLT, min_h));
                }
            } else if (strcmp(expr->name, "max") == 0) {

            } else if (strcmp(expr->name, "sum") == 0) {

            } else if (strcmp(expr->name, "avg") == 0) {

            } else if (strcmp(expr->name, "count") == 0) {

            }
            d.chunkSize = oldChunkSize;
            d.restartRead();
            free(data);
            cudaFree(data_d);
            break;
        }
        case hsql::kExprOperator: {
            myExpr *temp = newExpr(getOpType(expr->opType, expr->opChar));
            vector.push_back(*temp);
            int curr = (int)vector.size() - 1;
            vector[curr].childLeft = vector.size();
            exprToVec(expr->expr, vector, colNames, d);
            if (expr->expr2 != nullptr) {
                vector[curr].childRight = vector.size();
                exprToVec(expr->expr2, vector, colNames, d);
            }
            break;
        }
        case hsql::kExprSelect:
            printf("Not yet implemented");
            break;
    }
}

myExprType getOpType(hsql::Expr::OperatorType type, char opChar) {
    // TODO: Change Error to correct Constants
    switch (type) {
        case hsql::Expr::NONE:
            return CONSTANT_ERR;
        case hsql::Expr::BETWEEN:
            return CONSTANT_ERR;
        case hsql::Expr::CASE:
            return CONSTANT_ERR;
        case hsql::Expr::SIMPLE_OP:
            switch (opChar) {
                case '+':
                    return OPERATOR_PL;
                case '-':
                    return OPERATOR_MI;
                case '*':
                    return OPERATOR_MU;
                case '/':
                    return OPERATOR_DI;
                case '%':
                    return OPERATOR_MO;
                case '=':
                    return OPERATOR_EQ;
                case '<':
                    return OPERATOR_LT;
                case '>':
                    return OPERATOR_GT;
                default:
                    return CONSTANT_ERR;
            }
        case hsql::Expr::NOT_EQUALS:
            return OPERATOR_NE;
        case hsql::Expr::LESS_EQ:
            return OPERATOR_LE;
        case hsql::Expr::GREATER_EQ:
            return OPERATOR_GE;
        case hsql::Expr::LIKE:
            return CONSTANT_ERR;
        case hsql::Expr::NOT_LIKE:
            return CONSTANT_ERR;
        case hsql::Expr::AND:
            return OPERATOR_AND;
        case hsql::Expr::OR:
            return OPERATOR_OR;
        case hsql::Expr::IN:
            return CONSTANT_ERR;
        case hsql::Expr::NOT:
            return OPERATOR_NOT;
        case hsql::Expr::UMINUS:
            return OPERATOR_UMI;
        case hsql::Expr::ISNULL:
            return CONSTANT_ERR;
        case hsql::Expr::EXISTS:
            return CONSTANT_ERR;
    }
    return CONSTANT_ERR;
}
