## Indago - about

First of all, thank you for taking your time to read and review this project!

If you're curious about the name:
Indago *(in-DAH-go)* [is Latin for](http://latin-dictionary.net/definition/23351/indago-indagare-indagavi-indagatus) 
"I am searching out", "I try to find or procure by seeking".

### The task
Basically, this is the task:

*Using the provided data (tickets.json and users.json and organization.json ) write
a simple command line application to search the data and return the results in a human
readable format. Feel free to use libraries or roll your own code as you see fit. Where the data
exists, values from any related entities should be included in the results. The user should be
able to search on any field, full value matching is fine (e.g. “mar” won’t return “mary”). The user
should also be able to search for empty values, e.g. where description is empty.
Search can get pretty complicated pretty easily, we just want to see that you can code a basic
search application.*

### The solution
Having read the task, the first solution that came to my mind was implementing the brute-force search that looks for
data within whole array of records and outputs them as it finds it. I think that is perhaps a good solution for 
100 records or so in each collection, however if we expect to handle larger amounts of data, this approach will cause 
the search to take more and more time to complete. After noticing we would also need to output related data 
(like organization_name and ticket subjects for each found user), I realized I should think more.

In my development practice, when it comes to full-text search, I use Apache Solr. Solr and ElasticSearch are just 
high-level wrappers for Apache Lucene - a search engine that is extremely fast and robust. I decided to read more on
how Lucene works to achieve the speed it is famous for and found out it basically splits texts into n-grams and builds 
a search tree to achieve O(1) search time complexity. Of course, considering to implement Lucene over a week-end would 
be insane. Fortunately, the task states that full-value matching is ok, and that allowed me to implement this project
with a hashmap search tree.
 
Searching for data involves two steps - indexing (which turns un-normalized JSON data into search-tree) and looking up 
the value by field while utilizing the composed search-tree. To make things easier to read, I've put everything related
to indexing within lib/indago/indexing directory. As for the search itself, there are two classes that take care of 
it - Searcher and RelationsPopulator.

To cope with type casts and relations graph I considered creating models for every known collection with a DSL that
would mix features of Sunspot and ActiveRecord. However, that would complicate the solution, so I opted for assumptions
 about types of values and handling relations through a constant.

While writing tests, I wanted them to be as abstract as possible, but I soon realized that would not bring any clarity
to project's objects orchestration, which I believe is one of primary tasks of tests. So I created the data and indexes
in fixtures, which increased project size, but allowed me to operate with real data and indexes provided in the task.

All in all, I understand this is not a simplistic solution one could glance over in 5 minutes, that is why I aimed for
 clean, pragmatic code and proper test coverage.


### Moving forward
Some things I would consider doing if I were to ship this project to production:
1. Provide ability to index collections in parallel by utilizing several cores. Searching for large amounts of
data could be parallelized as well.
1. Create DSL for models (afterall) to ease up providing new type coercions and relations with new collections. Currently
type coercions are handled implicitly (non-array values are turned into strings) and relations are managed by
one big constant `Indago::RELATIONS`. This will get flaky the more collections we have.
1. With current setup it is quite easy to ship this solution as a Ruby gem. 
1. The biggest drawback of this solution is space complexity. If we were to deal with huge amounts of data, it would be 
sane to store the generated indexes across several servers. This refers to not only collection index (e.g. 'users'), but to 
smallest field indexes (e.g. 'name'), since the user at any given time would search for a concrete field (index of 
which is stored in a separate JSON file).
1. Split text field values into n-grams. Group datetime values by hour/day/month. 
Distribute string values by alphanumeric buckets. 
