//
// Created by gautam on 28/04/20.
//

#ifndef DBASE_DEVICEUTIL_H
#define DBASE_DEVICEUTIL_H

// #include <cuda_runtime.h>

#include "whereExpr.h"
#include "Metadata.h"

const int RESTYPE_INT = 1;
const int RESTYPE_FLT = 2;
const int RESTYPE_DTM = 3;
const int RESTYPE_BOOL = 4;

void eval(void *row, int rowSize, const int *offset, int offsetSize, char **cols, Metadata::ColType types[], whereExpr *expr, int currPos, void *&res, int &resType);

#endif //DBASE_DEVICEUTIL_H
