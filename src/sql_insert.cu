//
// Created by ameen on 01/05/20.
//

#include "sql_insert.cuh"

void sql_insert::execute(std::string &query) {
    hsql::SQLParserResult *result;
    std::vector<std::string> columnNames;
    std::vector<hsql::Expr*> values;
    result = hsql::SQLParser::parseSQLString(query);


    if(result->isValid()){
        const auto *stmt = (const hsql::InsertStatement *) result->getStatement(0);
        Metadata mdata(stmt->tableName);
        void * row = malloc(mdata.rowSize);
        // add columnnames to obj.columnNames
        if(stmt->columns != NULL)
            for(char *col_name : *stmt->columns)
                columnNames.emplace_back(col_name);
        // take each column from metadata
        int startIndex = 0;
        for (std::string currCol : mdata.columns) {
            // check if that column present in stmt->columns
            auto itr = std::find(columnNames.begin(), columnNames.end(), currCol);
            if (itr != columnNames.end()){
                int index = std::distance(columnNames.begin(), itr);
                // if yes, extract value from stmt->expr and insert in array
                switch (stmt->values->at(index)->type) {
                    case hsql::kExprLiteralFloat:
                        // stmt->values->at(index)->fval
                        memcpy((char *) row + startIndex, &(stmt->values->at(index)->fval), mdata.getColType(currCol).size);
                        // printf("%f\n", *(float *) ((char *) row + startIndex));
                        break;
                    case hsql::kExprLiteralInt:
                        // stmt->values->at(index)->ival
                        memcpy((char *) row + startIndex, &(stmt->values->at(index)->ival), mdata.getColType(currCol).size);
                        break;
                    case hsql::kExprLiteralString:
                        // stmt->values->at(index)->name
                    {
                        char *temp = new char[mdata.getColType(currCol).size];
                        strncpy(temp, stmt->values->at(index)->name, mdata.getColType(currCol).size - 1);
                        temp[mdata.getColType(currCol).size - 1] = 0;
                        // memcpy((char *) row + startIndex, (stmt->values->at(index)->name),
                        //        mdata.getColType(currCol).size);
                        memcpy((char *) row + startIndex, temp,
                               mdata.getColType(currCol).size);
                        // printf("%d\n", mdata.getColType(currCol).size);
                    }
                        break;
                    case hsql::kExprStar:
                        break;
                    case hsql::kExprPlaceholder:
                        break;
                    case hsql::kExprColumnRef:
                        break;
                    case hsql::kExprFunctionRef:
                        break;
                    case hsql::kExprOperator:
                        break;
                    case hsql::kExprSelect:
                        break;
                }
            }
            // if not, insert null value to array (111111)
            else{
                memset((char *) row + startIndex, 1, mdata.getColType(currCol).size);
            }
            startIndex += mdata.getColType(currCol).size;
        }
        // write row to data
        // utils::printRow(row, mdata.datatypes);
        std::ofstream in;
        // printf("%d\n", mdata.rowSize);
        in.open(utils::getDataFileName(mdata.tableName), std::ios::binary | std::ios::app);
        in.write((char *)row, mdata.rowSize);
        in.close();
        mdata.rowCount += 1;
        mdata.commit();
        // void * printData = malloc(mdata.rowSize * mdata.rowCount);
        // Data object(mdata.tableName);
        // object.read(printData);
        // utils::printMultiple(printData, mdata.datatypes, mdata.rowSize, (int)mdata.rowCount);

    }else {
        fprintf(stderr, "Given string is not a valid SQL query.\n");
        fprintf(stderr, "%s (L%d:%d)\n",
                result->errorMsg(),
                result->errorLine(),
                result->errorColumn());
    }
}
