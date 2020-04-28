//
// Created by ameen on 29/04/20.
//

#ifndef DBASE_DATA_H
#define DBASE_DATA_H

#include <string>
#include <vector>
#include <fstream>
#include <sstream>
#include <map>

#include "utils.h"
#include "Metadata.h"

class Data {
public:
    explicit Data(std::string tableName);
    int read(void *data);
    int write(void *data, int numBytes);
// private:
    string tableName;
    Metadata mdata;
    FILE *filePointer;
    std::ifstream f;
    std::ofstream o;

    // no of rows dealt as a chunk
    int chunkSize;
};

#endif //DBASE_DATA_H
