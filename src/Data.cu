//
// Created by ameen on 30/04/20.
//

#include "Data.cuh"

Data::Data(std::string tableName) {
    this->tableName = tableName;
    this->writeHappened = false;
    mdata = Metadata(tableName);
    chunkSize = ((500 * 1024 * 1024) / (mdata.rowSize));    // read 20 MB
    readCount = 0;
    f.open(utils::getDataFileName(tableName), std::ios::binary);
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
        // printf("inside destructor");
        remove(utils::getDataFileName(tableName).c_str());
        rename(utils::getTempFileName(tableName).c_str(), utils::getDataFileName(tableName).c_str());
    } else
        remove(utils::getTempFileName(tableName).c_str());
}

Data::Data(const std::string& t1, const std::string& t2) {
    this->tableName = t1 + "_" + t2 + ".join";
    this->writeHappened = false;
    // TODO: Change mdata to a new metadata of join of both tables
    this->mdata = Metadata(t1);
    // This should work if the above line is fixed
    this->chunkSize = ((20 * 1024 * 1024) / mdata.rowSize); // read 20MB because we will need 20 + 20 + 20 * 20 total space while joining
    this->readCount = 0;
    this->f = std::ifstream(utils::getDataFileName(this->tableName), std::ios::binary);
    this->o = std::ofstream(utils::getTempFileName(this->tableName), std::ios::binary);
}


