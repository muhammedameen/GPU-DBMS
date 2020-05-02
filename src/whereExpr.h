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

typedef struct {
    whereExprType type;
    int iVal;
    float fVal;
    char *sVal;
    int childLeft;
    int childRight;
} whereExpr;

whereExpr *newExpr(whereExprType type, long intVal);

whereExpr *newExpr(whereExprType type, float fVal);

whereExpr *newExpr(whereExprType type, char *sVal);

whereExpr *newExpr(whereExprType type);

void freeExpr(whereExpr *expr);

#endif //DBASE_WHEREEXPR_H
