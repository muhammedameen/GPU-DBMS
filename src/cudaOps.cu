//
// Created by gautam on 02/05/20.
//
#include "cudaOps.cuh"
#include "ColType.h"

__global__ void selectKernel(void *data, int rowSize, const int *offset, int offsetSize, char *cols, int *colStart, Metadata::ColType types[], whereExpr *where) {
    void *res;
    int resType = 0;
    eval(data, rowSize, offset, offsetSize, cols, colStart, types, &where[0], 0, res, resType);
    if (resType == RESTYPE_INT) {
        int *x = (int *) res;
        printf("Value of expression is : %d\n", *x);
    }
}