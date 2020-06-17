//
// Created by gautam on 17/04/20.
//

#include <fstream>
#include "utils.cuh"

std::string const utils::DATABASE_DIR = "../DB";
std::string const utils::DATABASE_FILE_PATH = utils::DATABASE_DIR + "/Database";
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

void utils::invalidQuery(std::string query) {
    std::cout << "\"" << query << "\"" << "is not a valid query" << std::endl;
}

void utils::invalidQuery(std::string &query, std::string &errString) {
    std::cout << "\"" << query << "\"" << "is not a valid query" << std::endl;
    std::cout << "Error: " << errString << std::endl;
}

std::string utils::getMetadataFileName(std::string &tableName) {
    return DATABASE_DIR + "/" + tableName + ".mdata";
}

std::string utils::getDataFileName(std::string &tableName) {
    return DATABASE_DIR + "/" + tableName + ".data";
}

std::string utils::getTempFileName(std::string &tableName) {
    return DATABASE_DIR + "/" + tableName + ".temp";
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
    return i != tables.size();
}

void utils::addTable(std::string &tableName) {
    tables.push_back(tableName);
}

void utils::dropTable(std::string &tableName){
	int i;
	for (i = 0; i < tables.size(); ++i) {
        if(tables[i] == tableName) {
            break;
        }
    }
    tables.erase(tables.begin() + i);
}

void utils::writeDatabase() {
    std::string filename = DATABASE_FILE_PATH;
    std::ofstream fout(filename);
    for (const auto& tableName : tables) {
        fout << tableName << std::endl;
    }
    fout.close();
}

void utils::printRow(void *row, std::vector<ColType> &cols) {
    int start = 0;
    for (const auto &c : cols) {
        // printf("Start: %d\n", start);
        switch (c.type) {
            case TYPE_INT: {
                int temp = *((int *) ((char *) row + start));
                printf("%d", temp);
                start += sizeof(int);
                break;
            }
            case TYPE_FLOAT: {
                float temp = *((float *) ((char *) row + start));
                printf("%f", temp);
                start += sizeof(float);
                break;
            }
            case TYPE_BOOL:
                break;
            case TYPE_VARCHAR: {
                char *temp = (char *) row + start;
                printf("%s", temp);
                start += c.size;
                break;
            }
            case TYPE_DATETIME:
                break;
            case TYPE_INVALID:
                break;
        }
        if (&c != &cols[cols.size() - 1]) {
            printf(", ");
        }
    }
    printf("\n");
}

void utils::printMultiple(void *data, std::vector<ColType> &cols, int rowSize, int numRows) {
    int start = 0;
    printf("\n");
    for (int i = 0; i < numRows; i++, start += rowSize) {
        printRow((char *)data + start, cols);
    }
}




