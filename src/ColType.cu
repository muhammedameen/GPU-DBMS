//
// Created by gautam on 02/05/20.
//

#include "ColType.cuh"

ColType newColType() {
    ColType c;
    c.type = TYPE_INVALID;
    c.size = 0;
    // c.str = "";
    strcpy(c.str, "");
    return c;
}

ColType newColType(std::string typeString) {
    ColType c;
    // utils::toLower(typeString);
    // c.str = typeString;
    strcpy(c.str, typeString.c_str());
    if (typeString == "int") {
        c.type = TYPE_INT;
        c.size = 4;
    } else if (typeString == "float") {
        c.type = TYPE_FLOAT;
        c.size = 4;
    } else if (typeString == "boolean") {
        c.type = TYPE_BOOL;
        c.size = 1;
    } else if (typeString == "datetime") {
        c.type = TYPE_DATETIME;
        c.size = 8;
    } else {
        if (typeString.length() < 10 || typeString[7] != '(' || typeString[typeString.length() - 1] != ')') {
            // :TODO SOME ERROR OCCURRED
            c.type = TYPE_INVALID;
            c.size = 0;
        } else {
            std::string wd = typeString.substr(0, 7);
            if(wd == "varchar") {
                c.type = TYPE_VARCHAR;
                std::stringstream val(typeString.substr(8, typeString.length()));
                val >> c.size;
                ++c.size;
            }
        }
    }
    return c;
}
