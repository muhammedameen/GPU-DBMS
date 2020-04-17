#include "CLI.h"
#include "Parser.h"

int main() {
    CLI interface;
    Parser parser;
    std::string query = interface.readLine();
    while (!query.empty()) {
        parser.parse(query);
        query = interface.readLine();
    }
    return 0;
}