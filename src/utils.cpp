//
// Created by gautam on 17/04/20.
//

#include "utils.h"

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
    return query.substr(0, query.find(" "));
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
