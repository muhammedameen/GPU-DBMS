//
// Created by gautam on 02/05/20.
//

#ifndef DBASE_COLTYPE_H
#define DBASE_COLTYPE_H


#include <string>
#include <vector>
#include <fstream>
#include <sstream>
#include <map>
#include "utils.h"
#include "../../../../../../../../usr/include/c++/9/bits/basic_string.h"
#include "../../../../../../../../usr/include/c++/8/vector"
#include "../../../../../../../../usr/include/c++/9/vector"
#include "../../../../../../../../usr/include/c++/8/map"
#include "../../../../../../../../usr/include/c++/9/map"

class ColType{
public:
    DATATYPE type;
    int size;
    basic_string<char> str;
    ColType();
    explicit ColType(basic_string<char> typeString);
};

ColType getColType(basic_string<char> &colName);

ColType getColType(int col);


#endif //DBASE_COLTYPE_H
