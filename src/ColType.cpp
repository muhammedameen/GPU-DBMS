//
// Created by gautam on 02/05/20.
//

#include "Metadata.h"
#include "ColType.h"
#include "../../../../../../../../usr/include/c++/8/string"
#include "../../../../../../../../usr/include/c++/8/map"
#include "../../../../../../../../usr/include/c++/8/vector"
#include "../../../../../../../../usr/include/c++/9/vector"
#include "../../../../../../../../usr/include/c++/9/map"
#include "../../../../../../../../usr/include/c++/8/fstream"
#include "../../../../../../../../usr/include/c++/9/string"
#include "../../../../../../../../usr/include/c++/8/ios"
#include "../../../../../../../../usr/include/c++/8/sstream"
#include "../../../../../../../../usr/include/stdio.h"
#include "../../../../../../../../usr/include/c++/9/sstream"
#include "../../../../../../../../usr/include/c++/8/iosfwd"
#include "../../../../../../../../usr/include/c++/8/iostream"
#include "../../../../../../../../usr/include/c++/8/ostream"
#include "../../../../../../../../usr/include/c++/9/iostream"
#include "../../../../../../../../usr/include/c++/9/fstream"
#include "../../../../../../../../usr/include/c++/9/iosfwd"


Metadata::ColType::ColType() {
    type = TYPE_INVALID;
    size = 0;
    str = "";
}

Metadata::ColType::ColType(std::string typeString) {
    utils::toLower(typeString);
    str = typeString;
    if (typeString == "int") {
        type = TYPE_INT;
        size = 4;
    } else if (typeString == "float") {
        type = TYPE_FLOAT;
        size = 4;
    } else if (typeString == "boolean") {
        type = TYPE_BOOL;
        size = 1;
    } else if (typeString == "datetime") {
        type = TYPE_DATETIME;
        size = 8;
    } else {
        if (typeString.length() < 10 || typeString[7] != '(' || typeString[typeString.length() - 1] != ')') {
            // :TODO SOME ERROR OCCURRED
            type = TYPE_INVALID;
            size = 0;
        } else {
            std::string wd = typeString.substr(0, 7);
            if(wd == "varchar") {
                type = TYPE_VARCHAR;
                std::stringstream val(typeString.substr(8, typeString.length()));
                val >> size;
                ++size;
            }
        }
    }
}