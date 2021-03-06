// Steps to be followed while creating a new table
// 1. Parse the query - Create TableName
// 2. Check if TableName already exists in Database, if not add it to Database.
// 3. Create TableName.data and TableName.mdata inside DB
// 4. Poppulate TableName.mdata using specifics in the query
// Sample Query - "CREATE TABLE Persons (
//				    ID int NOT NULL,
//				    LastName varchar(255) NOT NULL,
//				    FirstName varchar(255),
//				    Age int,
//				    PRIMARY KEY (ID)
//				  );"

#include "sql_create.cuh"

#define invalidQuery(query) {utils::invalidQuery(query); return;}

using namespace std;

namespace create {

    bool isSpecialChar(char ch) {
        return (ch == '(' || ch == ')' || ch == ',' || ch == ';');
    }

    void execute(string query) {
        for (int i = 0; i < query.size(); ++i) {
            if (isSpecialChar(query[i])) {
                query.insert(i, " ");
                query.insert(i + 2, " ");
                i += 2;
            }
        }
        string word;
        stringstream iss(query);
        iss >> word;
        utils::toLower(word);
        if (word != "create")
            invalidQuery(query);
        iss >> word;
        utils::toLower(word);
        if (word != "table")
            invalidQuery(query);
        //table name
        iss >> word;
        utils::toLower(word);
        if (utils::tableExists(word))
            invalidQuery(query);
        Metadata m(word);

        iss >> word;
        if (word != "(")
            invalidQuery(query);
        string col_name, col_type, key;
        string varchar_size;
        while (true) {
            iss >> col_name;
            utils::toLower(col_name);

            if (col_name == "primary") {
                iss >> word;
                utils::toLower(word);
                if (word != "key")
                    invalidQuery(query);
                iss >> word;
                if (word != "(")
                    invalidQuery(query);
                iss >> key;
                //make this column primary key
                m.appendKey(key);
                iss >> word;
                if (word != ")")
                    invalidQuery(query);
            } else {
                iss >> col_type;
                if (col_type == "varchar") {
                    iss >> word;
                    if (word != "(")
                        invalidQuery(query);
                    iss >> varchar_size;
                    iss >> word;
                    if (word != ")")
                        invalidQuery(query);
                    col_type += "(" + varchar_size + ")";
                }
                ColType c = newColType(col_type);
                m.append(col_name, c, false);
            }

            iss >> word;
            if (word != "," && word != ")")
                invalidQuery(query);

            if (word == ")")
                break;
        }
        m.commit();
        utils::addTable(m.tableName);
    }
}