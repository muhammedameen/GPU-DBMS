//
// Created by gautam on 18/04/20.
//

#ifndef DBASE_SQL_TRUNCATE_CUH
#define DBASE_SQL_TRUNCATE_CUH

#include <cstring>
#include "utils.cuh"
#include "tokenizer.cuh"
#include <cstdio>
#include <fstream>

class sql_truncate {
public:
    static void execute(std::string &query);
};


#endif //DBASE_SQL_DROP_CUH