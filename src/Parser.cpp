//
// Created by gautam on 17/04/20.
//

#include "Parser.h"

Parser::Parser():type(INVALID){

}

void Parser::parse(std::string query) {
    type = getQueryType(query);

}

Parser::QUERY_TYPE Parser::getQueryType(std::string &query) {
    std::string word = utils::getFistWord(query);
    return INVALID;
}
