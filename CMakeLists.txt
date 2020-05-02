cmake_minimum_required(VERSION 3.13)

project(dbase CUDA)

set(CMAKE_CUDA_STANDARD 14)

set(CMAKE_CXX_STANDARD 14)
#set(CMAKE_CXX_COMPILER /usr/bin/g++-8)

file(GLOB parser_src_parser_source
        "sql-parser/src/parser/*.h"
        "sql-parser/src/parser/*.cpp"
        )

file(GLOB parser_src_sql_source
        "sql-parser/src/sql/*.h"
        "sql-parser/src/sql/*.cpp"
        )

add_executable(dbase src/main.cu
        src/sql_create.cpp src/sql_create.h
        src/CLI.cpp src/CLI.h
        src/utils.cpp src/utils.h
        src/Parser.cpp src/Parser.h
        src/Metadata.cpp src/Metadata.h
        src/sql_drop.cpp src/sql_drop.h
        src/tokenizer.cpp src/tokenizer.h
        src/sql_truncate.cpp src/sql_truncate.h

        sql-parser/src/sqlhelper.cpp sql-parser/src/sqlhelper.h
        sql-parser/src/SQLParser.cpp sql-parser/src/SQLParser.h
        sql-parser/src/SQLParserResult.cpp sql-parser/src/SQLParserResult.h
        ${parser_src_parser_source}
        ${parser_src_sql_source}

        src/sql_select.cu src/sql_select.cuh
        src/whereExpr.h src/whereExpr.cpp
        src/deviceUtil.cu src/deviceUtil.cuh
        src/Data.cpp src/Data.h
        src/sql_insert.cpp src/sql_insert.h src/cudaOps.cu src/cudaOps.cuh src/ColType.cpp src/ColType.h)

set_target_properties(
        dbase
        PROPERTIES
        CUDA_SEPARABLE_COMPILATION ON
)


#cmake_minimum_required(VERSION 3.13)
#
#project(dbase)
#
#set(CMAKE_CXX_STANDARD 14)
#
#file(GLOB parser_src_parser_source
#        "sql-parser/src/parser/*.h"
#        "sql-parser/src/parser/*.cpp"
#        )
#
#file(GLOB parser_src_sql_source
#        "sql-parser/src/sql/*.h"
#        "sql-parser/src/sql/*.cpp"
#        )
#
#add_executable(dbase src/main.cpp
#        src/sql_create.cpp src/sql_create.h
#        src/CLI.cpp src/CLI.h
#        src/utils.cpp src/utils.h
#        src/Parser.cpp src/Parser.h
#        src/Metadata.cpp src/Metadata.h
#        src/sql_drop.cpp src/sql_drop.h
#        src/tokenizer.cpp src/tokenizer.h
#        src/sql_truncate.cpp src/sql_truncate.h
#        sql-parser/src/sqlhelper.cpp sql-parser/src/sqlhelper.h
#        sql-parser/src/SQLParser.cpp sql-parser/src/SQLParser.h
#        sql-parser/src/SQLParserResult.cpp sql-parser/src/SQLParserResult.h
#        ${parser_src_parser_source}
#        ${parser_src_sql_source}
#        src/sql_select.cpp src/sql_select.h src/whereExpr.h src/whereExpr.cpp src/deviceUtil.cpp src/deviceUtil.h src/Data.cpp src/Data.h src/sql_insert.cpp src/sql_insert.h)
#
