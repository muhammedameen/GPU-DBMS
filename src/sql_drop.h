//
// Created by gautam on 18/04/20.
//

#ifndef DBASE_SQL_DROP_H
#define DBASE_SQL_DROP_H

#include <string>
#include "utils.h"

class sql_drop {
public:
    static void execute(std::string &query);
};


#endif //DBASE_SQL_DROP_H
