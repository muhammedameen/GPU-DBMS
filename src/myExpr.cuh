//
// Created by gautam on 27/04/20.
//

#ifndef DBASE_MYEXPR_CUH
#define DBASE_MYEXPR_CUH

#include <cstring>
#include <cstdlib>
#include "../sql-parser/src/sql/Expr.h"

enum myExprType{
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
    myExprType type;
    int iVal;
    float fVal;
    char sVal[10];
    int childLeft;
    int childRight;
} myExpr;

myExpr *newExpr(myExprType type, long intVal);

myExpr *newExpr(myExprType type, float fVal);

myExpr *newExpr(myExprType type, char *sVal);

myExpr *newExpr(myExprType type);

void freeExpr(myExpr *expr);

void exprToVec(hsql::Expr *pExpr, std::vector<myExpr> &vector, const std::vector<std::string>& colNames);

myExprType getOpType(hsql::Expr::OperatorType type, char opChar);


#endif //DBASE_MYEXPR_CUH
