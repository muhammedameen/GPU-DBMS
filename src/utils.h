//
// Created by gautam on 17/04/20.
//

#ifndef DBASE_UTILS_H
#define DBASE_UTILS_H


#include <string>
#include <algorithm>

class utils {
public:
    // trim from start (in place)
    static inline void ltrim(std::string &s);

    // trim from end (in place)
    static inline void rtrim(std::string &s);

    // trim from both ends (in place)
    static inline void trim(std::string &s);
};


#endif //DBASE_UTILS_H
