//
// Created by gautam on 17/04/20.
//

#include "CLI.h"

CLI::CLI(): done(false), line("") {
    // load tables
    // get some stuff ready later
}

std::string CLI::readLine() {
    std::string query;
    do {
        std::cout << "> ";
        std::cout.flush();
        std::getline(std::cin, line);
    } while (testLine());
    if(line == "exit" || line == "quit") {
        return "";
    }
    return line;
}

bool CLI::testLine() {
    utils::trim(line);
    return line.empty();
}
