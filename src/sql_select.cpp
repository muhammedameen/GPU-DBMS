//
// Created by gautam on 25/04/20.
//

#include "sql_select.h"


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
        // Get where

        if (stmt->whereClause != nullptr) {
            auto expr = stmt->whereClause;

        } else {

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
