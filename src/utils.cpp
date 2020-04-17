//
// Created by gautam on 17/04/20.
//

#include <fstream>
#include "utils.h"

std::string const utils::DATABASE_FILE_PATH = "../DB/Database";
std::vector<std::string> utils::tables = std::vector<std::string>();

void utils::ltrim(std::string &s)  {
    s.erase(s.begin(), std::find_if(s.begin(), s.end(), [](int ch) {
        return !std::isspace(ch);
    }));
}

void utils::rtrim(std::string &s)  {
    s.erase(std::find_if(s.rbegin(), s.rend(), [](int ch) {
        return !std::isspace(ch);
    }).base(), s.end());
}

void utils::trim(std::string &s) {
    ltrim(s);
    rtrim(s);
}

std::string utils::getFistWord(std::string &query) {
    return query.substr(0, query.find(' '));
}

void utils::toLower(std::string &upper) {
    std::transform(upper.begin(), upper.end(), upper.begin(),
                   [](unsigned char c) { return std::tolower(c); });
}

void utils::invalidQuery(std::string &query) {
    std::cout << "\"" << query << "\"" << "is not a valid query" << std::endl;
}

std::string utils::getMetadataFileName(std::string &tableName) {
    return tableName + ".mdata";
}

std::string utils::getDataFileName(std::string &tableName) {
    return tableName + ".data";
}

bool utils::fileExists(std::string &filename) {
    if (FILE *file = fopen(filename.c_str(), "r")) {
        fclose(file);
        return true;
    } else {
        return false;
    }
}

void utils::loadTables() {
    std::string filename = DATABASE_FILE_PATH;
    std::ifstream fin(filename);
    if (utils::fileExists(filename)) {
        std::string tableName;
        while (fin >> tableName) {
            tables.push_back(tableName);
        }
    }
}

bool utils::tableExists(std::string &tableName) {
    if (tables.empty()) {
        loadTables();
        if(tables.empty()) {
            return false;
        }
    }
    int i;
    for (i = 0; i < tables.size(); ++i) {
        if(tables[i] == tableName) {
            break;
        }
    }
    return i == tables.size();
}

void utils::addTable(std::string &tableName) {
    tables.push_back(tableName);
}

void utils::writeDatabase() {
    std::string filename = DATABASE_FILE_PATH;
    std::ofstream fout(filename);
    for (const auto& tableName : tables) {
        fout << tableName << std::endl;
    }
    fout.close();
}


