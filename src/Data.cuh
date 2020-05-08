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
#include <cstdio>

#include "utils.cuh"
#include "Metadata.cuh"

class Data {
public:

    explicit Data(std::string tableName, bool temp = false);
    Data(const std::string& t1, const std::string& t2);

    int read(void *data);
    int readRow(void *data);
    int writeRow(void *data);
    int write(void *data, int numBytes);
    long readCount;
    ~Data();
    Metadata mdata;
    // no of rows dealt as a chunk
    int chunkSize;
    void restartRead();
    bool switchToRead();
private:
    bool writeHappened;
    bool joinObject;
    std::string tableName;
    std::ifstream f;
    std::ofstream o;
};


#endif //DBASE_DATA_CUH
