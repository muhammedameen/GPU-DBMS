//
// Created by gautam on 17/04/20.
//

#ifndef DBASE_UTILS_H
#define DBASE_UTILS_H


#include <string>
#include <algorithm>
#include <iostream>

class utils {
public:
    // trim from start (in place)
    static inline void ltrim(std::string &s);

    // trim from end (in place)
    static inline void rtrim(std::string &s);

    // trim from both ends (in place)
    static inline void trim(std::string &s);

    static std::string getFistWord(std::string &basicString);

    static void toLower(std::string &upper);

    static void invalidQuery(std::string &query);

    static std::string getMetadataFileName(std::string &tableName);

    static std::string getDataFileName(std::string &tableName);

    static bool fileExists(std::string &filename);
};


#endif //DBASE_UTILS_H
