//
// Created by gautam on 25/04/20.
//

#include "sql_select.h"
#include "deviceUtil.h"
#include "Metadata.h"

void sql_select::execute(std::string &query) {
    sql_select obj(query);
    if(obj.result->isValid()){
        // printf("Parsed successfully!\n");
        // printf("Number of statements: %lu\n", obj.result->size());
        // for (uint i = 0; i < obj.result->size(); ++i) {
        //     // Print a statement summary.
        //     hsql::printStatementInfo(obj.result->getStatement(i));
        // }
        const auto *stmt = (const hsql::SelectStatement *) obj.result->getStatement(0);
        hsql::printSelectStatementInfo(stmt, 1);
        // Get column names
        for (hsql::Expr* expr : *stmt->selectList){
            switch (expr->type) {
                case hsql::kExprStar:
                    obj.columnNames.emplace_back("*");
                    // inprint("*", numIndent);
                    break;
                case hsql::kExprColumnRef:
                    obj.columnNames.emplace_back(expr->name);
                    // inprint(expr->name, numIndent);
                    break;
                    // case kExprTableColumnRef: inprint(expr->table, expr->name, numIndent); break;
                case hsql::kExprLiteralFloat:
                    obj.columnNames.push_back(std::to_string(expr->fval));
                    // inprint(expr->fval, numIndent);
                    break;
                case hsql::kExprLiteralInt:
                    obj.columnNames.push_back(std::to_string(expr->ival));
                    // inprint(expr->ival, numIndent);
                    break;
                case hsql::kExprLiteralString:
                    obj.columnNames.emplace_back(expr->name);
                    // inprint(expr->name, numIndent);
                    break;
                // TODO: kExprFunctionRef (Distinct ?), kExprOperator (col1 + col2 ?)
                // case hsql::kExprFunctionRef:
                //     inprint(expr->name, numIndent);
                //     inprint(expr->expr->name, numIndent + 1);
                //     break;
                // case hsql::kExprOperator:
                //     printOperatorExpression(expr, numIndent);
                //     break;
                default:
                    fprintf(stderr, "Unrecognized expression type %d\n", expr->type);
                    return;
            }
        }
        // Get tables reference
        auto table = stmt->fromTable;
        switch (table->type) {
            case hsql::kTableName:
                // inprint(table->name, numIndent);
                obj.tableNames.emplace_back(table->name);
                break;
            // case hsql::kTableSelect:
            //     // printSelectStatementInfo(table->select, numIndent);
            //     break;
            // case hsql::kTableJoin:
            //     // inprint("Join Table", numIndent);
            //     // inprint("Left", numIndent + 1);
            //     // printTableRefInfo(table->join->left, numIndent + 2);
            //     // inprint("Right", numIndent + 1);
            //     // printTableRefInfo(table->join->right, numIndent + 2);
            //     // inprint("Join Condition", numIndent + 1);
            //     // printExpression(table->join->condition, numIndent + 2);
            //     break;
            // case hsql::kTableCrossProduct:
            //     // for (TableRef* tbl : *table->list) printTableRefInfo(tbl, numIndent);
            //     break;
            default:
                printf("Will be handled later\n");
                return;
        }
        if (stmt->whereClause != nullptr) {
            // Get where
            std::vector<whereExpr> tree;
            auto expr = stmt->whereClause;
            exprToVec(expr, tree);

            // FOR DEBUGGING
            for (auto leaf : tree) {
                printf("TYPE: %d, ival: %ld, fval: %f, sval: %s, left: %d, right: %d\n", leaf.type, leaf.iVal, leaf.fVal,
                       leaf.sVal, leaf.childLeft, leaf.childRight);
            }

            // GET ROWS SATISFYING WHERE
            // Data data(obj.tableNames[0], obj.columnNames);
            int rowSise = 0;
            int numCols = obj.columnNames.size();
            // rowSize = data.getRowSize();
            // int *offsets = data.getOffset();
            void *dataPtr = malloc(rowSise);
            // int numRows = data.getDataChunked(dataPtr);

            // TEST EVAL
            // char colNames[][20] = {"r1", "r2", "r3", "r4"};
            char *colNames[] = {"r1", "r2", "r3", "r4"};
            Metadata::ColType type[] = {Metadata::ColType("int"), Metadata::ColType("varchar(7)"), Metadata::ColType("int"), Metadata::ColType("float")};
            int start[] = {0, 4, 12, 16, 20};
            int end[] = {4, 12, 16, 20};
            void *row = malloc(20 * sizeof(char));
            int r1 = 5;
            char r2[] = "abcdefg";
            int r3 = 10;
            float r4 = 0.05f;
            memcpy((char *) row + start[0], &r1, end[0] - start[0]);
            memcpy((char *) row + start[1], r2, end[1] - start[1]);
            memcpy((char *) row + start[2], &r3, end[2] - start[2]);
            memcpy((char *) row + start[3], &r4, end[3] - start[3]);

            Data a("persons");
//            a.write(row, 20);
            free(row);
            row = malloc(20 * sizeof(char));
            a.read(row);
            // Revserse memcpy
            memcpy(&r1, (char *) row + start[0], end[0] - start[0]);
            memcpy(r2, (char *) row + start[1], end[1] - start[1]);
            memcpy(&r3, (char *) row + start[2], end[2] - start[2]);
            memcpy(&r4, (char *) row + start[3], end[3] - start[3]);
            printf("R1: %d, R2: %s, R3:%d, R4:%f\n", r1, r2, r3, r4);
            void *res;
            int resType = 0;
            eval(row, 20, start, 4, colNames, type, &tree[0], 0, res, resType);
            if (resType == RESTYPE_INT) {
                int *x = (int *) res;
                printf("Value of expression is : %d\n", *x);
            }
            // END TEST EVAL
        } else {
            // RETURN ALL ROWS
        }
    } else {
        fprintf(stderr, "Given string is not a valid SQL query.\n");
        fprintf(stderr, "%s (L%d:%d)\n",
                obj.result->errorMsg(),
                obj.result->errorLine(),
                obj.result->errorColumn());
    }
}

sql_select::sql_select(std::string &query) {
    result = hsql::SQLParser::parseSQLString(query);
    columnNames = std::vector<std::string>();
    tableNames = std::vector<std::string>();
}

void sql_select::exprToVec(hsql::Expr *expr, std::vector<whereExpr> &vector) {
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
        case hsql::kExprColumnRef:
            vector.push_back(*newExpr(COL_NAME, expr->name));
            break;
        case hsql::kExprFunctionRef:
            printf("What is this 2 Electric Boogaloo");
            break;
        case hsql::kExprOperator: {
            whereExpr *temp = newExpr(getOpType(expr->opType, expr->opChar));
            vector.push_back(*temp);
            int curr = vector.size() - 1;
            vector[curr].childLeft = vector.size();
            exprToVec(expr->expr, vector);
            if (expr->expr2 != nullptr) {
                vector[curr].childRight = vector.size();
                exprToVec(expr->expr2, vector);
            }
            break;
        }
        case hsql::kExprSelect:
            printf("Not yet implemented");
            break;
    }
}

whereExprType sql_select::getOpType(hsql::Expr::OperatorType type, char opChar) {
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
