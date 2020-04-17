#include "CLI.h"
#include "Parser.h"

int main() {
    CLI interface;
    utils::loadTables();
    Parser parser;
    std::string query = interface.readLine();
    while (!query.empty()) {
        parser.parse(query);
        query = interface.readLine();
    }
    utils::writeDatabase();
    return 0;
}