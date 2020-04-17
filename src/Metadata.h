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
        ColType();
        explicit ColType(std::string typeString);
    };

    ColType getColType(std::string &colName);

    ColType getColType(int col);

    void append(std::string &colName, ColType &colType, bool isKey = false);

    bool appendKey(std::string &keyName);

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