//
// Created by gautam on 18/04/20.
//

#ifndef DBASE_SQL_DROP_H
#define DBASE_SQL_DROP_H

#include <string.h>
#include "utils.h"
#include "tokenizer.h"
#include <stdio.h>

class sql_drop {
public:
    static void execute(std::string &query);
};


#endif //DBASE_SQL_DROP_H