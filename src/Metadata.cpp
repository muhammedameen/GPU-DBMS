//
// Created by gautam on 17/04/20.
//

#include "Metadata.h"

Metadata::Metadata(std::string tableName) {
    this->tableName = tableName;
    metadataFileName = utils::getMetadataFileName(tableName);
    dataFileName = utils::getDataFileName(tableName);
    columns = std::vector<std::string>();
    datatypes = std::vector<ColType>();
    keyCols = std::vector<std::string>();
    if (utils::fileExists(metadataFileName)) {
        std::ifstream metadataIn(metadataFileName);
        std::string line, val;
        // Read column names
        getline(metadataIn, line);
        std::istringstream iss(line);
        while (iss >> val) {
            columns.push_back(val);
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
        while (iss >> val) {
            keyCols.push_back(val);
        }
        metadataIn.close();
    } else {
        std::ofstream fout(metadataFileName);
        fout = std::ofstream(dataFileName);
    }
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
    int i;
    for (i = 0; i < columns.size(); ++i) {
        if (columns[i] == colName) {
            break;
        }
    }
    return datatypes[i];
}

void Metadata::append(std::string &colName, Metadata::ColType &colType, bool isKey) {
    columns.push_back(colName);
    datatypes.push_back(colType);
    if (isKey) {
        keyCols.push_back(colName);
    }
}

Metadata::~Metadata() {
    metadataFileName = utils::getMetadataFileName(tableName);
    std::ofstream fout(metadataFileName);
    for (const auto& colName : columns) {
        fout << colName << " ";
    }
    fout << std::endl;
    for (const ColType &colType : datatypes) {
        fout << colType.str << " ";
    }
    fout << std::endl;
    for (const std::string &keyCol : keyCols) {
        fout << keyCol.str << " ";
    }
    fout << std::endl;
    fout.close();
}




