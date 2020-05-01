//
// Created by gautam on 28/04/20.
//

#include "deviceUtil.h"

void eval(void *row, int rowSize, const int *offset, int offsetSize, char **cols, Metadata::ColType types[], whereExpr *exprArr, int currPos,
          void *&res, int &resType){
    auto expr = exprArr[currPos];
    switch (expr.type) {
        case CONSTANT_ERR:
            // printf("ERROR NOT SUPPORTED YET\n");
            break;
        case CONSTANT_INT:
            // printf("INT_VAL\n");
            fflush(stdout);
            res = malloc(sizeof(int));
            resType = RESTYPE_INT;
            memcpy(res, &expr.iVal, sizeof(int));
            // printf("val: %d\n", *((int *) res));
            break;
        case CONSTANT_FLT:
            res = malloc(sizeof(float));
            resType = RESTYPE_FLT;
            memcpy(res, &expr.fVal, sizeof(float));
            break;
        case CONSTANT_STR:
            res = malloc(sizeof(char) * strlen(expr.sVal) + 1);
            resType = (int)(-(strlen(expr.sVal)) - 1);
            memcpy(res, &expr.sVal, strlen(expr.sVal) + 1);
            break;
        case COL_NAME:
            // printf("COL_NAME\n");
            fflush(stdout);
            for (int i = 0; i < offsetSize; i++) {
                // printf("cols[i] : %s\n", cols[i]);
                fflush(stdout);
                if (strncmp(cols[i], expr.sVal, sizeof(expr.sVal)) == 0) {
                    // printf("Col Name: %s\n", expr.sVal);
                    fflush(stdout);
                    int start = offset[i];
                    int end = offset[i + 1];
                    switch (types[i].type) {
                        case Metadata::TYPE_INT:
                            res = malloc(sizeof(int));
                            resType = RESTYPE_INT;
                            memcpy(res, (char *) row + start, sizeof(int));
                            break;
                        case Metadata::TYPE_FLOAT:
                            res = malloc(sizeof(float));
                            resType = RESTYPE_FLT;
                            memcpy(res, (char *) row + start, sizeof(float));
                            break;
                        case Metadata::TYPE_BOOL:
                            // printf("Not yet implemented\n");
                            break;
                        case Metadata::TYPE_VARCHAR:
                            res = malloc(end - start);
                            resType = -(end - start + 1);
                            memcpy(res, (char *) row + start, end - start);
                            break;
                        case Metadata::TYPE_DATETIME:
                            // printf("Not yet implemented 2\n");
                            break;
                        case Metadata::TYPE_INVALID:
                            // printf("INVALID TYPE!\n");
                            break;
                    }
                    break;
                }
                if (i == offsetSize - 1) {
                    // printf("No such column\n");
                }
            }
            break;
        case OPERATOR_AND:{
            void *lres, *rres;
            int ltype = 0, rtype = 0;
            eval(row, rowSize, offset, offsetSize, cols, types, exprArr, expr.childLeft, lres, ltype);
            eval(row, rowSize, offset, offsetSize, cols, types, exprArr, expr.childRight, rres, rtype);
            res = malloc(sizeof(int));
            resType = RESTYPE_INT;
            int temp = 0;
            if (ltype == RESTYPE_FLT && rtype == RESTYPE_FLT) {
                float lhs, rhs;
                memcpy(&lhs, lres, sizeof(float));
                memcpy(&rhs, rres, sizeof(float));
                temp = lhs && rhs;
            } else if (ltype == RESTYPE_FLT) {
                float lhs;
                int rhs;
                memcpy(&lhs, lres, sizeof(float));
                memcpy(&rhs, rres, sizeof(int));
                temp = lhs && rhs;
            } else if (rtype == RESTYPE_FLT){
                int lhs;
                float rhs;
                memcpy(&lhs, lres, sizeof(int));
                memcpy(&rhs, rres, sizeof(float));
                temp = lhs && rhs;
            } else {
                int lhs, rhs;
                memcpy(&lhs, lres, sizeof(int));
                memcpy(&rhs, rres, sizeof(int));
                temp = lhs && rhs;
            }
            memcpy(res, &temp, sizeof(int));
            // printf("INSIDE AND %d\n", temp);
            fflush(stdout);
            free(lres);
            free(rres);
            break;
        }
        case OPERATOR_OR:{
            void *lres, *rres;
            int ltype = 0, rtype = 0;
            eval(row, rowSize, offset, offsetSize, cols, types, exprArr, expr.childLeft, lres, ltype);
            eval(row, rowSize, offset, offsetSize, cols, types, exprArr, expr.childRight, rres, rtype);
            res = malloc(sizeof(int));
            resType = RESTYPE_INT;
            int temp = 0;
            if (ltype == RESTYPE_FLT && rtype == RESTYPE_FLT) {
                float lhs, rhs;
                memcpy(&lhs, lres, sizeof(float));
                memcpy(&rhs, rres, sizeof(float));
                temp = lhs || rhs;
            } else if (ltype == RESTYPE_FLT) {
                float lhs;
                int rhs;
                memcpy(&lhs, lres, sizeof(float));
                memcpy(&rhs, rres, sizeof(int));
                temp = lhs || rhs;
            } else if (rtype == RESTYPE_FLT){
                int lhs;
                float rhs;
                memcpy(&lhs, lres, sizeof(int));
                memcpy(&rhs, rres, sizeof(float));
                temp = lhs || rhs;
            } else {
                int lhs, rhs;
                memcpy(&lhs, lres, sizeof(int));
                memcpy(&rhs, rres, sizeof(int));
                temp = lhs || rhs;
            }
            memcpy(res, &temp, sizeof(int));
            // printf("INSIDE AND %d\n", temp);
            fflush(stdout);
            free(lres);
            free(rres);
            break;
        }
        case OPERATOR_NOT:{
            void *lres;
            int ltype = 0;
            eval(row, rowSize, offset, offsetSize, cols, types, exprArr, expr.childLeft, lres, ltype);
            res = malloc(sizeof(int));
            resType = RESTYPE_INT;
            int temp = 0;
            if (ltype == RESTYPE_FLT) {
                float lhs;
                memcpy(&lhs, lres, sizeof(float));
                temp = !lhs;
            } else {
                int lhs, rhs;
                memcpy(&lhs, lres, sizeof(int));
                temp = !lhs;
                // printf("lhs: %d, rhs: %d", lhs, rhs);
            }
            memcpy(res, &temp, sizeof(int));
            // printf("INSIDE = %d\n", temp);
            fflush(stdout);
            free(lres);
            break;
        }   
        case OPERATOR_EQ: {
            void *lres, *rres;
            int ltype = 0, rtype = 0;
            eval(row, rowSize, offset, offsetSize, cols, types, exprArr, expr.childLeft, lres, ltype);
            eval(row, rowSize, offset, offsetSize, cols, types, exprArr, expr.childRight, rres, rtype);
            res = malloc(sizeof(int));
            resType = RESTYPE_INT;
            int temp = 0;
            if (ltype == RESTYPE_FLT && rtype == RESTYPE_FLT) {
                float lhs, rhs;
                memcpy(&lhs, lres, sizeof(float));
                memcpy(&rhs, rres, sizeof(float));
                temp = lhs == rhs;
            } else if (ltype == RESTYPE_FLT) {
                float lhs;
                int rhs;
                memcpy(&lhs, lres, sizeof(float));
                memcpy(&rhs, rres, sizeof(int));
                temp = lhs == rhs;
            } else if (rtype == RESTYPE_FLT) {
                int lhs;
                float rhs;
                memcpy(&lhs, lres, sizeof(int));
                memcpy(&rhs, rres, sizeof(float));
                temp = lhs == rhs;
            } else {
                int lhs, rhs;
                memcpy(&lhs, lres, sizeof(int));
                memcpy(&rhs, rres, sizeof(int));
                temp = lhs == rhs;
                // printf("lhs: %d, rhs: %d", lhs, rhs);
            }
            memcpy(res, &temp, sizeof(int));
            // printf("INSIDE = %d\n", temp);
            fflush(stdout);
            free(lres);
            free(rres);
            break;
        }
        case OPERATOR_NE:{
            void *lres, *rres;
            int ltype = 0, rtype = 0;
            eval(row, rowSize, offset, offsetSize, cols, types, exprArr, expr.childLeft, lres, ltype);
            eval(row, rowSize, offset, offsetSize, cols, types, exprArr, expr.childRight, rres, rtype);
            res = malloc(sizeof(int));
            resType = RESTYPE_INT;
            int temp = 0;
            if (ltype == RESTYPE_FLT && rtype == RESTYPE_FLT) {
                float lhs, rhs;
                memcpy(&lhs, lres, sizeof(float));
                memcpy(&rhs, rres, sizeof(float));
                temp = (lhs != rhs);
            } else if (ltype == RESTYPE_FLT) {
                float lhs;
                int rhs;
                memcpy(&lhs, lres, sizeof(float));
                memcpy(&rhs, rres, sizeof(int));
                temp = (lhs != rhs);
            } else if (rtype == RESTYPE_FLT) {
                int lhs;
                float rhs;
                memcpy(&lhs, lres, sizeof(int));
                memcpy(&rhs, rres, sizeof(float));
                temp = (lhs != rhs);
            } else {
                int lhs, rhs;
                memcpy(&lhs, lres, sizeof(int));
                memcpy(&rhs, rres, sizeof(int));
                temp = (lhs != rhs);
                // printf("lhs: %d, rhs: %d", lhs, rhs);
            }
            memcpy(res, &temp, sizeof(int));
            // printf("INSIDE = %d\n", temp);
            fflush(stdout);
            free(lres);
            free(rres);
            break;
        }
        case OPERATOR_GE:{
            void *lres, *rres;
            int ltype = 0, rtype = 0;
            eval(row, rowSize, offset, offsetSize, cols, types, exprArr, expr.childLeft, lres, ltype);
            eval(row, rowSize, offset, offsetSize, cols, types, exprArr, expr.childRight, rres, rtype);
            res = malloc(sizeof(int));
            resType = RESTYPE_INT;
            int temp = 0;
            if (ltype == RESTYPE_FLT && rtype == RESTYPE_FLT) {
                float lhs, rhs;
                memcpy(&lhs, lres, sizeof(float));
                memcpy(&rhs, rres, sizeof(float));
                temp = (lhs >= rhs);
            } else if (ltype == RESTYPE_FLT) {
                float lhs;
                int rhs;
                memcpy(&lhs, lres, sizeof(float));
                memcpy(&rhs, rres, sizeof(int));
                temp = (lhs >= rhs);
            } else if (rtype == RESTYPE_FLT) {
                int lhs;
                float rhs;
                memcpy(&lhs, lres, sizeof(int));
                memcpy(&rhs, rres, sizeof(float));
                temp = (lhs >= rhs);
            } else {
                int lhs, rhs;
                memcpy(&lhs, lres, sizeof(int));
                memcpy(&rhs, rres, sizeof(int));
                temp = (lhs >= rhs);
                // printf("lhs: %d, rhs: %d", lhs, rhs);
            }
            memcpy(res, &temp, sizeof(int));
            // printf("INSIDE = %d\n", temp);
            fflush(stdout);
            free(lres);
            free(rres);
            break;
        }
        case OPERATOR_LE:{
            void *lres, *rres;
            int ltype = 0, rtype = 0;
            eval(row, rowSize, offset, offsetSize, cols, types, exprArr, expr.childLeft, lres, ltype);
            eval(row, rowSize, offset, offsetSize, cols, types, exprArr, expr.childRight, rres, rtype);
            res = malloc(sizeof(int));
            resType = RESTYPE_INT;
            int temp = 0;
            if (ltype == RESTYPE_FLT && rtype == RESTYPE_FLT) {
                float lhs, rhs;
                memcpy(&lhs, lres, sizeof(float));
                memcpy(&rhs, rres, sizeof(float));
                temp = (lhs <= rhs);
            } else if (ltype == RESTYPE_FLT) {
                float lhs;
                int rhs;
                memcpy(&lhs, lres, sizeof(float));
                memcpy(&rhs, rres, sizeof(int));
                temp = (lhs <= rhs);
            } else if (rtype == RESTYPE_FLT) {
                int lhs;
                float rhs;
                memcpy(&lhs, lres, sizeof(int));
                memcpy(&rhs, rres, sizeof(float));
                temp = (lhs <= rhs);
            } else {
                int lhs, rhs;
                memcpy(&lhs, lres, sizeof(int));
                memcpy(&rhs, rres, sizeof(int));
                temp = (lhs <= rhs);
                // printf("lhs: %d, rhs: %d", lhs, rhs);
            }
            memcpy(res, &temp, sizeof(int));
            // printf("INSIDE = %d\n", temp);
            fflush(stdout);
            free(lres);
            free(rres);
            break;
        }
        case OPERATOR_GT:{
            void *lres, *rres;
            int ltype = 0, rtype = 0;
            eval(row, rowSize, offset, offsetSize, cols, types, exprArr, expr.childLeft, lres, ltype);
            eval(row, rowSize, offset, offsetSize, cols, types, exprArr, expr.childRight, rres, rtype);
            res = malloc(sizeof(int));
            resType = RESTYPE_INT;
            int temp = 0;
            if (ltype == RESTYPE_FLT && rtype == RESTYPE_FLT) {
                float lhs, rhs;
                memcpy(&lhs, lres, sizeof(float));
                memcpy(&rhs, rres, sizeof(float));
                temp = (lhs > rhs);
            } else if (ltype == RESTYPE_FLT) {
                float lhs;
                int rhs;
                memcpy(&lhs, lres, sizeof(float));
                memcpy(&rhs, rres, sizeof(int));
                temp = (lhs > rhs);
            } else if (rtype == RESTYPE_FLT) {
                int lhs;
                float rhs;
                memcpy(&lhs, lres, sizeof(int));
                memcpy(&rhs, rres, sizeof(float));
                temp = (lhs > rhs);
            } else {
                int lhs, rhs;
                memcpy(&lhs, lres, sizeof(int));
                memcpy(&rhs, rres, sizeof(int));
                temp = (lhs > rhs);
                // printf("lhs: %d, rhs: %d", lhs, rhs);
            }
            memcpy(res, &temp, sizeof(int));
            // printf("INSIDE = %d\n", temp);
            fflush(stdout);
            free(lres);
            free(rres);
            break;
        }
        case OPERATOR_LT:{
            void *lres, *rres;
            int ltype = 0, rtype = 0;
            eval(row, rowSize, offset, offsetSize, cols, types, exprArr, expr.childLeft, lres, ltype);
            eval(row, rowSize, offset, offsetSize, cols, types, exprArr, expr.childRight, rres, rtype);
            res = malloc(sizeof(int));
            resType = RESTYPE_INT;
            int temp = 0;
            if (ltype == RESTYPE_FLT && rtype == RESTYPE_FLT) {
                float lhs, rhs;
                memcpy(&lhs, lres, sizeof(float));
                memcpy(&rhs, rres, sizeof(float));
                temp = (lhs < rhs);
            } else if (ltype == RESTYPE_FLT) {
                float lhs;
                int rhs;
                memcpy(&lhs, lres, sizeof(float));
                memcpy(&rhs, rres, sizeof(int));
                temp = (lhs < rhs);
            } else if (rtype == RESTYPE_FLT) {
                int lhs;
                float rhs;
                memcpy(&lhs, lres, sizeof(int));
                memcpy(&rhs, rres, sizeof(float));
                temp = (lhs < rhs);
            } else {
                int lhs, rhs;
                memcpy(&lhs, lres, sizeof(int));
                memcpy(&rhs, rres, sizeof(int));
                temp = (lhs < rhs);
                // printf("lhs: %d, rhs: %d", lhs, rhs);
            }
            memcpy(res, &temp, sizeof(int));
            // printf("INSIDE = %d\n", temp);
            fflush(stdout);
            free(lres);
            free(rres);
            break;
        }
        case OPERATOR_PL:{
            void *lres, *rres;
            int ltype = 0, rtype = 0;
            eval(row, rowSize, offset, offsetSize, cols, types, exprArr, expr.childLeft, lres, ltype);
            eval(row, rowSize, offset, offsetSize, cols, types, exprArr, expr.childRight, rres, rtype);
            res = malloc(sizeof(int));
            resType = RESTYPE_FLT;
            if (ltype == RESTYPE_FLT && rtype == RESTYPE_FLT) {
            	float temp = 0;
                float lhs, rhs;
                memcpy(&lhs, lres, sizeof(float));
                memcpy(&rhs, rres, sizeof(float));
                temp = lhs + rhs;
            	memcpy(res, &temp, sizeof(float));
            } else if (ltype == RESTYPE_FLT) {
            	float temp = 0;
                float lhs;
                int rhs;
                memcpy(&lhs, lres, sizeof(float));
                memcpy(&rhs, rres, sizeof(int));
                temp = lhs + rhs;
            	memcpy(res, &temp, sizeof(float));
            } else if (rtype == RESTYPE_FLT) {
            	float temp = 0;
                int lhs;
                float rhs;
                memcpy(&lhs, lres, sizeof(int));
                memcpy(&rhs, rres, sizeof(float));
                temp = (lhs + rhs);
            	memcpy(res, &temp, sizeof(float));
            } else {
                resType = RESTYPE_INT;
            	int temp;
                int lhs, rhs;
                memcpy(&lhs, lres, sizeof(int));
                memcpy(&rhs, rres, sizeof(int));
                temp = (lhs + rhs);
            	memcpy(res, &temp, sizeof(int));
                // printf("lhs: %d, rhs: %d", lhs, rhs);
            }
            fflush(stdout);
            free(lres);
            free(rres);
            break;
        }
        case OPERATOR_MI:{
            void *lres, *rres;
            int ltype = 0, rtype = 0;
            eval(row, rowSize, offset, offsetSize, cols, types, exprArr, expr.childLeft, lres, ltype);
            eval(row, rowSize, offset, offsetSize, cols, types, exprArr, expr.childRight, rres, rtype);
            res = malloc(sizeof(int));
            resType = RESTYPE_FLT;
            if (ltype == RESTYPE_FLT && rtype == RESTYPE_FLT) {
            	float temp = 0;
                float lhs, rhs;
                memcpy(&lhs, lres, sizeof(float));
                memcpy(&rhs, rres, sizeof(float));
                temp = lhs - rhs;
            	memcpy(res, &temp, sizeof(float));
            } else if (ltype == RESTYPE_FLT) {
            	float temp = 0;
                float lhs;
                int rhs;
                memcpy(&lhs, lres, sizeof(float));
                memcpy(&rhs, rres, sizeof(int));
                temp = lhs - rhs;
            	memcpy(res, &temp, sizeof(float));
            } else if (rtype == RESTYPE_FLT) {
            	float temp = 0;
                int lhs;
                float rhs;
                memcpy(&lhs, lres, sizeof(int));
                memcpy(&rhs, rres, sizeof(float));
                temp = (lhs - rhs);
            	memcpy(res, &temp, sizeof(float));
            } else {
                resType = RESTYPE_INT;
            	int temp;
                int lhs, rhs;
                memcpy(&lhs, lres, sizeof(int));
                memcpy(&rhs, rres, sizeof(int));
                temp = (lhs - rhs);
            	memcpy(res, &temp, sizeof(int));
                // printf("lhs: %d, rhs: %d", lhs, rhs);
            }
            fflush(stdout);
            free(lres);
            free(rres);
            break;
        }
        case OPERATOR_MU:{
            void *lres, *rres;
            int ltype = 0, rtype = 0;
            eval(row, rowSize, offset, offsetSize, cols, types, exprArr, expr.childLeft, lres, ltype);
            eval(row, rowSize, offset, offsetSize, cols, types, exprArr, expr.childRight, rres, rtype);
            res = malloc(sizeof(int));
            resType = RESTYPE_FLT;
            if (ltype == RESTYPE_FLT && rtype == RESTYPE_FLT) {
            	float temp = 0;
                float lhs, rhs;
                memcpy(&lhs, lres, sizeof(float));
                memcpy(&rhs, rres, sizeof(float));
                temp = lhs * rhs;
            	memcpy(res, &temp, sizeof(float));
            } else if (ltype == RESTYPE_FLT) {
            	float temp = 0;
                float lhs;
                int rhs;
                memcpy(&lhs, lres, sizeof(float));
                memcpy(&rhs, rres, sizeof(int));
                temp = lhs * rhs;
            	memcpy(res, &temp, sizeof(float));
            } else if (rtype == RESTYPE_FLT) {
            	float temp = 0;
                int lhs;
                float rhs;
                memcpy(&lhs, lres, sizeof(int));
                memcpy(&rhs, rres, sizeof(float));
                temp = (lhs * rhs);
            	memcpy(res, &temp, sizeof(float));
            	// printf("Value : !!%f!!", temp);
            } else {
                resType = RESTYPE_INT;
            	int temp;
                int lhs, rhs;
                memcpy(&lhs, lres, sizeof(int));
                memcpy(&rhs, rres, sizeof(int));
                temp = (lhs * rhs);
            	memcpy(res, &temp, sizeof(int));
                // printf("lhs: %d, rhs: %d", lhs, rhs);
            }
            fflush(stdout);
            free(lres);
            free(rres);
            break;
        }
        case OPERATOR_DI:{
            void *lres, *rres;
            int ltype = 0, rtype = 0;
            eval(row, rowSize, offset, offsetSize, cols, types, exprArr, expr.childLeft, lres, ltype);
            eval(row, rowSize, offset, offsetSize, cols, types, exprArr, expr.childRight, rres, rtype);
            res = malloc(sizeof(int));
            resType = RESTYPE_FLT;
            if (ltype == RESTYPE_FLT && rtype == RESTYPE_FLT) {
            	float temp = 0;
                float lhs, rhs;
                memcpy(&lhs, lres, sizeof(float));
                memcpy(&rhs, rres, sizeof(float));
                temp = lhs / rhs;
            	memcpy(res, &temp, sizeof(float));
            } else if (ltype == RESTYPE_FLT) {
            	float temp = 0;
                float lhs;
                int rhs;
                memcpy(&lhs, lres, sizeof(float));
                memcpy(&rhs, rres, sizeof(int));
                temp = lhs / rhs;
            	memcpy(res, &temp, sizeof(float));
            } else if (rtype == RESTYPE_FLT) {
            	float temp = 0;
                int lhs;
                float rhs;
                memcpy(&lhs, lres, sizeof(int));
                memcpy(&rhs, rres, sizeof(float));
                temp = (lhs / rhs);
            	memcpy(res, &temp, sizeof(float));
            } else {
                resType = RESTYPE_INT;
            	int temp;
                int lhs, rhs;
                memcpy(&lhs, lres, sizeof(int));
                memcpy(&rhs, rres, sizeof(int));
                temp = (lhs / rhs);
            	memcpy(res, &temp, sizeof(int));
                // printf("lhs: %d, rhs: %d", lhs, rhs);
            }
            fflush(stdout);
            free(lres);
            free(rres);
            break;
        }
        case OPERATOR_MO:{
            void *lres, *rres;
            int ltype = 0, rtype = 0;
            eval(row, rowSize, offset, offsetSize, cols, types, exprArr, expr.childLeft, lres, ltype);
            eval(row, rowSize, offset, offsetSize, cols, types, exprArr, expr.childRight, rres, rtype);
            res = malloc(sizeof(int));
            resType = RESTYPE_INT;
            int temp = 0;
            if (ltype == RESTYPE_FLT && rtype == RESTYPE_FLT) {
                float lhs, rhs;
                memcpy(&lhs, lres, sizeof(float));
                memcpy(&rhs, rres, sizeof(float));
                temp = (int)lhs % (int)rhs;
            } else if (ltype == RESTYPE_FLT) {
                float lhs;
                int rhs;
                memcpy(&lhs, lres, sizeof(float));
                memcpy(&rhs, rres, sizeof(int));
                temp = (int)lhs % rhs;
            } else if (rtype == RESTYPE_FLT) {
                int lhs;
                float rhs;
                memcpy(&lhs, lres, sizeof(int));
                memcpy(&rhs, rres, sizeof(float));
                temp = lhs % (int)rhs;
            } else {
                int lhs, rhs;
                memcpy(&lhs, lres, sizeof(int));
                memcpy(&rhs, rres, sizeof(int));
                temp = lhs % rhs;
                // printf("lhs: %d, rhs: %d", lhs, rhs);
            }
            memcpy(res, &temp, sizeof(int));
            fflush(stdout);
            free(lres);
            free(rres);
            break;
        }
        case OPERATOR_UMI:{
            void *lres;
            int ltype = 0;
            eval(row, rowSize, offset, offsetSize, cols, types, exprArr, expr.childLeft, lres, ltype);
            res = malloc(sizeof(int));
            resType = RESTYPE_FLT;
            if (ltype == RESTYPE_FLT) {
            	float temp = 0;
                float lhs;
                memcpy(&lhs, lres, sizeof(float));
                temp = -lhs;
                memcpy(res, &temp, sizeof(int));
            } else {
                resType = RESTYPE_INT;
            	int temp;
                int lhs, rhs;
                memcpy(&lhs, lres, sizeof(int));
                temp = -lhs;
                memcpy(res, &temp, sizeof(int));
                // printf("lhs: %d, rhs: %d", lhs, rhs);
            }
            fflush(stdout);
            free(lres);
            break;
        }  
    }
}