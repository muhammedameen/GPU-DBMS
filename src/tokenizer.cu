//
// Created by gautam on 18/04/20.
//

#include "tokenizer.cuh"

const char tokenizer::delims1[] = {' ', '\t'};
const char tokenizer::delims2[] = {',', ';', '(', ')'};
const int tokenizer::DELIM1_SIZE = 2;
const int tokenizer::DELIM2_SIZE = 4;

tokenizer::tokenizer(std::string &s) {
    this->query = s;
    utils::toLower(this->query);
    query = query.substr(0, query.find(';'));
    ltrim(query);
}

bool tokenizer::operator>>(std::string &s) {
    return nextToken(s);
}



bool tokenizer::nextToken(std::string &s) {
    if (query.empty())
        return false;
    s = "";
    int i;
    char ch;
    for (i = 0; i < query.size(); ++i) {
        ch = query[i];
        if (!find(delims1, DELIM1_SIZE, ch)) {      // Not space char
            if (!find(delims2, DELIM2_SIZE, ch)) {      // Not spl char
                s += ch;
            } else if (s.empty()) {         // Spl char and s is empty
                s = ch;
                if (i < query.size() - 1) {
                    query = query.substr(i + 1, query.size());
                    ltrim(query);
                }   else {
                    query = "";
                }
                break;
            } else {        // s is not empty
                query = query.substr(i, query.size());
                ltrim(query);
                break;
            }
        } else {        // Space char
            query = query.substr(i, query.size());
            ltrim(query);
            break;
        }
    }
    return true;
}

void tokenizer::ltrim(std::string &s) {
    int i = 0;
    while (i < s.size()){
        if(!find(delims1, DELIM1_SIZE, s[i])) break;
        ++i;
    }
    if (i == s.size())  s = "";
    else s = s.substr(i, s.size());
}

bool tokenizer::find(const char *arr, int size, char ch) {
    int i;
    for (i = 0; i < size; ++i) {
        if(arr[i] == ch) break;
    }
    return i != size;
}

