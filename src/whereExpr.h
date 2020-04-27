//
// Created by gautam on 27/04/20.
//

#ifndef DBASE_WHEREEXPR_H
#define DBASE_WHEREEXPR_H

#include <cstring>
#include <cstdlib>

const int CONSTANT_INT = 0;
const int CONSTANT_FLT = 1;
const int CONSTANT_STR = 2;
const int COL_NAME = 3;

const int OPERATOR_AND = 10;
const int OPERATOR_OR = 11;
const int OPERATOR_NOT = 12;

const int OPERATOR_EQ = 20;
const int OPERATOR_NE = 21;
const int OPERATOR_GE = 22;
const int OPERATOR_LE = 23;
const int OPERATOR_GT = 24;
const int OPERATOR_LT = 25;

const int OPERATOR_PL = 30;
const int OPERATOR_MI = 31;
const int OPERATOR_MU = 32;
const int OPERATOR_DI = 33;
const int OPERATOR_MO = 34;

struct whereExpr {
    int type;
    int iVal;
    float fVal;
    char *sVal;
    int childLeft;
    int childRight;
};

whereExpr * newExpr(int type, int intVal){
    auto *expr = new whereExpr;
    expr->type = type;
    expr->iVal = intVal;
    expr->fVal = 0.0f;
    expr->sVal = nullptr;
    expr->childLeft = -1;
    expr->childRight = -1;
    return expr;
}

whereExpr * newExpr(int type, float fVal){
    auto *expr = new whereExpr;
    expr->type = type;
    expr->iVal = 0;
    expr->fVal = fVal;
    expr->sVal = nullptr;
    expr->childLeft = -1;
    expr->childRight = -1;
    return expr;
}

whereExpr * newExpr(int type, char *sVal){
    auto *expr = new whereExpr;
    expr->type = type;
    expr->iVal = 0;
    expr->fVal = 0.0f;
    expr->sVal = new char[strlen(sVal) + 1];
    stpcpy(expr->sVal, sVal);
    expr->childLeft = -1;
    expr->childRight = -1;
    return expr;
}

void freeExpr(whereExpr *expr){
    if (expr->sVal != nullptr) {
        free(expr->sVal);
    }
    free(expr);
}

#endif //DBASE_WHEREEXPR_H
