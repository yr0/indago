## Indago
**The JSON search engine**

A week-end project, implementation of challenge provided by guys at Zendesk.

You can read more about solution itself in [ABOUT_SOLUTION](ABOUT_SOLUTION.md) 

### Installation
1. Make sure you have ruby 2.4.2 installed along with bundler
1. Within project directory, run `bundle`

### Usage
1. Put JSON files to be searched in **data** directory. You can find sample JSON files in spec/fixtures/data.
1. Run `bin/indago index` to index the files in data directory. The indexes (indices?) will be created in **indexes** 
directory. You will have to run index every time you change the contents of JSON files in data directory. You can
 run indexing for a single collection by running index with a parameter: `bin/indago index -c <collection name>`
1. For now available collections are: **users**, **organizations**, **tickets**. 
1. To perform search, run `bin/indago search -c <collection name> -f <name of field> -v <value>`. Alternatively,
you can run `bin/indago search -c <collection name>` and enter the session of continuous search, which will procure
results for the same fields faster, since all data will be stored in-memory.
1. To view fields available for search for certain collection, run `bin/indago list_fields -c <collection name>`
1. To view help on indago CLI commands, as well as full-name options for them run `bin/indago help`. To view help on 
a single command, run `bin/indago help <name of command>`

### Assumptions about Data
Inferring data schema from data sets provided within the challenge, we assume the engine will produce consistent 
results if yet unseen data adheres to following assumptions: 

1. Data size is more than 100 and less than 100000 entities. For data size less than 100 we could achieve better 
time/space complexity trade-off with brute-force approach (i.e. rake over raw dataset looking for a key-value pair and 
return what you've found).
1. Data adheres to format requirements. Allowed value types (as inferred from examples) are: string, integer, float, 
array. The array cannot be nested and may only contain strings, integers, or floats. 
1. The data is stored in files with *.json extension. The file name without extension specifies how a user would 
reference the entity collection during search. E.g. if *data* directory contains the `users.json` file, after it has
been indexed, you will be able to search users collection with `bin/indago search -c users`.
1. Data is stored as an array of entities in JSON-parseable format.
1. Each item in data has an _id which is unique for that collection
1. Name of collections and entity fields can be used as valid filenames.
