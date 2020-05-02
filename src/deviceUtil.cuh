//
// Created by gautam on 28/04/20.
//

#ifndef DBASE_DEVICEUTIL_CUH
#define DBASE_DEVICEUTIL_CUH

// #include <cuda_runtime.h>

#include "whereExpr.h"
#include "Metadata.h"
#include "ColType.h"

const int RESTYPE_INT = 1;
const int RESTYPE_FLT = 2;
const int RESTYPE_DTM = 3;
const int RESTYPE_BOOL = 4;

__device__ void eval(void *row, int rowSize, const int *offset, int offsetSize, const char *cols, const int *colStart, Metadata::ColType types[], whereExpr *expr, int currPos, void *&res, int &resType);


__device__ int myStrncmp(const char *str_a, const char *str_b, unsigned len = 256);

__device__ int myStrlen(const char *str);
#endif //DBASE_DEVICEUTIL_CUH
