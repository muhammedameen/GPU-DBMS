//
// Created by gautam on 17/04/20.
//

#ifndef DBASE_METADATA_CUH
#define DBASE_METADATA_CUH

#include <string>
#include <vector>
#include <fstream>
#include <sstream>
#include <map>

#include "utils.cuh"
#include "ColType.cuh"

class Metadata {
public:
    explicit Metadata(std::string tableName);

    Metadata();

    std::string getColName(int col);

    std::string operator[] (int col);

    bool append(std::string &colName, ColType &colType, bool isKey = false);

    bool appendKey(std::string &keyName);

    void invalidate();

    void commit();

    std::string metadataFileName;
    std::string dataFileName;
    std::string tableName;
    int rowSize;
    long rowCount;

    ColType getColType(std::string &colName);

    ColType getColType(int col);

    std::vector<std::string> columns;
    std::vector<ColType> datatypes;
    std::map<std::string, int> colMap;
    std::vector<std::string> keyCols;
    std::map<std::string, int> keyMap;
private:
    bool valid;
};


#endif //DBASE_METADATA_CUH
