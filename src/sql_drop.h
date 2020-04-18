<<<<<<< HEAD
#include <string>
#include <vector>
#include <fstream>
#include <sstream>
#include <map>
#include "tokeniser.h"
#include "utils.h"


class drop {
public:
    void execute(string query);
};
=======
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
>>>>>>> 026b43acd9942eab75760d18ac0daee053b25e91
