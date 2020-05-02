//
// Created by ameen on 30/04/20.
//

#ifndef DBASE_DATA_CUH
#define DBASE_DATA_CUH


#include <string>
#include <vector>
#include <fstream>
#include <sstream>
#include <map>
#include <stdio.h>

#include "utils.cuh"
#include "Metadata.cuh"

class Data {
public:
    explicit Data(std::string tableName);
    int read(void *data);
    int readRow(void *data);
    int writeRow(void *data);
    int write(void *data, int numBytes);
    long readCount;
    ~Data();
    Metadata mdata;
private:
    bool writeHappened;
    std::string tableName;
    std::ifstream f;
    std::ofstream o;
    // no of rows dealt as a chunk
    int chunkSize;
};


#endif //DBASE_DATA_CUH
