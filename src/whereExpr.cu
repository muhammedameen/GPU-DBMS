//
// Created by gautam on 28/04/20.
//

#include "whereExpr.cuh"

whereExpr *newExpr(whereExprType type, long intVal) {
    auto *expr = new whereExpr;
    expr->type = type;
    expr->iVal = (int)intVal;
    expr->fVal = 0.0f;
    expr->sVal[0] = 0;
    expr->childLeft = -1;
    expr->childRight = -1;
    return expr;
}

whereExpr * newExpr(whereExprType type, float fVal){
    auto *expr = new whereExpr;
    expr->type = type;
    expr->iVal = 0;
    expr->fVal = fVal;
    expr->sVal[0] = 0;
    expr->childLeft = -1;
    expr->childRight = -1;
    return expr;
}

whereExpr * newExpr(whereExprType type, char *sVal){
    auto *expr = new whereExpr;
    expr->type = type;
    expr->iVal = 0;
    expr->fVal = 0.0f;
    // expr->sVal = new char[strlen(sVal) + 1];
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
    expr->sVal[0] = 0;
    expr->childLeft = -1;
    expr->childRight = -1;
    return expr;
}

void freeExpr(whereExpr *expr){
    free(expr);
}

void exprToVec(hsql::Expr *expr, std::vector<whereExpr> &vector, const std::vector<std::string>& colNames) {
    switch (expr->type) {
        case hsql::kExprLiteralFloat:
            vector.push_back(*newExpr(CONSTANT_FLT, expr->fval));
            break;
        case hsql::kExprLiteralString:
            vector.push_back(*newExpr(CONSTANT_STR, expr->name));
            break;
        case hsql::kExprLiteralInt:
            vector.push_back(*newExpr(CONSTANT_INT, expr->ival));
            break;
        case hsql::kExprStar:
            printf("Why is there a `*` here?");
            break;
        case hsql::kExprPlaceholder:
            printf("What is this?");
            break;
        case hsql::kExprColumnRef:{
            int i;
            for (i = 0; i < colNames.size(); i++) {
                if (colNames[i] == expr->name) break;
            }
            vector.push_back(*newExpr(COL_NAME, (long)i));
            break;
        }
        case hsql::kExprFunctionRef:
            printf("What is this 2 Electric Boogaloo");
            break;
        case hsql::kExprOperator: {
            whereExpr *temp = newExpr(getOpType(expr->opType, expr->opChar));
            vector.push_back(*temp);
            int curr = (int)vector.size() - 1;
            vector[curr].childLeft = vector.size();
            exprToVec(expr->expr, vector, colNames);
            if (expr->expr2 != nullptr) {
                vector[curr].childRight = vector.size();
                exprToVec(expr->expr2, vector, colNames);
            }
            break;
        }
        case hsql::kExprSelect:
            printf("Not yet implemented");
            break;
    }
}

whereExprType getOpType(hsql::Expr::OperatorType type, char opChar) {
    // TODO: Change Error to correct Constants
    switch (type) {
        case hsql::Expr::NONE:
            return CONSTANT_ERR;
        case hsql::Expr::BETWEEN:
            return CONSTANT_ERR;
        case hsql::Expr::CASE:
            return CONSTANT_ERR;
        case hsql::Expr::SIMPLE_OP:
            switch (opChar) {
                case '+':
                    return OPERATOR_PL;
                case '-':
                    return OPERATOR_MI;
                case '*':
                    return OPERATOR_MU;
                case '/':
                    return OPERATOR_DI;
                case '%':
                    return OPERATOR_MO;
                case '=':
                    return OPERATOR_EQ;
                case '<':
                    return OPERATOR_LT;
                case '>':
                    return OPERATOR_GT;
                default:
                    return CONSTANT_ERR;
            }
        case hsql::Expr::NOT_EQUALS:
            return OPERATOR_NE;
        case hsql::Expr::LESS_EQ:
            return OPERATOR_LE;
        case hsql::Expr::GREATER_EQ:
            return OPERATOR_GE;
        case hsql::Expr::LIKE:
            return CONSTANT_ERR;
        case hsql::Expr::NOT_LIKE:
            return CONSTANT_ERR;
        case hsql::Expr::AND:
            return OPERATOR_AND;
        case hsql::Expr::OR:
            return OPERATOR_OR;
        case hsql::Expr::IN:
            return CONSTANT_ERR;
        case hsql::Expr::NOT:
            return OPERATOR_NOT;
        case hsql::Expr::UMINUS:
            return OPERATOR_UMI;
        case hsql::Expr::ISNULL:
            return CONSTANT_ERR;
        case hsql::Expr::EXISTS:
            return CONSTANT_ERR;
    }
    return CONSTANT_ERR;
}
