//
// Created by gautam on 02/05/20.
//

#ifndef DBASE_COLTYPE_CUH
#define DBASE_COLTYPE_CUH

#include <string>
#include <sstream>

enum DATATYPE {
    TYPE_INT,
    TYPE_FLOAT,
    TYPE_BOOL,
    TYPE_VARCHAR,
    TYPE_DATETIME,
    TYPE_INVALID
};

typedef struct {
    DATATYPE type;
    int size;
    char str[10];
    // ColType(std::string typeString);
} ColType;

ColType newColType();

ColType newColType(std::string typeString);

#endif //DBASE_COLTYPE_CUH
