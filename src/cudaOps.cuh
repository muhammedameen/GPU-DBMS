//
// Created by gautam on 02/05/20.
//

#ifndef DBASE_CUDAOPS_CUH
#define DBASE_CUDAOPS_CUH


#include "Metadata.h"
#include "whereExpr.h"
#include "deviceUtil.cuh"
#include "ColType.h"

#include <cuda_runtime.h>

__global__ void selectKernel(void *data, int rowSize, const int *offset, int offsetSize, char *cols, int *colStart, Metadata::ColType types[], whereExpr *where);

#endif //DBASE_CUDAOPS_CUH
