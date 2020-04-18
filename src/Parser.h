//
// Created by gautam on 17/04/20.
//

#ifndef DBASE_PARSER_H
#define DBASE_PARSER_H


#include <string>
#include <iostream>
#include "utils.h"
#include "sql_create.h"

class Parser {
private:
    enum QUERY_TYPE {
        CREATE,         // CPU
        ALTER,          // CPU + check using GPU(?)
        DROP,           // CPU
        TRUNCATE,       // CPU
        INSERT,         // GPU (?) if B+ tree, insertion can be done in parallel
        SELECT,         // GPU
        UPDATE,         // GPU
        DELETE,         // GPU
        INVALID         // Invalid query type
    };

    QUERY_TYPE type;
public:
    Parser();

    void parse(std::string query);

    static QUERY_TYPE getQueryType(std::string &query);
};


#endif //DBASE_PARSER_H
