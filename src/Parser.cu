//
// Created by gautam on 17/04/20.
//

#include "Parser.cuh"

Parser::Parser():type(INVALID){
}

void Parser::parse(std::string query) {
    utils::toLower(query);
    type = getQueryType(query);

    if (type == INVALID) {
        utils::invalidQuery(query);
    } else if (type == CREATE) {
        create::execute(query);
    } else if (type == ALTER) {
        // AlterClass.execute(query);
    } else if (type == DROP) {
        sql_drop::execute(query);
    } else if (type == TRUNCATE) {
        sql_truncate::execute(query);
    } else if (type == INSERT) {
         sql_insert::execute(query);
    } else if (type == SELECT) {
        sql_select::execute(query);
    } else if (type == UPDATE) {
        // UpdateClass.execute(query);
    } else if (type == DELETE) {
        // DeleteClass.execute(query);
    }
}

Parser::QUERY_TYPE Parser::getQueryType(std::string &query) {
    std::string word = utils::getFistWord(query);
    if(word == "create") {
        return CREATE;
    } else if (word == "alter") {
        return ALTER;
    } else if (word == "insert") {
        return INSERT;
    } else if (word == "drop") {
        return DROP;
    } else if (word == "truncate") {
        return TRUNCATE;
    } else if (word == "select") {
        return SELECT;
    } else if (word == "update") {
        return UPDATE;
    } else if (word == "delete") {
        return DELETE;
    }
    return INVALID;
}
