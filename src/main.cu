#include "CLI.cuh"
#include "Parser.cuh"
#include "deviceUtil.cuh"

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