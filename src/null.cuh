//
// Created by ameen on 09/05/20.
//

#ifndef DBASE_NULL_CUH
#define DBASE_NULL_CUH

__device__ bool isNull(int *i);

__device__ bool isNull(char *data);

__device__ bool isNull(float *f);

__device__ int getNullInt();

__device__ float getNullFlt();

__device__ void getNullStr(char *data, int size);

#endif //DBASE_NULL_CUH
