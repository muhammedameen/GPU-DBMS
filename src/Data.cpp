//
// Created by ameen on 30/04/20.
//

#include "Data.h"
Data::Data(std::string tableName) {
    this->tableName = tableName;
    this->writeHappened = false;
    mdata = Metadata(tableName);
    chunkSize = ((500 * 1000000) / (mdata.rowSize * 1024)) * 1024;
    readCount = 0;
    writeHappened = false;
    f.open(utils::getDataFileName(tableName), std::ios::binary);
    f.seekg(0, std::ios::beg);
    o.open(utils::getTempFileName(tableName), std::ios::binary);
}


int Data::readRow(void *data) {
    f.read(static_cast<char *>(data), mdata.rowSize);
    return 0;
}

int Data::writeRow(void *data) {
    o.write(static_cast<const char *>(data), mdata.rowSize);
    return 0;
}

int Data::read (void *data){
    if(readCount + chunkSize < mdata.rowCount){
        f.read(static_cast<char *>(data), chunkSize * mdata.rowSize);
        readCount += chunkSize;
        return chunkSize;
    }
    else if (readCount < mdata.rowCount){
        f.read(static_cast<char *>(data), (mdata.rowCount - readCount) * mdata.rowSize);
        int rowsRead = mdata.rowCount - readCount;
        readCount = mdata.rowSize;
        return rowsRead;
    } else
        return -1;
}

int Data::write(void *data, int numBytes){
    writeHappened = true;
    if(!o.write((char *)data, numBytes))
        return -1;
    else
        return numBytes;
}

Data::~Data() {
//rename the temp file as data file
    if(writeHappened){
        remove(utils::getDataFileName(tableName).c_str());
        rename(utils::getTempFileName(tableName).c_str(), utils::getDataFileName(tableName).c_str());
    }

}


