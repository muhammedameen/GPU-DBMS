//
// Created by gautam on 17/04/20.
//

#include "Metadata.cuh"

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
            ColType temp = newColType(val);
            rowSize += temp.size;
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
        // Read row count
        getline(metadataIn, line);
        iss = std::istringstream(line);
        iss >> rowCount;
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

bool Metadata::append(std::string &colName, ColType &colType, bool isKey) {
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
        fout << rowCount << " ";
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

ColType Metadata::getColType(int col) {
    return datatypes[col];
}

ColType Metadata::getColType(std::string &colName) {
    return datatypes[colMap[colName]];
}

Metadata::Metadata() {
    rowSize = 0;
    rowCount = 0;
    valid = false;
}