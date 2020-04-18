<<<<<<< HEAD
#include "sql_drop.h"

#define invalidQuery(query) {utils::invalidQuery(query); return;}

void drop::execute(string query){

	string word;
	if(word != "delete")
		invalidQuery(query);

	if(!utils::tableExists(word))
		invalidQuery(query);

	//drop table from Database
	utils::dropTable(word);
	//delete files
	string data_file;
	string mdata_file;
	data_file = utils::getDataFileName(word);
	mdata_file = utils::getMetadataFileName(word);
	if( remove( data_file ) != 0 )
    	cout<<"Error removing the Data File"<<endl;
    if( remove( mdata_file ) != 0 )
    	cout<<"Error removing the Metadata File"<<endl;
    return;
}
=======
//
// Created by gautam on 18/04/20.
//

#include "sql_drop.h"

void sql_drop::execute(std::string &query) {
    utils::toLower(query);

}
>>>>>>> 026b43acd9942eab75760d18ac0daee053b25e91
