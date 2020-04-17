//
// Created by gautam on 17/04/20.
//

#include "CLI.h"

CLI::CLI(): done(false), line("") {
    // load tables
    // get some stuff ready later
    std::cout << "> ";
    std::cout.flush();
}

std::string CLI::readLine() {
    do {
        std::getline(std::cin, line);
        std::cout << "> ";
        std::cout.flush();
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
