//
// Created by gautam on 18/04/20.
//

#include "tokenizer.h"

tokenizer::tokenizer(std::string &s) {
    this->query = s;
    utils::toLower(this->query);
    query = query.substr(0, query.find(';'));
}

bool tokenizer::operator>>(std::string &s) {
    if (query.empty())
        return false;
    s = utils::getFistWord(query);
    if (s.empty())
        return false;
    int index = query.find(' ');
    if (index != std::string::npos) {
        query = query.substr(query.find(' '));
        utils::trim(query);
    } else {
        query = "";
    }
    return true;
}
