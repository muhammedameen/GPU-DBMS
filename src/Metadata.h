//
// Created by gautam on 17/04/20.
//

#ifndef DBASE_METADATA_H
#define DBASE_METADATA_H

#include <string>
#include <vector>
#include <fstream>
#include <sstream>

#include "utils.h"

class Metadata {
public:
    Metadata(std::string tableName);

    std::string getColName(int col);

    std::string operator[] (int col);

    enum DATATYPE {
        TYPE_INT,
        TYPE_FLOAT,
        TYPE_BOOL,
        TYPE_VARCHAR,
        TYPE_DATETIME,
        TYPE_INVALID
    };

    class ColType{
    public:
        DATATYPE type;
        int size;
        std::string str;
        ColType(){
            type = TYPE_INVALID;
            size = 0;
            str = ""
        }
        explicit ColType(std::string typeString) {
            utils::toLower(typeString);
            str = typeString;
            if (typeString == "int") {
                type = TYPE_INT;
                size = 32;
            } else if (typeString == "float") {
                type = TYPE_FLOAT;
                size = 32;
            } else if (typeString == "boolean") {
                type = TYPE_BOOL;
                size = 1;
            } else if (typeString == "datetime") {
                type = TYPE_DATETIME;
                size = 64;
            } else {
                if (typeString.length() < 10 || typeString[7] != '(' || typeString[typeString.length() - 1] != ')') {
                    // :TODO SOME ERROR OCCURRED
                    type = TYPE_INVALID;
                    size = 0;
                } else {
                    std::string wd = typeString.substr(0, 7);
                    if(wd == "varchar") {
                        type = TYPE_VARCHAR;
                        std::stringstream val(typeString.substr(8, typeString.length()));
                        val >> size;
                    }
                }
            }
        }

    };

    ColType getColType(std::string &colName);

    ColType getColType(int col);

    void append(std::string &colName, ColType &colType, bool isKey = false);

    ~Metadata();

    std::string metadataFileName;
    std::string dataFileName;
    std::string tableName;
private:

    std::vector<std::string> columns;
    std::vector<ColType> datatypes;
    std::vector<std::string> keyCols;
};


#endif //DBASE_METADATA_H
