//
// Created by gautam on 17/04/20.
//

#ifndef DBASE_CLI_H
#define DBASE_CLI_H

#include <string>
#include <iostream>
#include "utils.h"

class CLI {
private:
    std::string line;
    bool done;

    bool testLine();
public:
    CLI();

    std::string readLine();
};


#endif //DBASE_CLI_H
