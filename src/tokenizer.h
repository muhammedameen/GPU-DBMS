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
    static const char delims1[];
    static const char delims2[];
    static const int DELIM1_SIZE;
    static const int DELIM2_SIZE;
public:
    explicit tokenizer(std::string &s);

    bool operator >> (std::string &s);

    bool nextToken(std::string &s);

    static void ltrim(std::string &s);

    static bool find(const char *arr, int size, char ch);
};


#endif //DBASE_TOKENIZER_H
