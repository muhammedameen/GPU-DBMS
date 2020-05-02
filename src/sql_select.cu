//
// Created by gautam on 25/04/20.
//

#include "sql_select.cuh"

__global__ void selectKernel(void *data, int rowSize, int *offset, int offsetSize, ColType *types, whereExpr *exprs) {
    void *res;
    int resType = 0;
    eval(data, rowSize, offset, offsetSize, types, exprs, 0, res, resType);
    if (resType == RESTYPE_INT) {
        int *x = (int *) res;
        printf("Value of expression is : %d\n", *x);
    } else {
        printf("Res Type is : %d", resType);
    }
}

void sql_select::execute(std::string &query) {

    hsql::SQLParserResult *result;
    std::vector<std::string> columnNames;
    std::vector<std::string> tableNames;

    result = hsql::SQLParser::parseSQLString(query);
    columnNames = std::vector<std::string>();
    tableNames = std::vector<std::string>();

    if(result->isValid()){
        const auto *stmt = (const hsql::SelectStatement *) result->getStatement(0);
        // hsql::printSelectStatementInfo(stmt, 1);
        // Get column names
        for (hsql::Expr* expr : *stmt->selectList){
            switch (expr->type) {
                case hsql::kExprStar:
                    columnNames.emplace_back("*");
                    break;
                case hsql::kExprColumnRef:
                    columnNames.emplace_back(expr->name);
                    break;
                // case hsql::kExprTableColumnRef:
                // inprint(expr->table, expr->name, numIndent);
                // break;
                case hsql::kExprLiteralFloat:
                    columnNames.push_back(std::to_string(expr->fval));
                    break;
                case hsql::kExprLiteralInt:
                    columnNames.push_back(std::to_string(expr->ival));
                    break;
                case hsql::kExprLiteralString:
                    columnNames.emplace_back(expr->name);
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
                tableNames.emplace_back(table->name);
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
            printf("%s\n", tableNames[0].c_str());
            Data d(tableNames[0]);

            auto expr = stmt->whereClause;
            exprToVec(expr, tree, d.mdata.columns);
            free(expr);

            int rowSize = d.mdata.rowSize;
            void *data = malloc(d.chunkSize);
            void *data_d;
            int numCols = d.mdata.columns.size();
            ColType *type_d;
            cudaMalloc(&type_d, sizeof(ColType) * numCols);
            cudaMemcpy(type_d, &d.mdata.datatypes[0], sizeof(ColType) * numCols, cudaMemcpyHostToDevice);
            whereExpr *where_d;
            cudaMalloc(&where_d, sizeof(whereExpr) * tree.size());
            cudaMemcpy(where_d, &tree[0], sizeof(whereExpr) * tree.size(), cudaMemcpyHostToDevice);
            int *offsets = (int *) malloc(sizeof(int) * (numCols + 1));
            offsets[0] = d.mdata.datatypes[0].size;
            for (int i = 1; i <= numCols; i++) {
                offsets[i] = offsets[i - 1] + d.mdata.datatypes[i].size;
            }
            int *offsets_d;
            cudaMalloc(&offsets_d, sizeof(int) * (numCols + 1));
            cudaMemcpy(offsets_d, offsets, sizeof(int) * (numCols + 1), cudaMemcpyHostToDevice);
            int numRows = d.read(data);

            while (numRows > 0) {
                printf("Inside\n");
                fflush(stdout);
                cudaMalloc(&data_d, rowSize * numRows);
                cudaMemcpy(data_d, data, rowSize * numRows, cudaMemcpyHostToDevice);
                selectKernel<<<1, 512>>>(data_d, rowSize, offsets_d, numCols, type_d, where_d);
                cudaDeviceSynchronize();
                cudaError_t err = cudaGetLastError();
                printf("Error at %d: %s\n", __LINE__, cudaGetErrorString(err));
                numRows = d.read(data);
            }

            // FOR DEBUGGING
            // for (auto leaf : tree) {
            //     printf("TYPE: %d, ival: %d, fval: %f, sval: %s, left: %d, right: %d\n", leaf.type, leaf.iVal, leaf.fVal,
            //            leaf.sVal, leaf.childLeft, leaf.childRight);
            // }

            // TEST EVAL
            // ColType type[] = {newColType("int"), newColType("varchar(7)"), newColType("int"), newColType("float")};
            // int start[] = {0, 4, 12, 16, 20};
            // int end[] = {4, 12, 16, 20};
            // void *row = malloc(20 * sizeof(char));
            // int r1 = 5;
            // char r2[8] = "ab";
            // int r3 = 10;
            // float r4 = 0.05f;
            // memcpy((char *) row + start[0], &r1, end[0] - start[0]);
            // memcpy((char *) row + start[1], r2, end[1] - start[1]);
            // memcpy((char *) row + start[2], &r3, end[2] - start[2]);
            // memcpy((char *) row + start[3], &r4, end[3] - start[3]);
            //
            // Data *a = new Data("persons");
            // // a.write(row, 20);
            // free(row);
            // row = malloc(20 * sizeof(char));
            // a->mdata.rowCount = 1;
            // a->read(row);
            //
            //
            // // Revserse memcpy
            // memcpy(&r1, (char *) row + start[0], end[0] - start[0]);
            // memcpy(r2, (char *) row + start[1], end[1] - start[1]);
            // memcpy(&r3, (char *) row + start[2], end[2] - start[2]);
            // memcpy(&r4, (char *) row + start[3], end[3] - start[3]);
            // printf("R1: %d, R2: %s, R3:%d, R4:%f\n", r1, r2, r3, r4);
            //
            // void *row_d;
            // cudaMalloc(&row_d, 20);
            // cudaMemcpy(row_d, row, 20, cudaMemcpyHostToDevice);
            //
            // int *offset_d;
            // cudaMalloc(&offset_d, 5 * sizeof(int));
            // cudaMemcpy(offset_d, start, 5 * sizeof(int), cudaMemcpyHostToDevice);
            //
            // char *colNames_d;
            // int *colPos_d;
            // cudaMalloc(&colNames_d, sizeof(char *) * 4 * 100);
            // cudaMalloc(&colPos_d, sizeof(int) * 4);
            // int colPos[] = {0, 3, 6, 9};
            // for (int i = 0; i < 4; i++) {
            //     cudaMemcpy(colNames_d + 3 * i, colNames[i], sizeof(char) * 3, cudaMemcpyHostToDevice);
            // }
            // cudaMemcpy(colPos_d, colPos, sizeof(int) * 4, cudaMemcpyHostToDevice);
            //
            // ColType *types_d;
            // cudaMalloc(&types_d, sizeof(ColType) * 4);
            // cudaMemcpy(types_d, type, sizeof(ColType) * 4, cudaMemcpyHostToDevice);
            //
            // whereExpr *whereClause;
            // cudaMalloc(&whereClause, sizeof(whereExpr) * tree.size());
            // cudaMemcpy(whereClause, &tree[0], sizeof(whereExpr) * tree.size(), cudaMemcpyHostToDevice);

            // selectKernel<<<1, 1>>>(row, 20, offset_d, 4, colNames_d, colPos_d, types_d, whereClause);
            // cudaDeviceSynchronize();
            // cudaError_t err = cudaGetLastError();
            // printf("Error at %d: %s\n", __LINE__, cudaGetErrorString(err));
            // eval(row, 20, start, 4, colNames, type, &tree[0], 0, res, resType);
            // if (resType == RESTYPE_INT) {
            //     int *x = (int *) res;
            //     printf("Value of expression is : %d\n", *x);
            // }
            // END TEST EVAL
        } else {
            // RETURN ALL ROWS
        }
    } else {
        fprintf(stderr, "Given string is not a valid SQL query.\n");
        fprintf(stderr, "%s (L%d:%d)\n",
                result->errorMsg(),
                result->errorLine(),
                result->errorColumn());
    }
    free(result);
}