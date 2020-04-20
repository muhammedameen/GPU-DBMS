#include "CLI.h"
#include "Parser.h"
#include "../sql-parser/src/SQLParserResult.h"
#include "../sql-parser/src/SQLParser.h"
#include "../sql-parser/src/sqlhelper.h"


int main() {
    CLI interface;
    utils::loadTables();
    Parser parser;
    std::string query = interface.readLine();
    while (!query.empty()) {
        // parser.parse(query);
        hsql::SQLParserResult* result = hsql::SQLParser::parseSQLString(query);
        if (result->isValid()) {
            printf("Parsed successfully!\n");
            printf("Number of statements: %lu\n", result->size());

            for (uint i = 0; i < result->size(); ++i) {
                // Print a statement summary.
                hsql::printStatementInfo(result->getStatement(i));
            }
        } else {
            fprintf(stderr, "Given string is not a valid SQL query.\n");
            fprintf(stderr, "%s (L%d:%d)\n",
                    result->errorMsg(),
                    result->errorLine(),
                    result->errorColumn());
        }
        query = interface.readLine();
    }
    utils::writeDatabase();
    return 0;
}