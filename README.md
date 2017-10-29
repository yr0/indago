## Indago
*(in-DAH-go)*

**The JSON search engine**

A week-end project, implementation of challenge provided by guys at Zendesk.
You can read more about solution itself in [ABOUT_SOLUTION](ABOUT_SOLUTION.md) 

### Installation
1. Make sure you have ruby 2.4.2 installed along with bundler gem
1. Within project directory, run `bundle` to install gem dependencies
1. To see test results, run `rspec`. To check code style, run `rubocop`

### Usage
1. Put JSON files to be searched in **data** directory. You can find sample JSON files in spec/fixtures/data.
1. Run `bin/indago index` to index the files in data directory. The indexes (indices?) will be created in **indexes** 
directory. To index a single collection, you can run `bin/indago index -c <collection name>`. You will have to perform 
index every time you change the contents of JSON files in data directory.
1. For now, available collections are: **users**, **organizations**, **tickets**. 
1. To perform search, run `bin/indago search -c <collection name> -f <name of field> -v <value>`. Alternatively,
you can run `bin/indago search -c <collection name>` to start a session of continuous search.
1. To view fields available for search for certain collection, run `bin/indago list_fields -c <collection name>`
1. To view help on indago CLI commands, as well as full-name options for them, run `bin/indago help`. To view help on 
a single command, run `bin/indago help <name of command>`

### Assumptions about Data
Inferring data schema from the sets provided within the coding challenge, we assume the engine will produce consistent 
results if yet unseen data adheres to following assumptions: 

1. Data size is more than 100 and less than 100000 entities. For data size less than 100 we could achieve better 
time/space complexity trade-off with brute-force approach (i.e. rake over raw dataset looking for a key-value pair and 
return what you've found).
1. Data adheres to format requirements. Allowed value types (as inferred from examples) are: string, integer, 
array. The array cannot be nested and may only contain strings or integers. 
1. The data is stored in files with *.json extension. The file name without extension specifies how a user would 
reference the entity collection during search. E.g. if *data* directory contains the `users.json` file, after it has
been indexed, you will be able to search users collection with `bin/indago search -c users`.
1. Data is stored as an array of entities in JSON-parseable format.
1. Each item in data has an _id which is unique for that collection. Every collection has the same primary field name,
which you can change within `Indago::PRIMARY_FIELD_NAME` constant.
1. Names of entity fields can be used as part of valid filenames (e.g. name.json).
1. Collection size in bytes is not bigger than value provided within `Indago::MAX_INDEXING_ARRAY_SIZE` to prevent 
potential memory overflows.

### Features :)
1. Extensibility. Indago couldn't care less if you add another collection for indexing and searching. Just make sure it
adheres to data assumptions. If the collection needs to be associated with other collections, just update the 
`Indago::RELATIONS` hash and make sure new entities have a `name` field for basic data 
(or update the `Indago::CUSTOM_BASIC_DATA_FIELDS`). Since indexing and searching are separated and thoroughly tested,
 you can inject your logic at any step of these processes with not much of a fuss.
1. Simplicity. There are basically 5 classes in play for a full search cycle. All project parts adhere to Ruby style 
standards, SOLID principles. Obscure parts of code are documented. The tests are expressive and provide perspective on
how one would use the objects in a separated context.
1. Test Coverage. I aimed for the fullest and most practical testing suite possible. I also tried to adjust the 
test suite in a way that allows future developers to re-use most of boilerplate and shared functionality in their tests.
1. Performance. This solution should handle significant data increase. It is expected that with data increase 
the indexing should take linearly more time, the search time should remain more or less constant.
1. Robustness. The solution handles most possible errors, including some edge cases. If something wrong happens that 
wasn't accounted for, you will see a full Ruby error output. You can configure the logging level by changing the value 
of `Indago::LOGGER_LEVEL`.
