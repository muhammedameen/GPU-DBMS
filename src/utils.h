//
// Created by gautam on 17/04/20.
//

#ifndef DBASE_UTILS_H
#define DBASE_UTILS_H


#include <string>
#include <algorithm>
#include <iostream>
#include <vector>

class utils {
public:
    static const std::string DATABASE_FILE_PATH;

    static const std::string DATABASE_DIR;

    static std::vector<std::string> tables;

    // trim from start (in place)
    static void ltrim(std::string &s);

    // trim from end (in place)
    static void rtrim(std::string &s);

    // trim from both ends (in place)
    static void trim(std::string &s);

    static std::string getFistWord(std::string &basicString);

    static void toLower(std::string &upper);

    static void invalidQuery(std::string &query);

    static void invalidQuery(std::string &query, std::string &errString);

    static std::string getMetadataFileName(std::string &tableName);

    static std::string getDataFileName(std::string &tableName);

    static std::string getTempFileName(std::string &tableName);

    static bool fileExists(std::string &filename);

    static void loadTables();

    static bool tableExists(std::string &tableName);

    static void addTable(std::string &tableName);

    static void dropTable(std::string &tableName);

    static void writeDatabase();
};


#endif //DBASE_UTILS_H
