//
// Created by gautam on 28/04/20.
//

#include "deviceUtil.cuh"

// __device__ whereExpr *exprArr;
// __device__ ColType *types;
// __device__ int *offset;
// __device__ int whereExprSize;

void eval2(void *row, int *offset, ColType *types, whereExpr *exprArr, void *&res, int &resType);

__device__ void printRowDevice(void *row, ColType *colTypes, int numCols) {
    // int start =  0;
    // char buff[100];
    // int buffStart = 0;
    // for (int i = 0; i < numCols; i++, start += colTypes[i].size) {
    //     switch (colTypes->type) {
    //         case TYPE_INT: {
    //             int temp = *((int *) ((char *) row + start));
    //             buffStart += sprintf(buff + buffStart, "%d", temp);
    //             break;
    //         }
    //         case TYPE_FLOAT: {
    //             float temp = *((float *) ((char *) row + start));
    //             buffStart += sprintf(buff + buffStart, "%f", temp);
    //             break;
    //         }
    //         case TYPE_BOOL:
    //             break;
    //         case TYPE_VARCHAR: {
    //             char *temp = (char *) row + start;
    //             buffStart += sprintf(buff + buffStart, "%s", temp);
    //             break;
    //         }
    //         case TYPE_DATETIME:
    //             break;
    //         case TYPE_INVALID:
    //             break;
    //     }
    //     if (i != numCols - 1) {
    //         buffStart += sprintf(buff + buffStart, ", ");
    //     }
    // }
    // printf("%s\n", buff);
}

__device__ void eval2(void *row, int *offset, ColType *types, whereExpr *exprArr, void *&res, int &resType) {
    const int MAX_DEPTH = 10;
    int *exprStack = (int *) malloc(sizeof(int) * MAX_DEPTH);
    exprStack[0] = 0;        // Push Expr of 0
    bool *solved = (bool *) malloc(sizeof(bool) * 100);
    void **resArr = (void **) malloc(sizeof(void *) * 100);
    int *resTypeArr = (int *) malloc(sizeof(int) * 100);
    for (int i = 0; i < 100; i++) solved[i] = false;
    int count = 1;
    while (count > 0) {
        // pop
        int index = exprStack[count - 1];
        whereExpr *expr = &exprArr[index];
        --count;
        // check if children are solved
        // if solved evaluate current node
        // else push children
        switch (expr->type) {
            case CONSTANT_ERR:
                printf("Error");
                break;
            case CONSTANT_INT: {
                solved[index] = true;
                resTypeArr[index] = RESTYPE_INT;
                int *temp = (int *) malloc(sizeof(int));
                *temp = expr->iVal;
                resArr[index] = temp;
                break;
            }
            case OPERATOR_PL: {
                if (solved[expr->childLeft] && solved[expr->childRight]) {
                    solved[index] = true;
                    int ltype = resTypeArr[expr->childLeft];
                    int rtype = resTypeArr[expr->childRight];
                    void *lres = resArr[expr->childLeft];
                    void *rres = resArr[expr->childRight];
                    resTypeArr[index] = RESTYPE_FLT;
                    if (ltype == RESTYPE_FLT && rtype == RESTYPE_FLT) {
                        float lhs, rhs;
                        float *temp = (float *)malloc(sizeof(float));
                        lhs = *(float *) lres;
                        rhs = *(float *) rres;
                        *temp = lhs + rhs;
                        resArr[index] = temp;
                    } else if (ltype == RESTYPE_FLT) {
                        float lhs;
                        int rhs;
                        float *temp = (float *)malloc(sizeof(float));
                        lhs = *(float *) lres;
                        rhs = *(int *) rres;
                        *temp = lhs + rhs;
                        resArr[index] = temp;
                    } else if (rtype == RESTYPE_FLT) {
                        int lhs;
                        float rhs;
                        float *temp = (float *)malloc(sizeof(float));
                        lhs = *(int *) lres;
                        rhs = *(float *) rres;
                        *temp = lhs + rhs;
                        resArr[index] = temp;
                    } else {
                        resTypeArr[index] = RESTYPE_INT;
                        int *temp = (int *)malloc(sizeof(float));
                        int lhs, rhs;
                        lhs = *(int *) lres;
                        rhs = *(int *) rres;
                        *temp = lhs + rhs;
                        resArr[index] = temp;
                    }
                } else {
                    // push this
                    // push ALL children
                    exprStack[count] = index;
                    ++count;
                    exprStack[count] = expr->childLeft;
                    ++count;
                    exprStack[count] = expr->childRight;
                    ++count;
                }
                break;
            }
            default:
                printf("Not yet implemented");
        }
    }
    // Result and restype are stored in resArr[0] and resArrType[0]
    res = resArr[0];
    resType = resTypeArr[0];
    free(resTypeArr);
    for (int i = 1; i < 100; i++) {
        if (solved[i]) {
            free(resArr[i]);
        }
    }
    free(resArr);
}

__device__ void eval(void *row, int *offset2, ColType types2[],
          whereExpr *exprArr2,
          void *&res, int &resType, int tid, bool flag) {
    if (tid == 0) {
        // offset = offset2;
        // types = types2;
        // exprArr = exprArr2;
        // whereExprSize = sizeof(whereExpr);
    }
    __syncthreads();
    if (tid == 1) {
        printf("Inside eval.\n");
        // for (int i = 0; i < 3; i++) {
        //     auto leaf = exprArr2[i];
        //     printf("TYPE: %d, ival: %d, fval: %f, sval: %s, left: %d, right: %d\n", leaf.type, leaf.iVal, leaf.fVal,
        //            leaf.sVal, leaf.childLeft, leaf.childRight);
        // }
    }
    if (flag) {
        // evalUtil(row, 0, res, resType);
        eval2(row, offset2, types2, exprArr2, res, resType);
    }
}



// __device__ void evalUtil(void *row, int currPos, void *&res, int &resType) {
//     printf("CURR POS: %d\n", currPos);
//     printf("WhereExpr size: %lu\n", sizeof(exprArr[0]));
//     whereExpr *expr = exprArr + currPos;
//     printf("Address: %ld\n", (long) &expr);
//     const auto leaf = *expr;
//     printf("TYPE inside Eval: %d, ival: %d, fval: %f, sval: %s, left: %d, right: %d\n", leaf.type, leaf.iVal, leaf.fVal,
//            leaf.sVal, leaf.childLeft, leaf.childRight);
//     switch (expr->type) {
//         case CONSTANT_ERR:
//             // printf("ERROR NOT SUPPORTED YET\n");
//             break;
//         case CONSTANT_INT:
//             // printf("INT_VAL\n");
//             // fflush(stdout);
//             res = malloc(sizeof(int));
//             resType = RESTYPE_INT;
//             memcpy(res, &expr->iVal, sizeof(int));
//             printf("val: %d\n", *((int *) res));
//             printf("val: %d\n", expr->iVal);
//             break;
//         case CONSTANT_FLT:
//             res = malloc(sizeof(float));
//             resType = RESTYPE_FLT;
//             memcpy(res, &expr->fVal, sizeof(float));
//             break;
//         case CONSTANT_STR: {
//             int len = myStrlen(expr->sVal);
//             res = malloc(sizeof(char) * len + 1);
//             resType = (int) (-len - 1);
//             memcpy(res, &expr->sVal, len + 1);
//             break;
//         }
//         case COL_NAME: {
//             int i = expr->iVal;
//             int start = offset[i];
//             int end = offset[i + 1];
//             switch (types[i].type) {
//                 case TYPE_INT:
//                     res = malloc(sizeof(int));
//                     resType = RESTYPE_INT;
//                     memcpy(res, (char *) row + start, sizeof(int));
//                     printf("Col val: %d\n", *(int *) res);
//                     break;
//                 case TYPE_FLOAT:
//                     res = malloc(sizeof(float));
//                     resType = RESTYPE_FLT;
//                     memcpy(res, (char *) row + start, sizeof(float));
//                     break;
//                 case TYPE_BOOL:
//                     printf("Not yet implemented\n");
//                     break;
//                 case TYPE_VARCHAR:
//                     res = malloc(end - start);
//                     resType = -(end - start + 1);
//                     memcpy(res, (char *) row + start, end - start);
//                     break;
//                 case TYPE_DATETIME:
//                     printf("Not yet implemented 2\n");
//                     break;
//                 case TYPE_INVALID:
//                     printf("INVALID TYPE!\n");
//                     break;
//             }
//             break;
//         }
//         case OPERATOR_PL: {
//             void *lres, *rres;
//             int ltype = 0, rtype = 0;
//             //eval(row, rowSize, offset, offsetSize, types, exprArr, expr->childLeft, lres, ltype);
//             // size_t mem_free_0, mem_tot_0;
//             // cudaMemGetInfo(&mem_free_0, &mem_tot_0);
//             printf("left: %d, right: %d\n", expr->childLeft, expr->childRight);
//             evalUtil(row, expr->childLeft, lres, ltype);
//             //eval(row, rowSize, offset, offsetSize, types, exprArr, expr->childRight, rres, rtype);
//             evalUtil(row, expr->childRight, rres, rtype);;
//             resType = RESTYPE_FLT;
//             if (ltype == RESTYPE_FLT && rtype == RESTYPE_FLT) {
//                 res = malloc(sizeof(float));
//                 float temp = 0;
//                 float lhs, rhs;
//                 memcpy(&lhs, lres, sizeof(float));
//                 memcpy(&rhs, rres, sizeof(float));
//                 temp = lhs + rhs;
//                 memcpy(res, &temp, sizeof(float));
//             } else if (ltype == RESTYPE_FLT) {
//                 res = malloc(sizeof(float));
//                 float temp = 0;
//                 float lhs;
//                 int rhs;
//                 memcpy(&lhs, lres, sizeof(float));
//                 memcpy(&rhs, rres, sizeof(int));
//                 temp = lhs + rhs;
//                 memcpy(res, &temp, sizeof(float));
//             } else if (rtype == RESTYPE_FLT) {
//                 res = malloc(sizeof(float));
//                 float temp = 0;
//                 int lhs;
//                 float rhs;
//                 memcpy(&lhs, lres, sizeof(int));
//                 memcpy(&rhs, rres, sizeof(float));
//                 temp = (lhs + rhs);
//                 memcpy(res, &temp, sizeof(float));
//             } else {
//                 res = malloc(sizeof(int));
//                 resType = RESTYPE_INT;
//                 int temp;
//                 int lhs, rhs;
//                 memcpy(&lhs, lres, sizeof(int));
//                 memcpy(&rhs, rres, sizeof(int));
//                 temp = (lhs + rhs);
//                 memcpy(res, &temp, sizeof(int));
//                 // printf("lhs: %d, rhs: %d", lhs, rhs);
//             }
//             // fflush(stdout);
//             free(lres);
//             free(rres);
//             break;
//         }
//         case OPERATOR_AND: {
//             void *lres, *rres;
//             int ltype = 0, rtype = 0;
//             //eval(row, rowSize, offset, offsetSize, types, exprArr, expr->childLeft, lres, ltype);
//             evalUtil(row, expr->childLeft, lres, ltype);
//             //eval(row, rowSize, offset, offsetSize, types, exprArr, expr->childRight, rres, rtype);
//             evalUtil(row, expr->childRight, rres, rtype);
//             res = malloc(sizeof(int));
//             resType = RESTYPE_INT;
//             int temp = 0;
//             if (ltype == RESTYPE_FLT && rtype == RESTYPE_FLT) {
//                 float lhs, rhs;
//                 lhs = *(float *) lres;
//                 rhs = *(float *) rres;
//                 // memcpy(&lhs, lres, sizeof(float));
//                 // memcpy(&rhs, rres, sizeof(float));
//                 temp = lhs && rhs;
//             } else if (ltype == RESTYPE_FLT) {
//                 float lhs;
//                 int rhs;
//                 lhs = *(float *) lres;
//                 rhs = *(int *) rres;
//                 // memcpy(&lhs, lres, sizeof(float));
//                 // memcpy(&rhs, rres, sizeof(int));
//                 temp = lhs && rhs;
//             } else if (rtype == RESTYPE_FLT) {
//                 int lhs;
//                 float rhs;
//                 lhs = *(int *) lres;
//                 rhs = *(float *) rres;
//                 // memcpy(&lhs, lres, sizeof(int));
//                 // memcpy(&rhs, rres, sizeof(float));
//                 temp = lhs && rhs;
//             } else {
//                 int lhs, rhs;
//                 lhs = *(int *) lres;
//                 rhs = *(int *) rres;
//                 // memcpy(&lhs, lres, sizeof(int));
//                 // memcpy(&rhs, rres, sizeof(int));
//                 temp = lhs && rhs;
//             }
//             memcpy(res, &temp, sizeof(int));
//             // printf("INSIDE AND %d\n", temp);
//             // fflush(stdout);
//             free(lres);
//             free(rres);
//             break;
//         }
//         case OPERATOR_OR: {
//             void *lres, *rres;
//             int ltype = 0, rtype = 0;
//             //eval(row, rowSize, offset, offsetSize, types, exprArr, expr->childLeft, lres, ltype);
//             evalUtil(row, expr->childLeft, lres, ltype);
//             //eval(row, rowSize, offset, offsetSize, types, exprArr, expr->childRight, rres, rtype);
//             evalUtil(row, expr->childRight, rres, rtype);
//             res = malloc(sizeof(int));
//             resType = RESTYPE_INT;
//             int temp = 0;
//             if (ltype == RESTYPE_FLT && rtype == RESTYPE_FLT) {
//                 float lhs, rhs;
//                 memcpy(&lhs, lres, sizeof(float));
//                 memcpy(&rhs, rres, sizeof(float));
//                 temp = lhs || rhs;
//             } else if (ltype == RESTYPE_FLT) {
//                 float lhs;
//                 int rhs;
//                 memcpy(&lhs, lres, sizeof(float));
//                 memcpy(&rhs, rres, sizeof(int));
//                 temp = lhs || rhs;
//             } else if (rtype == RESTYPE_FLT) {
//                 int lhs;
//                 float rhs;
//                 memcpy(&lhs, lres, sizeof(int));
//                 memcpy(&rhs, rres, sizeof(float));
//                 temp = lhs || rhs;
//             } else {
//                 int lhs, rhs;
//                 memcpy(&lhs, lres, sizeof(int));
//                 memcpy(&rhs, rres, sizeof(int));
//                 temp = lhs || rhs;
//             }
//             memcpy(res, &temp, sizeof(int));
//             // printf("INSIDE AND %d\n", temp);
//             // fflush(stdout);
//             free(lres);
//             free(rres);
//             break;
//         }
//         case OPERATOR_NOT: {
//             void *lres;
//             int ltype = 0;
//             //eval(row, rowSize, offset, offsetSize, types, exprArr, expr->childLeft, lres, ltype);
//             evalUtil(row, expr->childLeft, lres, ltype);
//             res = malloc(sizeof(int));
//             resType = RESTYPE_INT;
//             int temp = 0;
//             if (ltype == RESTYPE_FLT) {
//                 float lhs;
//                 memcpy(&lhs, lres, sizeof(float));
//                 temp = !lhs;
//             } else {
//                 int lhs;
//                 memcpy(&lhs, lres, sizeof(int));
//                 temp = !lhs;
//                 // printf("lhs: %d, rhs: %d", lhs, rhs);
//             }
//             memcpy(res, &temp, sizeof(int));
//             // printf("INSIDE = %d\n", temp);
//             // fflush(stdout);
//             free(lres);
//             break;
//         }
//         case OPERATOR_EQ: {
//             void *lres, *rres;
//             int ltype = 0, rtype = 0;
//             //eval(row, rowSize, offset, offsetSize, types, exprArr, expr->childLeft, lres, ltype);
//             evalUtil(row, expr->childLeft, lres, ltype);
//             //eval(row, rowSize, offset, offsetSize, types, exprArr, expr->childRight, rres, rtype);
//             evalUtil(row, expr->childRight, rres, rtype);
//             res = malloc(sizeof(int));
//             resType = RESTYPE_INT;
//             int temp = 0;
//             if (ltype == RESTYPE_FLT && rtype == RESTYPE_FLT) {
//                 float lhs, rhs;
//                 memcpy(&lhs, lres, sizeof(float));
//                 memcpy(&rhs, rres, sizeof(float));
//                 temp = lhs == rhs;
//             } else if (ltype == RESTYPE_FLT) {
//                 float lhs;
//                 int rhs;
//                 memcpy(&lhs, lres, sizeof(float));
//                 memcpy(&rhs, rres, sizeof(int));
//                 temp = lhs == rhs;
//             } else if (rtype == RESTYPE_FLT) {
//                 int lhs;
//                 float rhs;
//                 memcpy(&lhs, lres, sizeof(int));
//                 memcpy(&rhs, rres, sizeof(float));
//                 temp = lhs == rhs;
//             } else {
//                 int lhs, rhs;
//                 memcpy(&lhs, lres, sizeof(int));
//                 memcpy(&rhs, rres, sizeof(int));
//                 temp = lhs == rhs;
//                 // printf("lhs: %d, rhs: %d", lhs, rhs);
//             }
//             memcpy(res, &temp, sizeof(int));
//             // printf("INSIDE = %d\n", temp);
//             // fflush(stdout);
//             free(lres);
//             free(rres);
//             break;
//         }
//         case OPERATOR_NE: {
//             void *lres, *rres;
//             int ltype = 0, rtype = 0;
//             //eval(row, rowSize, offset, offsetSize, types, exprArr, expr->childLeft, lres, ltype);
//             evalUtil(row, expr->childLeft, lres, ltype);
//             //eval(row, rowSize, offset, offsetSize, types, exprArr, expr->childRight, rres, rtype);
//             evalUtil(row, expr->childRight, rres, rtype);
//             res = malloc(sizeof(int));
//             resType = RESTYPE_INT;
//             int temp = 0;
//             if (ltype == RESTYPE_FLT && rtype == RESTYPE_FLT) {
//                 float lhs, rhs;
//                 memcpy(&lhs, lres, sizeof(float));
//                 memcpy(&rhs, rres, sizeof(float));
//                 temp = (lhs != rhs);
//             } else if (ltype == RESTYPE_FLT) {
//                 float lhs;
//                 int rhs;
//                 memcpy(&lhs, lres, sizeof(float));
//                 memcpy(&rhs, rres, sizeof(int));
//                 temp = (lhs != rhs);
//             } else if (rtype == RESTYPE_FLT) {
//                 int lhs;
//                 float rhs;
//                 memcpy(&lhs, lres, sizeof(int));
//                 memcpy(&rhs, rres, sizeof(float));
//                 temp = (lhs != rhs);
//             } else {
//                 int lhs, rhs;
//                 memcpy(&lhs, lres, sizeof(int));
//                 memcpy(&rhs, rres, sizeof(int));
//                 temp = (lhs != rhs);
//                 // printf("lhs: %d, rhs: %d", lhs, rhs);
//             }
//             memcpy(res, &temp, sizeof(int));
//             // printf("INSIDE = %d\n", temp);
//             // fflush(stdout);
//             free(lres);
//             free(rres);
//             break;
//         }
//         case OPERATOR_GE: {
//             void *lres, *rres;
//             int ltype = 0, rtype = 0;
//             //eval(row, rowSize, offset, offsetSize, types, exprArr, expr->childLeft, lres, ltype);
//             evalUtil(row, expr->childLeft, lres, ltype);
//             //eval(row, rowSize, offset, offsetSize, types, exprArr, expr->childRight, rres, rtype);
//             evalUtil(row, expr->childRight, rres, rtype);;
//             res = malloc(sizeof(int));
//             resType = RESTYPE_INT;
//             int temp = 0;
//             if (ltype == RESTYPE_FLT && rtype == RESTYPE_FLT) {
//                 float lhs, rhs;
//                 memcpy(&lhs, lres, sizeof(float));
//                 memcpy(&rhs, rres, sizeof(float));
//                 temp = (lhs >= rhs);
//             } else if (ltype == RESTYPE_FLT) {
//                 float lhs;
//                 int rhs;
//                 memcpy(&lhs, lres, sizeof(float));
//                 memcpy(&rhs, rres, sizeof(int));
//                 temp = (lhs >= rhs);
//             } else if (rtype == RESTYPE_FLT) {
//                 int lhs;
//                 float rhs;
//                 memcpy(&lhs, lres, sizeof(int));
//                 memcpy(&rhs, rres, sizeof(float));
//                 temp = (lhs >= rhs);
//             } else {
//                 int lhs, rhs;
//                 memcpy(&lhs, lres, sizeof(int));
//                 memcpy(&rhs, rres, sizeof(int));
//                 temp = (lhs >= rhs);
//                 // printf("lhs: %d, rhs: %d", lhs, rhs);
//             }
//             memcpy(res, &temp, sizeof(int));
//             // printf("INSIDE = %d\n", temp);
//             // fflush(stdout);
//             free(lres);
//             free(rres);
//             break;
//         }
//         case OPERATOR_LE: {
//             void *lres, *rres;
//             int ltype = 0, rtype = 0;
//             //eval(row, rowSize, offset, offsetSize, types, exprArr, expr->childLeft, lres, ltype);
//             evalUtil(row, expr->childLeft, lres, ltype);
//             //eval(row, rowSize, offset, offsetSize, types, exprArr, expr->childRight, rres, rtype);
//             evalUtil(row, expr->childRight, rres, rtype);;
//             res = malloc(sizeof(int));
//             resType = RESTYPE_INT;
//             int temp = 0;
//             if (ltype == RESTYPE_FLT && rtype == RESTYPE_FLT) {
//                 float lhs, rhs;
//                 memcpy(&lhs, lres, sizeof(float));
//                 memcpy(&rhs, rres, sizeof(float));
//                 temp = (lhs <= rhs);
//             } else if (ltype == RESTYPE_FLT) {
//                 float lhs;
//                 int rhs;
//                 memcpy(&lhs, lres, sizeof(float));
//                 memcpy(&rhs, rres, sizeof(int));
//                 temp = (lhs <= rhs);
//             } else if (rtype == RESTYPE_FLT) {
//                 int lhs;
//                 float rhs;
//                 memcpy(&lhs, lres, sizeof(int));
//                 memcpy(&rhs, rres, sizeof(float));
//                 temp = (lhs <= rhs);
//             } else {
//                 int lhs, rhs;
//                 memcpy(&lhs, lres, sizeof(int));
//                 memcpy(&rhs, rres, sizeof(int));
//                 temp = (lhs <= rhs);
//                 // printf("lhs: %d, rhs: %d", lhs, rhs);
//             }
//             memcpy(res, &temp, sizeof(int));
//             // printf("INSIDE = %d\n", temp);
//             // fflush(stdout);
//             free(lres);
//             free(rres);
//             break;
//         }
//         case OPERATOR_GT: {
//             void *lres, *rres;
//             int ltype = 0, rtype = 0;
//             //eval(row, rowSize, offset, offsetSize, types, exprArr, expr->childLeft, lres, ltype);
//             evalUtil(row, expr->childLeft, lres, ltype);
//             //eval(row, rowSize, offset, offsetSize, types, exprArr, expr->childRight, rres, rtype);
//             evalUtil(row, expr->childRight, rres, rtype);;
//             res = malloc(sizeof(int));
//             resType = RESTYPE_INT;
//             int temp = 0;
//             if (ltype == RESTYPE_FLT && rtype == RESTYPE_FLT) {
//                 float lhs, rhs;
//                 memcpy(&lhs, lres, sizeof(float));
//                 memcpy(&rhs, rres, sizeof(float));
//                 temp = (lhs > rhs);
//             } else if (ltype == RESTYPE_FLT) {
//                 float lhs;
//                 int rhs;
//                 memcpy(&lhs, lres, sizeof(float));
//                 memcpy(&rhs, rres, sizeof(int));
//                 temp = (lhs > rhs);
//             } else if (rtype == RESTYPE_FLT) {
//                 int lhs;
//                 float rhs;
//                 memcpy(&lhs, lres, sizeof(int));
//                 memcpy(&rhs, rres, sizeof(float));
//                 temp = (lhs > rhs);
//             } else {
//                 int lhs, rhs;
//                 memcpy(&lhs, lres, sizeof(int));
//                 memcpy(&rhs, rres, sizeof(int));
//                 temp = (lhs > rhs);
//                 // printf("lhs: %d, rhs: %d", lhs, rhs);
//             }
//             memcpy(res, &temp, sizeof(int));
//             // printf("INSIDE = %d\n", temp);
//             // fflush(stdout);
//             free(lres);
//             free(rres);
//             break;
//         }
//         case OPERATOR_LT: {
//             void *lres, *rres;
//             int ltype = 0, rtype = 0;
//             //eval(row, rowSize, offset, offsetSize, types, exprArr, expr->childLeft, lres, ltype);
//             evalUtil(row, expr->childLeft, lres, ltype);
//             //eval(row, rowSize, offset, offsetSize, types, exprArr, expr->childRight, rres, rtype);
//             evalUtil(row, expr->childRight, rres, rtype);;
//             res = malloc(sizeof(int));
//             resType = RESTYPE_INT;
//             int temp = 0;
//             if (ltype == RESTYPE_FLT && rtype == RESTYPE_FLT) {
//                 float lhs, rhs;
//                 memcpy(&lhs, lres, sizeof(float));
//                 memcpy(&rhs, rres, sizeof(float));
//                 temp = (lhs < rhs);
//             } else if (ltype == RESTYPE_FLT) {
//                 float lhs;
//                 int rhs;
//                 memcpy(&lhs, lres, sizeof(float));
//                 memcpy(&rhs, rres, sizeof(int));
//                 temp = (lhs < rhs);
//             } else if (rtype == RESTYPE_FLT) {
//                 int lhs;
//                 float rhs;
//                 memcpy(&lhs, lres, sizeof(int));
//                 memcpy(&rhs, rres, sizeof(float));
//                 temp = (lhs < rhs);
//             } else {
//                 int lhs, rhs;
//                 memcpy(&lhs, lres, sizeof(int));
//                 memcpy(&rhs, rres, sizeof(int));
//                 temp = (lhs < rhs);
//                 // printf("lhs: %d, rhs: %d", lhs, rhs);
//             }
//             memcpy(res, &temp, sizeof(int));
//             // printf("INSIDE = %d\n", temp);
//             // fflush(stdout);
//             free(lres);
//             free(rres);
//             break;
//         }
//         case OPERATOR_MI: {
//             void *lres, *rres;
//             int ltype = 0, rtype = 0;
//             //eval(row, rowSize, offset, offsetSize, types, exprArr, expr->childLeft, lres, ltype);
//             evalUtil(row, expr->childLeft, lres, ltype);
//             //eval(row, rowSize, offset, offsetSize, types, exprArr, expr->childRight, rres, rtype);
//             evalUtil(row, expr->childRight, rres, rtype);
//             res = malloc(sizeof(int));
//             resType = RESTYPE_FLT;
//             if (ltype == RESTYPE_FLT && rtype == RESTYPE_FLT) {
//                 float temp = 0;
//                 float lhs, rhs;
//                 memcpy(&lhs, lres, sizeof(float));
//                 memcpy(&rhs, rres, sizeof(float));
//                 temp = lhs - rhs;
//                 memcpy(res, &temp, sizeof(float));
//             } else if (ltype == RESTYPE_FLT) {
//                 float temp = 0;
//                 float lhs;
//                 int rhs;
//                 memcpy(&lhs, lres, sizeof(float));
//                 memcpy(&rhs, rres, sizeof(int));
//                 temp = lhs - rhs;
//                 memcpy(res, &temp, sizeof(float));
//             } else if (rtype == RESTYPE_FLT) {
//                 float temp = 0;
//                 int lhs;
//                 float rhs;
//                 memcpy(&lhs, lres, sizeof(int));
//                 memcpy(&rhs, rres, sizeof(float));
//                 temp = (lhs - rhs);
//                 memcpy(res, &temp, sizeof(float));
//             } else {
//                 resType = RESTYPE_INT;
//                 int temp;
//                 int lhs, rhs;
//                 memcpy(&lhs, lres, sizeof(int));
//                 memcpy(&rhs, rres, sizeof(int));
//                 temp = (lhs - rhs);
//                 memcpy(res, &temp, sizeof(int));
//                 // printf("lhs: %d, rhs: %d", lhs, rhs);
//             }
//             // fflush(stdout);
//             free(lres);
//             free(rres);
//             break;
//         }
//         case OPERATOR_MU: {
//             void *lres, *rres;
//             int ltype = 0, rtype = 0;
//             //eval(row, rowSize, offset, offsetSize, types, exprArr, expr->childLeft, lres, ltype);
//             evalUtil(row, expr->childLeft, lres, ltype);
//             //eval(row, rowSize, offset, offsetSize, types, exprArr, expr->childRight, rres, rtype);
//             evalUtil(row, expr->childRight, rres, rtype);
//             res = malloc(sizeof(int));
//             resType = RESTYPE_FLT;
//             if (ltype == RESTYPE_FLT && rtype == RESTYPE_FLT) {
//                 float temp = 0;
//                 float lhs, rhs;
//                 memcpy(&lhs, lres, sizeof(float));
//                 memcpy(&rhs, rres, sizeof(float));
//                 temp = lhs * rhs;
//                 memcpy(res, &temp, sizeof(float));
//             } else if (ltype == RESTYPE_FLT) {
//                 float temp = 0;
//                 float lhs;
//                 int rhs;
//                 memcpy(&lhs, lres, sizeof(float));
//                 memcpy(&rhs, rres, sizeof(int));
//                 temp = lhs * rhs;
//                 memcpy(res, &temp, sizeof(float));
//             } else if (rtype == RESTYPE_FLT) {
//                 float temp = 0;
//                 int lhs;
//                 float rhs;
//                 memcpy(&lhs, lres, sizeof(int));
//                 memcpy(&rhs, rres, sizeof(float));
//                 temp = (lhs * rhs);
//                 memcpy(res, &temp, sizeof(float));
//                 // printf("Value : !!%f!!", temp);
//             } else {
//                 resType = RESTYPE_INT;
//                 int temp;
//                 int lhs, rhs;
//                 memcpy(&lhs, lres, sizeof(int));
//                 memcpy(&rhs, rres, sizeof(int));
//                 printf("lhs: %d, rhs: %d", lhs, rhs);
//                 temp = (lhs * rhs);
//                 memcpy(res, &temp, sizeof(int));
//             }
//             // fflush(stdout);
//             free(lres);
//             free(rres);
//             break;
//         }
//         case OPERATOR_DI: {
//             void *lres, *rres;
//             int ltype = 0, rtype = 0;
//             //eval(row, rowSize, offset, offsetSize, types, exprArr, expr->childLeft, lres, ltype);
//             evalUtil(row, expr->childLeft, lres, ltype);
//             //eval(row, rowSize, offset, offsetSize, types, exprArr, expr->childRight, rres, rtype);
//             evalUtil(row, expr->childRight, rres, rtype);
//             res = malloc(sizeof(int));
//             resType = RESTYPE_FLT;
//             if (ltype == RESTYPE_FLT && rtype == RESTYPE_FLT) {
//                 float temp = 0;
//                 float lhs, rhs;
//                 memcpy(&lhs, lres, sizeof(float));
//                 memcpy(&rhs, rres, sizeof(float));
//                 temp = lhs / rhs;
//                 memcpy(res, &temp, sizeof(float));
//             } else if (ltype == RESTYPE_FLT) {
//                 float temp = 0;
//                 float lhs;
//                 int rhs;
//                 memcpy(&lhs, lres, sizeof(float));
//                 memcpy(&rhs, rres, sizeof(int));
//                 temp = lhs / rhs;
//                 memcpy(res, &temp, sizeof(float));
//             } else if (rtype == RESTYPE_FLT) {
//                 float temp = 0;
//                 int lhs;
//                 float rhs;
//                 memcpy(&lhs, lres, sizeof(int));
//                 memcpy(&rhs, rres, sizeof(float));
//                 temp = (lhs / rhs);
//                 memcpy(res, &temp, sizeof(float));
//             } else {
//                 resType = RESTYPE_INT;
//                 int temp;
//                 int lhs, rhs;
//                 memcpy(&lhs, lres, sizeof(int));
//                 memcpy(&rhs, rres, sizeof(int));
//                 temp = (lhs / rhs);
//                 memcpy(res, &temp, sizeof(int));
//                 // printf("lhs: %d, rhs: %d", lhs, rhs);
//             }
//             // fflush(stdout);
//             free(lres);
//             free(rres);
//             break;
//         }
//         case OPERATOR_MO: {
//             void *lres, *rres;
//             int ltype = 0, rtype = 0;
//             //eval(row, rowSize, offset, offsetSize, types, exprArr, expr->childLeft, lres, ltype);
//             evalUtil(row, expr->childLeft, lres, ltype);
//             //eval(row, rowSize, offset, offsetSize, types, exprArr, expr->childRight, rres, rtype);
//             evalUtil(row, expr->childRight, rres, rtype);
//             res = malloc(sizeof(int));
//             resType = RESTYPE_INT;
//             int temp = 0;
//             if (ltype == RESTYPE_FLT && rtype == RESTYPE_FLT) {
//                 float lhs, rhs;
//                 memcpy(&lhs, lres, sizeof(float));
//                 memcpy(&rhs, rres, sizeof(float));
//                 temp = (int) lhs % (int) rhs;
//             } else if (ltype == RESTYPE_FLT) {
//                 float lhs;
//                 int rhs;
//                 memcpy(&lhs, lres, sizeof(float));
//                 memcpy(&rhs, rres, sizeof(int));
//                 temp = (int) lhs % rhs;
//             } else if (rtype == RESTYPE_FLT) {
//                 int lhs;
//                 float rhs;
//                 memcpy(&lhs, lres, sizeof(int));
//                 memcpy(&rhs, rres, sizeof(float));
//                 temp = lhs % (int) rhs;
//             } else {
//                 int lhs, rhs;
//                 memcpy(&lhs, lres, sizeof(int));
//                 memcpy(&rhs, rres, sizeof(int));
//                 temp = lhs % rhs;
//                 // printf("lhs: %d, rhs: %d", lhs, rhs);
//             }
//             memcpy(res, &temp, sizeof(int));
//             // fflush(stdout);
//             free(lres);
//             free(rres);
//             break;
//         }
//         case OPERATOR_UMI: {
//             void *lres;
//             int ltype = 0;
//             //eval(row, rowSize, offset, offsetSize, types, exprArr, expr->childLeft, lres, ltype);
//             evalUtil(row, expr->childLeft, lres, ltype);
//             res = malloc(sizeof(int));
//             resType = RESTYPE_FLT;
//             if (ltype == RESTYPE_FLT) {
//                 float temp = 0;
//                 float lhs;
//                 memcpy(&lhs, lres, sizeof(float));
//                 temp = -lhs;
//                 memcpy(res, &temp, sizeof(int));
//             } else {
//                 resType = RESTYPE_INT;
//                 int temp;
//                 int lhs;
//                 memcpy(&lhs, lres, sizeof(int));
//                 temp = -lhs;
//                 memcpy(res, &temp, sizeof(int));
//                 // printf("lhs: %d, rhs: %d", lhs, rhs);
//             }
//             // fflush(stdout);
//             free(lres);
//             break;
//         }
//     }
// }

__device__ int myStrncmp(const char *str_a, const char *str_b, unsigned len) {
    int match = 0;
    unsigned i = 0;
    unsigned done = 0;
    while ((i < len) && (match == 0) && !done) {
        if ((str_a[i] == 0) || (str_b[i] == 0)) done = 1;
        else if (str_a[i] != str_b[i]) {
            match = i + 1;
            if ((int) str_a[i] - (int) str_b[i] < 0) match = 0 - (i + 1);
        }
        i++;
    }
    return match;
}

__device__ int myStrlen(const char *str) {
    int length = 0;
    while (str[length++] != 0);
    return length;
}