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
                        break;
                    case hsql::kExprLiteralInt:
                        // stmt->values->at(index)->ival
                        memcpy((char *) row + startIndex, &(stmt->values->at(index)->ival), mdata.getColType(currCol).size);
                        break;
                    case hsql::kExprLiteralString:
                        // stmt->values->at(index)->name
                        memcpy((char *) row + startIndex, (stmt->values->at(index)->name), mdata.getColType(currCol).size);
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
        std::ofstream in;
        in.open(utils::getDataFileName(mdata.tableName), std::ios::binary | std::ios::app);
        in.seekp(mdata.rowCount * mdata.rowSize);
        in.write(static_cast<const char *>(row), mdata.rowSize);
        // increment mdata.rowCount
        mdata.rowCount += 1;
        mdata.commit();

    }else {
        fprintf(stderr, "Given string is not a valid SQL query.\n");
        fprintf(stderr, "%s (L%d:%d)\n",
                result->errorMsg(),
                result->errorLine(),
                result->errorColumn());
    }
}
