一、简介和CRUD
在MongoDB中，文档是MongoDB中的基本数据单元，类似于关系型数据库中的行。文档是由键值对组成的，可以包含不同类型的值，如字符串、整数、数组和嵌套的文档。
集合是一组MongoDB文档的组合，类似于关系型数据库中的表。集合中的文档可以是各种不同的结构，但通常情况下，集合中的文档都有着相似的结构。
数据库是一组集合的容器，类似于关系型数据库中的数据库。在MongoDB中，一个数据库可以包含多个集合，每个集合可以包含多个文档。
因此，MongoDB中的文档、集合和数据库之间的关系可以概括为：数据库包含集合，集合包含文档。

movie = {"title" : "Star Wars: Episode IV - A New Hope", "director" : "George Lucas", "year" : 1977}

{
        "title" : "Star Wars: Episode IV - A New Hope",
        "director" : "George Lucas",
        "year" : 1977
}

> db.movies.insertOne(movie)

{
        "acknowledged" : true,
        "insertedId" : ObjectId("5721794b349c32b32a012b11")
}

> db.movies.find().pretty()

{
        "_id" : ObjectId("5721794b349c32b32a012b11"),
        "title" : "Star Wars: Episode IV - A New Hope",
        "director" : "George Lucas",
        "year" : 1977
}
//创建

> db.movies.findOne()

{
        "_id" : ObjectId("5721794b349c32b32a012b11"),
        "title" : "Star Wars: Episode IV - A New Hope",
        "director" : "George Lucas",
        "year" : 1977
}
//读取

> db.movies.updateOne({title : "Star Wars: Episode IV - A New Hope"}, {$set : {reviews: []}})

WriteResult({"nMatched": 1, "nUpserted": 0, "nModified": 1})
//更新

> db.movies.deleteOne({title : "Star Wars: Episode IV - A New Hope"})
//删除。这里删除掉了movie里的所有文档？为什么？

二、数据类型
MongoDB支持多种数据类型，其中包括：
String：字符串
Integer：整数
Double：双精度浮点数
Boolean：布尔值
Object：嵌套文档
Array：数组
Binary Data：二进制数据
ObjectId：对象标识符
Date：日期
Timestamp：时间戳
Regular Expression：正则表达式
Null：空值
Symbol：符号
Decimal128：128位的十进制浮点数
Min/Max keys：最小值和最大值键
这些数据类型为MongoDB提供了灵活性和丰富的功能。

三、mongoshell
//有一个可以了解函数具体行为的好方法，就是在不使用小括号的情况下输入函数名。这样会打印出函数的 JavaScript 源代码。如果想知道 update 函数的工作方式或是记不清参数的顺序，就可以执行以下操作。
> db.movies.updateOne
function (filter, update, options) {
    var opts = Object.extend({}, options || {});

    // 检查update语句中的第一个键是否包含$
    var keys = Object.keys(update);
    if (keys.length == 0) {
        throw new Error("the update operation document must contain at
        least one atomic operator");
    }
    ...
