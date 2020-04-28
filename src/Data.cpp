//
// Created by ameen on 29/04/20.
//
#include "data.h"

Data::Data(std::string tableName) {
    this->tableName = tableName;
    mdata = Metadata(tableName);
    chunkSize = ((500 * 1000000)/(mdata.rowSize*1024)) * 1024;
    f.open(utils::getDataFileName(tableName), std::ios::binary);
    f.seekg(0, std::ios::beg)
    o.open(utils::getDataFileName(tableName), std::ios::binary);
    return;
}

int Data::read (void *data){
    int oldPos, currentPos;
    oldPos = f.tellg();
    //open the data file and read into the pointer
    if(!f.read(data, chunkSize*mdata.rowSize)){
        // we reached the end of file
        int bytesLeft = f.gcount();
        f.seekg(oldPos);
        f.read(data, bytesLeft);
        return bytesLeft;
    }
    currentPos = f.tellg();
    return currentPos - oldPos;
}

int Data::write(void *data, int numBytes){
    data = (char *)malloc(chunkSize*mdata.rowSize);

}
