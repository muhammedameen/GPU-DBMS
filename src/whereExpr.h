//
// Created by gautam on 27/04/20.
//

#ifndef DBASE_WHEREEXPR_H
#define DBASE_WHEREEXPR_H

#include <cstring>
#include <cstdlib>

enum whereExprType{
    CONSTANT_ERR,
    CONSTANT_INT,
    CONSTANT_FLT,
    CONSTANT_STR,
    COL_NAME,
    OPERATOR_AND,
    OPERATOR_OR,
    OPERATOR_NOT,
    OPERATOR_EQ,
    OPERATOR_NE,
    OPERATOR_GE,
    OPERATOR_LE,
    OPERATOR_GT,
    OPERATOR_LT,
    OPERATOR_PL,
    OPERATOR_MI,
    OPERATOR_MU,
    OPERATOR_DI,
    OPERATOR_MO,
    OPERATOR_UMI,
};

// const int CONSTANT_ERR = -1;
//
// const int CONSTANT_INT = 0;
// const int CONSTANT_FLT = 1;
// const int CONSTANT_STR = 2;
// const int COL_NAME = 3;
//
// const int OPERATOR_AND = 10;
// const int OPERATOR_OR = 11;
// const int OPERATOR_NOT = 12;
//
// const int OPERATOR_EQ = 20;
// const int OPERATOR_NE = 21;
// const int OPERATOR_GE = 22;
// const int OPERATOR_LE = 23;
// const int OPERATOR_GT = 24;
// const int OPERATOR_LT = 25;
//
// const int OPERATOR_PL = 30;
// const int OPERATOR_MI = 31;
// const int OPERATOR_MU = 32;
// const int OPERATOR_DI = 33;
// const int OPERATOR_MO = 34;
//
// const int OPERATOR_UMI = 40;

struct whereExpr {
    whereExprType type;
    int iVal;
    float fVal;
    char *sVal;
    int childLeft;
    int childRight;
};

whereExpr *newExpr(whereExprType type, long intVal);

whereExpr *newExpr(whereExprType type, float fVal);

whereExpr *newExpr(whereExprType type, char *sVal);

whereExpr *newExpr(whereExprType type);

void freeExpr(whereExpr *expr);

#endif //DBASE_WHEREEXPR_H
