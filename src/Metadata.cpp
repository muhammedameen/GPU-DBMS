//
// Created by gautam on 17/04/20.
//

#include "Metadata.h"

Metadata::Metadata(std::string tableName) {
    this->tableName = tableName;
    this->valid = true;
    keyMap = std::map<std::string, int>();
    metadataFileName = utils::getMetadataFileName(tableName);
    dataFileName = utils::getDataFileName(tableName);
    columns = std::vector<std::string>();
    datatypes = std::vector<ColType>();
    keyCols = std::vector<std::string>();
    colMap = std::map<std::string, int>();
    rowSize = 0;
    rowCount = 0;
    if (utils::fileExists(metadataFileName)) {
        std::ifstream metadataIn(metadataFileName);
        std::string line, val;
        // Read column names
        getline(metadataIn, line);
        std::istringstream iss(line);
        int index = 0;
        while (iss >> val) {
            columns.push_back(val);
            colMap[val] = index++;
        }
        // Read column datatypes
        getline(metadataIn, line);
        iss = std::istringstream(line);
        while (iss >> val) {
            ColType temp(val);
            datatypes.push_back(temp);
        }
        // Read key columns
        getline(metadataIn, line);
        iss = std::istringstream(line);
        index = 0;
        while (iss >> val) {
            keyCols.push_back(val);
            keyMap[val] = index++;
        }
        metadataIn.close();
    }
    // No need to create now, wait till destructor is reached. Might be invalidated later.
    // else {
    //     std::ofstream fout(metadataFileName);
    //     fout.close();
    //     fout = std::ofstream(dataFileName);
    //     fout.close();
    // }
}

std::string Metadata::getColName(int col) {
    return columns[col];
}

std::string Metadata::operator[](int col) {
    return columns[col];
}

Metadata::ColType Metadata::getColType(int col) {
    return datatypes[col];
}

Metadata::ColType Metadata::getColType(std::string &colName) {
    return datatypes[colMap[colName]];
}

bool Metadata::append(std::string &colName, Metadata::ColType &colType, bool isKey) {
    if (colMap.find(colName) == colMap.end()) {
        colMap[colName] = columns.size();
        columns.push_back(colName);
        datatypes.push_back(colType);
        rowSize += colType.size;
        if (isKey && keyMap.find(colName) == keyMap.end()) {
            keyMap[colName] = keyCols.size();
            keyCols.push_back(colName);
        }
        return true;
    }
    return false;
}

void Metadata::commit() {
    if (valid) {
        metadataFileName = utils::getMetadataFileName(tableName);
        std::ofstream fout(metadataFileName);
        for (const auto &colName : columns) {
            fout << colName << " ";
        }
        fout << std::endl;
        for (const ColType &colType : datatypes) {
            fout << colType.str << " ";
        }
        fout << std::endl;
        for (const std::string &keyCol : keyCols) {
            fout << keyCol << " ";
        }
        fout << std::endl;
        fout.close();
        fout = std::ofstream(dataFileName);
        fout.close();
    }
}

bool Metadata::appendKey(std::string &keyName) {
    if(columns.empty() || colMap.find(keyName) == colMap.end())  // Col with that name doesn't exist
        return false;
    if (keyMap.find(keyName) == keyMap.end()) {  // Col exists but not designated as key
        keyMap[keyName] = keyCols.size();
        keyCols.push_back(keyName);
    }
    return true;
}

void Metadata::invalidate() {
    this->valid = false;
    columns.clear();
    colMap.clear();
    datatypes.clear();
    keyCols.clear();
    keyMap.clear();
}

Metadata::Metadata() {
    valid = false;
}


Metadata::ColType::ColType() {
    type = TYPE_INVALID;
    size = 0;
    str = "";
}

Metadata::ColType::ColType(std::string typeString) {
    utils::toLower(typeString);
    str = typeString;
    if (typeString == "int") {
        type = TYPE_INT;
        size = 4;
    } else if (typeString == "float") {
        type = TYPE_FLOAT;
        size = 4;
    } else if (typeString == "boolean") {
        type = TYPE_BOOL;
        size = 1;
    } else if (typeString == "datetime") {
        type = TYPE_DATETIME;
        size = 8;
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
