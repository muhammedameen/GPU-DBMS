//
// Created by gautam on 28/04/20.
//

#ifndef DBASE_DEVICEUTIL_CUH
#define DBASE_DEVICEUTIL_CUH

// #include <cuda_runtime.h>

#include "myExpr.cuh"
#include "ColType.cuh"
#include "null.cuh"

#pragma hd_warning_disable

const int RESTYPE_INT = 1;
const int RESTYPE_FLT = 2;
const int RESTYPE_DTM = 3;
const int RESTYPE_BOOL = 4;

__device__ void eval(void *row, int *offset, ColType *types, myExpr *exprArr, void *&res, int &resType);

__device__ void evalUtil(void *row, int currPos, void *&res, int &resType);

__device__ int myStrncmp(const char *str_a, const char *str_b, unsigned len = 256);

__device__ int myStrlen(const char *str);

__device__ void printRowDevice(void *row, ColType *colTypes, int numCols);

__device__ int appendInt(char *data, int i);

__device__ int appendFlt(char *data, float f);

__device__ int appendStr(char *data, const char *str);


#endif //DBASE_DEVICEUTIL_CUH
