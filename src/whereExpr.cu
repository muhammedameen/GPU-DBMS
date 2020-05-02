//
// Created by gautam on 28/04/20.
//

#include "whereExpr.cuh"

whereExpr *newExpr(whereExprType type, long intVal) {
    auto *expr = new whereExpr;
    expr->type = type;
    expr->iVal = (int)intVal;
    expr->fVal = 0.0f;
    expr->sVal = nullptr;
    expr->childLeft = -1;
    expr->childRight = -1;
    return expr;
}

whereExpr * newExpr(whereExprType type, float fVal){
    auto *expr = new whereExpr;
    expr->type = type;
    expr->iVal = 0;
    expr->fVal = fVal;
    expr->sVal = nullptr;
    expr->childLeft = -1;
    expr->childRight = -1;
    return expr;
}

whereExpr * newExpr(whereExprType type, char *sVal){
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

whereExpr *newExpr(whereExprType type){
    auto *expr = new whereExpr;
    expr->type = type;
    expr->iVal = 0;
    expr->fVal = 0.0f;
    expr->sVal = nullptr;
    expr->childLeft = -1;
    expr->childRight = -1;
    return expr;
}
void freeExpr(whereExpr *expr){
    if (expr->sVal != nullptr) {
        ::free(expr->sVal);
    }
    free(expr);
}

