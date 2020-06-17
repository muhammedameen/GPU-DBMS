//
// Created by gautam on 28/04/20.
//

#include "deviceUtil.cuh"

__device__ int printStar(void *row, ColType *colTypes, int numCols, char *buff) {
    int start =  0;
    // char buff[100];
    int buffStart = 0;
    // float flt;
    // memcpy(&flt, (char *) row + 12, sizeof(float));
    // float * fltptr = (float *)((char *)row + 12);
    // printf("Float: %f, %f\n", *fltptr, flt);
    for (int i = 0; i < numCols; start += colTypes[i].size, i++) {
        // printf("i: %d, start: %d\n", i, start);
        switch (colTypes[i].type) {
            case TYPE_INT: {
                // int *temp = ((int *) ((char *) row + start));
                int temp;
                memcpy(&temp, (char *)row + start, sizeof(int));
                if (!isNull(&temp)) {
                    buffStart += appendInt(buff + buffStart, temp);
                } else {
                    buffStart += appendStr(buff + buffStart, "NULL");
                }
                break;
            }
            case TYPE_FLOAT: {
                float temp;
                memcpy(&temp, (char *) row + start, sizeof(float));
                // printf("FLOAT VAL: %f, %f\n", temp, *(float *)((char *) row + start));
                // printf("FLOAT USING MEMCPY: %f\n", temp2);
                // float *temp = ((float *) ((char *) row + start));

                if (!isNull(&temp)) {
                    buffStart += appendFlt(buff + buffStart, temp);
                    // printf("Float val: %f\n", temp);
                } else {
                    buffStart += appendStr(buff + buffStart, "NULL");
                }
                break;
            }
            case TYPE_VARCHAR: {
                char *temp = (char *) row + start;

                if (!isNull(temp)) {
                    buffStart += appendStr(buff + buffStart, temp);
                } else {
                    buffStart += appendStr(buff + buffStart, "NULL");
                }
                break;
            }
            default:
                printf("Not yet implemented");
        }
        if (i != numCols - 1) {
            buffStart += appendStr(buff + buffStart, ", ");
        }
    }
    buff[buffStart] = 0;
    return buffStart;
    // printf("%s\n", buff);
}

__device__ void printRowDevice(void *row, ColType *colTypes, int numCols, const int *dispCols, int numDispCols, const int *offsets) {
    char *buff = (char *)malloc(sizeof(char) * 250);
    int buffStart = 0;
    for (int i = 0; i < numDispCols; ++i) {
        if (dispCols[i] == -1) {
            buffStart += printStar(row, colTypes, numCols, buff + buffStart);
        } else if (dispCols[i] == -2) {
            printf("Not implemented");
            free(buff);
            return;
        } else {
            int colId = dispCols[i];
            switch (colTypes[colId].type) {
                case TYPE_INT: {
                    // int *temp = ((int *) ((char *) row + offsets[colId]));
                    int temp;
                    memcpy(&temp, (char *)row + offsets[colId], sizeof(int));
                    if (!isNull(&temp)) {
                        buffStart += appendInt(buff + buffStart, temp);
                    } else {
                        buffStart += appendStr(buff + buffStart, "NULL");
                    }
                    break;
                }
                case TYPE_FLOAT: {
                    // float *temp = ((float *) ((char *) row + offsets[colId]));
                    float temp;
                    memcpy(&temp, (char *)row + offsets[colId], sizeof(float));
                    if (!isNull(&temp)) {
                        buffStart += appendFlt(buff + buffStart, temp);
                    } else {
                        buffStart += appendStr(buff + buffStart, "NULL");
                    }
                    break;
                }
                case TYPE_VARCHAR: {
                    char *temp = (char *) row + offsets[colId];
                    if (!isNull(temp)) {
                        buffStart += appendStr(buff + buffStart, temp);
                    } else {
                        buffStart += appendStr(buff + buffStart, "NULL");
                    }
                    break;
                }
                default:
                    printf("Not yet implemented");
            }
        }
        if (i != numDispCols - 1) {
            buffStart += appendStr(buff + buffStart, ", ");
        }
    }
    buff[buffStart] = 0;
    printf("%s\n", buff);
    free(buff);
}

__device__ void eval(void *row, int *offset, ColType *types, myExpr *exprArr, void *&res, int &resType) {
    const int MAX_DEPTH = 50;
    int *exprStack = (int *) malloc(sizeof(int) * MAX_DEPTH);
    exprStack[0] = 0;        // Push Expr of 0
    bool *solved = (bool *) malloc(sizeof(bool) * 100);
    void **resArr = (void **) malloc(sizeof(void *) * 100);
    int *resTypeArr = (int *) malloc(sizeof(int) * 100);
    bool *freeAble = (bool *) malloc(sizeof(bool) * 100);
    for (int i = 0; i < 100; i++) {solved[i] = false; freeAble[i] = true;}
    int count = 1;
    while (count > 0) {
        // pop
        int index = exprStack[count - 1];
        myExpr *expr = &exprArr[index];
        --count;
        // check if children are solved; if solved evaluate current node; else push children
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
            case CONSTANT_FLT: {
                solved[index] = true;
                resTypeArr[index] = RESTYPE_FLT;
                float *temp = (float *) malloc(sizeof(float));
                *temp = expr->fVal;
                resArr[index] = temp;
                break;
            }
            case CONSTANT_STR:{
                solved[index] = true;
                resTypeArr[index] = -myStrlen(expr->sVal) - 1;
                resArr[index] = expr->sVal;
                freeAble[index] = false;
                break;
            }
            case COL_NAME: {
                int colId = expr->iVal;
                int start = offset[colId];
                solved[index] = true;
                resArr[index] = (char *) row + start;
                freeAble[index] = false;
                switch (types[colId].type) {
                    case TYPE_INT: {
                        resTypeArr[index] = RESTYPE_INT;
                        break;
                    }
                    case TYPE_FLOAT: {
                        resTypeArr[index] = RESTYPE_FLT;
                        break;
                    }
                    case TYPE_VARCHAR: {
                        resTypeArr[index] = types[colId].size;
                        break;
                    }
                    default:
                        printf("Not implemented\n");
                }
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
                        float *temp = (float *) malloc(sizeof(float));
                        lhs = *(float *) lres;
                        rhs = *(float *) rres;
                        *temp = lhs + rhs;
                        resArr[index] = temp;
                    } else if (ltype == RESTYPE_FLT) {
                        float lhs;
                        int rhs;
                        float *temp = (float *) malloc(sizeof(float));
                        lhs = *(float *) lres;
                        rhs = *(int *) rres;
                        *temp = lhs + rhs;
                        resArr[index] = temp;
                    } else if (rtype == RESTYPE_FLT) {
                        int lhs;
                        float rhs;
                        float *temp = (float *) malloc(sizeof(float));
                        lhs = *(int *) lres;
                        rhs = *(float *) rres;
                        *temp = lhs + rhs;
                        resArr[index] = temp;
                    } else {
                        resTypeArr[index] = RESTYPE_INT;
                        int *temp = (int *) malloc(sizeof(float));
                        int lhs, rhs;
                        lhs = *(int *) lres;
                        rhs = *(int *) rres;
                        *temp = lhs + rhs;
                        resArr[index] = temp;
                    }
                }
                break;
            }
            case OPERATOR_EQ: {
                if (solved[expr->childLeft] && solved[expr->childRight]) {
                    solved[index] = true;
                    int ltype = resTypeArr[expr->childLeft];
                    int rtype = resTypeArr[expr->childRight];
                    void *lres = resArr[expr->childLeft];
                    void *rres = resArr[expr->childRight];
                    resTypeArr[index] = RESTYPE_INT;
                    int *temp = (int *) malloc(sizeof(int));
                    if (ltype == RESTYPE_FLT && rtype == RESTYPE_FLT) {
                        float lhs, rhs;
                        lhs = *(float *) lres;
                        rhs = *(float *) rres;
                        *temp = lhs == rhs;
                    } else if (ltype == RESTYPE_FLT && rtype == RESTYPE_INT) {
                        float lhs;
                        int rhs;
                        lhs = *(float *) lres;
                        rhs = *(int *) rres;
                        *temp = lhs == rhs;
                    } else if (rtype == RESTYPE_FLT && ltype == RESTYPE_INT) {
                        int lhs;
                        float rhs;
                        lhs = *(int *) lres;
                        rhs = *(float *) rres;
                        *temp = lhs == rhs;
                    } else if (ltype == RESTYPE_INT && rtype == RESTYPE_INT){
                        int lhs, rhs;
                        lhs = *(int *) lres;
                        rhs = *(int *) rres;
                        *temp = lhs == rhs;
                    } else {
                        *temp = myStrncmp((const char *) lres, (const char *) rres, min(-ltype, -rtype)) == 0;
                    }
                    resArr[index] = temp;
                }
                break;
            }
            case OPERATOR_MI: {
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
                        *temp = lhs - rhs;
                        resArr[index] = temp;
                    } else if (ltype == RESTYPE_FLT) {
                        float lhs;
                        int rhs;
                        float *temp = (float *)malloc(sizeof(float));
                        lhs = *(float *) lres;
                        rhs = *(int *) rres;
                        *temp = lhs - rhs;
                        resArr[index] = temp;
                    } else if (rtype == RESTYPE_FLT) {
                        int lhs;
                        float rhs;
                        float *temp = (float *)malloc(sizeof(float));
                        lhs = *(int *) lres;
                        rhs = *(float *) rres;
                        *temp = lhs - rhs;
                        resArr[index] = temp;
                    } else {
                        resTypeArr[index] = RESTYPE_INT;
                        int *temp = (int *)malloc(sizeof(int));
                        int lhs, rhs;
                        lhs = *(int *) lres;
                        rhs = *(int *) rres;
                        *temp = lhs - rhs;
                        resArr[index] = temp;
                    }
                }
                break;
            }
            case OPERATOR_MU: {
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
                        *temp = lhs * rhs;
                        resArr[index] = temp;
                    } else if (ltype == RESTYPE_FLT) {
                        float lhs;
                        int rhs;
                        float *temp = (float *)malloc(sizeof(float));
                        lhs = *(float *) lres;
                        rhs = *(int *) rres;
                        *temp = lhs * rhs;
                        resArr[index] = temp;
                    } else if (rtype == RESTYPE_FLT) {
                        int lhs;
                        float rhs;
                        float *temp = (float *)malloc(sizeof(float));
                        lhs = *(int *) lres;
                        rhs = *(float *) rres;
                        *temp = lhs * rhs;
                        resArr[index] = temp;
                    } else {
                        resTypeArr[index] = RESTYPE_INT;
                        int *temp = (int *)malloc(sizeof(int));
                        int lhs, rhs;
                        lhs = *(int *) lres;
                        rhs = *(int *) rres;
                        *temp = lhs * rhs;
                        resArr[index] = temp;
                    }
                }
                break;
            }
            case OPERATOR_DI: {
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
                        *temp = lhs / rhs;
                        resArr[index] = temp;
                    } else if (ltype == RESTYPE_FLT) {
                        float lhs;
                        int rhs;
                        float *temp = (float *)malloc(sizeof(float));
                        lhs = *(float *) lres;
                        rhs = *(int *) rres;
                        *temp = lhs / rhs;
                        resArr[index] = temp;
                    } else if (rtype == RESTYPE_FLT) {
                        int lhs;
                        float rhs;
                        float *temp = (float *)malloc(sizeof(float));
                        lhs = *(int *) lres;
                        rhs = *(float *) rres;
                        *temp = lhs / rhs;
                        resArr[index] = temp;
                    } else {
                        resTypeArr[index] = RESTYPE_INT;
                        int *temp = (int *)malloc(sizeof(int));
                        int lhs, rhs;
                        lhs = *(int *) lres;
                        rhs = *(int *) rres;
                        *temp = lhs / rhs;
                        resArr[index] = temp;
                    }
                }
                break;
            }
            case OPERATOR_GT: {
                if (solved[expr->childLeft] && solved[expr->childRight]) {
                    solved[index] = true;
                    int ltype = resTypeArr[expr->childLeft];
                    int rtype = resTypeArr[expr->childRight];
                    void *lres = resArr[expr->childLeft];
                    void *rres = resArr[expr->childRight];
                    resTypeArr[index] = RESTYPE_INT;
                    int *temp = (int *)malloc(sizeof(int));
                    if (ltype == RESTYPE_FLT && rtype == RESTYPE_FLT) {
                        float lhs, rhs;
                        lhs = *(float *) lres;
                        rhs = *(float *) rres;
                        *temp = lhs > rhs;
                        resArr[index] = temp;
                    } else if (ltype == RESTYPE_FLT) {
                        float lhs;
                        int rhs;
                        lhs = *(float *) lres;
                        rhs = *(int *) rres;
                        *temp = lhs > rhs;
                        resArr[index] = temp;
                    } else if (rtype == RESTYPE_FLT) {
                        int lhs;
                        float rhs;
                        lhs = *(int *) lres;
                        rhs = *(float *) rres;
                        *temp = lhs > rhs;
                        resArr[index] = temp;
                    } else {
                        resTypeArr[index] = RESTYPE_INT;
                        int lhs, rhs;
                        lhs = *(int *) lres;
                        rhs = *(int *) rres;
                        *temp = lhs > rhs;
                        resArr[index] = temp;
                    }
                }
                break;
            }
            case OPERATOR_GE: {
                if (solved[expr->childLeft] && solved[expr->childRight]) {
                    solved[index] = true;
                    int ltype = resTypeArr[expr->childLeft];
                    int rtype = resTypeArr[expr->childRight];
                    void *lres = resArr[expr->childLeft];
                    void *rres = resArr[expr->childRight];
                    resTypeArr[index] = RESTYPE_INT;
                    int *temp = (int *)malloc(sizeof(int));
                    if (ltype == RESTYPE_FLT && rtype == RESTYPE_FLT) {
                        float lhs, rhs;
                        lhs = *(float *) lres;
                        rhs = *(float *) rres;
                        *temp = lhs >= rhs;
                        resArr[index] = temp;
                    } else if (ltype == RESTYPE_FLT) {
                        float lhs;
                        int rhs;
                        lhs = *(float *) lres;
                        rhs = *(int *) rres;
                        *temp = lhs >= rhs;
                        resArr[index] = temp;
                    } else if (rtype == RESTYPE_FLT) {
                        int lhs;
                        float rhs;
                        lhs = *(int *) lres;
                        rhs = *(float *) rres;
                        *temp = lhs >= rhs;
                        resArr[index] = temp;
                    } else {
                        resTypeArr[index] = RESTYPE_INT;
                        int lhs, rhs;
                        lhs = *(int *) lres;
                        rhs = *(int *) rres;
                        *temp = lhs >= rhs;
                        resArr[index] = temp;
                    }
                }
                break;
            }
            case OPERATOR_LT: {
                if (solved[expr->childLeft] && solved[expr->childRight]) {
                    solved[index] = true;
                    int ltype = resTypeArr[expr->childLeft];
                    int rtype = resTypeArr[expr->childRight];
                    void *lres = resArr[expr->childLeft];
                    void *rres = resArr[expr->childRight];
                    resTypeArr[index] = RESTYPE_INT;
                    int *temp = (int *)malloc(sizeof(int));
                    if (ltype == RESTYPE_FLT && rtype == RESTYPE_FLT) {
                        float lhs, rhs;
                        lhs = *(float *) lres;
                        rhs = *(float *) rres;
                        *temp = lhs < rhs;
                        resArr[index] = temp;
                    } else if (ltype == RESTYPE_FLT) {
                        float lhs;
                        int rhs;
                        lhs = *(float *) lres;
                        rhs = *(int *) rres;
                        *temp = lhs < rhs;
                        resArr[index] = temp;
                    } else if (rtype == RESTYPE_FLT) {
                        int lhs;
                        float rhs;
                        lhs = *(int *) lres;
                        rhs = *(float *) rres;
                        *temp = lhs < rhs;
                        resArr[index] = temp;
                    } else {
                        resTypeArr[index] = RESTYPE_INT;
                        int lhs, rhs;
                        lhs = *(int *) lres;
                        rhs = *(int *) rres;
                        *temp = lhs < rhs;
                        resArr[index] = temp;
                    }
                }
                break;
            }
            case OPERATOR_LE: {
                if (solved[expr->childLeft] && solved[expr->childRight]) {
                    solved[index] = true;
                    int ltype = resTypeArr[expr->childLeft];
                    int rtype = resTypeArr[expr->childRight];
                    void *lres = resArr[expr->childLeft];
                    void *rres = resArr[expr->childRight];
                    resTypeArr[index] = RESTYPE_INT;
                    int *temp = (int *)malloc(sizeof(int));
                    if (ltype == RESTYPE_FLT && rtype == RESTYPE_FLT) {
                        float lhs, rhs;
                        lhs = *(float *) lres;
                        rhs = *(float *) rres;
                        *temp = lhs <= rhs;
                        resArr[index] = temp;
                    } else if (ltype == RESTYPE_FLT) {
                        float lhs;
                        int rhs;
                        lhs = *(float *) lres;
                        rhs = *(int *) rres;
                        *temp = lhs <= rhs;
                        resArr[index] = temp;
                    } else if (rtype == RESTYPE_FLT) {
                        int lhs;
                        float rhs;
                        lhs = *(int *) lres;
                        rhs = *(float *) rres;
                        *temp = lhs <= rhs;
                        resArr[index] = temp;
                    } else {
                        resTypeArr[index] = RESTYPE_INT;
                        int lhs, rhs;
                        lhs = *(int *) lres;
                        rhs = *(int *) rres;
                        *temp = lhs <= rhs;
                        resArr[index] = temp;
                    }
                }
                break;
            }
            case OPERATOR_MO: {
                if (solved[expr->childLeft] && solved[expr->childRight]) {
                    solved[index] = true;
                    // int ltype = resTypeArr[expr->childLeft];
                    // int rtype = resTypeArr[expr->childRight];
                    void *lres = resArr[expr->childLeft];
                    void *rres = resArr[expr->childRight];
                    resTypeArr[index] = RESTYPE_INT;
                    int *temp = (int *)malloc(sizeof(int));
                    int lhs, rhs;
                    lhs = *(int *) lres;
                    rhs = *(int *) rres;
                    *temp = lhs % rhs;
                    resArr[index] = temp;
                }
                break;
            }
            default:
                printf("Not yet implemented");
        }
        if(!solved[index]){
            // push this and ALL children
            exprStack[count] = index;
            ++count;
            if (expr->childLeft != -1) {
                exprStack[count] = expr->childLeft;
                ++count;
            }
            if (expr->childRight != -1) {
                exprStack[count] = expr->childRight;
                ++count;
            }
            continue;
        }
    }
    // Result and restype are stored in resArr[0] and resArrType[0]
    res = resArr[0];
    resType = resTypeArr[0];
    free(resTypeArr);
    for (int i = 1; i < 100; i++) {
        if (solved[i] && freeAble[i]) {
            free(resArr[i]);
        }
    }
    free(resArr);
}

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

__device__ void reverse(char* str, int len)
{
    int i = 0, j = len - 1, temp;
    while (i < j) {
        temp = str[i];
        str[i] = str[j];
        str[j] = temp;
        i++;
        j--;
    }
}

// Implementation of itoa()
__device__ char* itoa(int num, char* str)
{
    int base = 10;
    int i = 0;
    bool isNegative = false;

    /* Handle 0 explicitely, otherwise empty string is printed for 0 */
    if (num == 0)
    {
        str[i++] = '0';
        str[i] = '\0';
        return str;
    }

    // In standard itoa(), negative numbers are handled only with
    // base 10. Otherwise numbers are considered unsigned.
    if (num < 0 && base == 10)
    {
        isNegative = true;
        num = -num;
    }

    // Process individual digits
    while (num != 0)
    {
        int rem = num % base;
        str[i++] = (rem > 9)? (rem-10) + 'a' : rem + '0';
        num = num/base;
    }

    // If number is negative, append '-'
    if (isNegative)
        str[i++] = '-';

    str[i] = '\0'; // Append string terminator

    // Reverse the string
    reverse(str, i);

    return str;
}

__device__ int intToStr(int x, char str[], int d)
{
    int i = 0;
    while (x) {
        str[i++] = (x % 10) + '0';
        x = x / 10;
    }

    // If number of digits required is more, then
    // add 0s at the beginning
    while (i < d)
        str[i++] = '0';

    reverse(str, i);
    str[i] = '\0';
    return i;
}

// Converts a floating-point/double number to a string.
__device__ void ftoa(float n, char* res, int afterpoint)
{
    // Extract integer part
    int ipart = (int)n;

    // Extract floating part
    float fpart = n - (float)ipart;

    // convert integer part to string
    int i = intToStr(ipart, res, 0);

    // check for display option after point
    if (afterpoint != 0) {
        res[i] = '.'; // add dot

        // Get the value of fraction part upto given no.
        // of points after dot. The third parameter
        // is needed to handle cases like 233.007
        fpart = fpart * pow(10, afterpoint);

        intToStr((int)fpart, res + i + 1, afterpoint);
    }
}

__device__ int appendInt(char *data, int i) {
    char str[20];
    itoa(i,str);
    int j=0;
    while(str[j] != '\0'){
        data[j] = str[j];
        j++;
    }
    return j;
}

__device__ int appendFlt(char *data, float f) {
    char str[30];
    int precision = 5;
    ftoa(f, str, precision);
    int j=0;
    while(str[j] != '\0'){
        data[j] = str[j];
        j++;
    }
    return j;
}

__device__ int appendStr(char *data, const char *str) {
    int j=0;
    while(str[j] != '\0'){
        data[j] = str[j];
        j++;
    }
    return j;
}


