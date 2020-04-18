//
// Created by gautam on 18/04/20.
//

#ifndef DBASE_TOKENIZER_H
#define DBASE_TOKENIZER_H

#include <string>
#include "utils.h"

class tokenizer {
private:
    std::string query;
public:
    explicit tokenizer(std::string &s);

    bool operator >> (std::string &s);
};


#endif //DBASE_TOKENIZER_H
