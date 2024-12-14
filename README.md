# TranscludeData
A Scribunto lua module for making data easily transcludable on wikis

## Setup
To set up TranscludeData, go to the [latest release](https://github.com/Jono997/TranscludeData/releases) and copy the contents of `TranscludeData.lua` into `Module:TranscludeData` of your current wiki. Then create the `Module:TranscludeData/data` and `Module:TranscludeData/views` submodules. See below sections for how to create those.

### Creating `Module:TranscludeData/data`
`Module:TranscludeData/data`, hereafter referred to as the data submodule, is where all transcludable data is stored along with the verification schema (not implemented). The module should return a table with the following keys:
- `"data"`: The location of the data itself. Can contain any number/depth of subtables and keys can be either strings or numbers, but the keys should not contain full stops or be a string representation of an integer (eg. "2").
- `"schema"`: The data verification schema. This is optional and currently not implemented.

### Creating `Module:TranscludeData/views`
`Module:TranscludeData/views`, hereafter referred to as the views submodule, is where all the "views" (functions that take data from the data submodule and output it in some form as wikitext) are stored. The module should return a table, where each key is the ID of a view (string) and the contents and their respective entries a table containing the following keys:
#### `"params"`
A table comprised of 0 or more subtables denoting the parameters this view can be passed. Each subtable should contain the following keys:
- `1`: The key of the parameter. This can be either a number or an string.
- `2`: The type of the parameter, as a string. The value should either be `"string"` or `"number"`.
#### `"func"`
A function that gets executed when the view is called, which returns the wikitext output and takes in the following arguments
- `utils`: The standard library of functions views can use to get and format data
- `frame`: The frame that was used when invoking TranscludeData to render this view.
- `parent_fram`: The parent of `frame`, identical to `frame:getParent()`.
- `params`: A table of all the parameters passed to the view.

## Usage
TranscludeData has two ways to be used on pages. The main way data can be used is via views, which are called like so: `{{#invoke:TranslcudeData|View|<view name>|<whatever parameters the view takes>}}`  
Another method is directly grabbing data, like so: `{{#invoke:TranscludeData|Get|<data path>|<view to spoof, currently has no use, but will in later versions>}}`

## Planned features
- Data verification system
- View structure verification system (will likely be using the data verification system under the hood)
- Data override system (way to make data in the data module appear differently depending on which view is accessing it)
- Way to add more functions to the views function library without editing TranscludeData directly