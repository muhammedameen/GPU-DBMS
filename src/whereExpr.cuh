//
// Created by gautam on 27/04/20.
//

#ifndef DBASE_WHEREEXPR_CUH
#define DBASE_WHEREEXPR_CUH

#include <cstring>
#include <cstdlib>
#include "../sql-parser/src/sql/Expr.h"

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
    char sVal[10];
    int childLeft;
    int childRight;
} whereExpr;

whereExpr *newExpr(whereExprType type, long intVal);

whereExpr *newExpr(whereExprType type, float fVal);

whereExpr *newExpr(whereExprType type, char *sVal);

whereExpr *newExpr(whereExprType type);

void freeExpr(whereExpr *expr);

void exprToVec(hsql::Expr *pExpr, std::vector<whereExpr> &vector, const std::vector<std::string>& colNames);

whereExprType getOpType(hsql::Expr::OperatorType type, char opChar);


#endif //DBASE_WHEREEXPR_CUH
