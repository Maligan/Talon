## Talon Basics
The main and only Talon building block is *Node*, which:

* Has visible *bounds* — rectangle
* Has *attributes* — string key-value pairs
* Can contain *children* nodes
* Can contain attached *style sheet* and *resource dictionary*

Combine nodes into trees allow create complex UI.

### Attribute
Attribute is **string key-value pair** where key — unique identifier within node, value — string which calculated in 4 steps:

1. The basis is default attribute value
2. If attribute has value from style sheet it overwrite value
3. If attribute has explicit value via code or markup it overwrite value
4. If attribute must respect values of other attributes:
	* If attribute must inherit value from parent then parent node attribute used  
	For example `fontColor` if setuped into `inherit` then concrete value fetched from parent
	* If attribute must merge values from other attrubes then value calculated  
	For example `padding` = `paddingTop paddingRight paddingBottom paddingLeft`

There is only **one mandatory attribute** — `type`, it define node behaviour, used attributes, ect. Talon from the box define and implement three types: `div`, `txt`, `img` they will be described in detail below.

### Styles & Resources

If you are familiar with W3C CSS — there is nothing new to you, else do not worry — style sheet is simple set of pairs
> `selector` → `list of key-value pairs`  

Styles used in attribute value calculation process (which described above) in *step 2*.

Таблица ресурсов — пары `строка`-`объект`. Ресурсы (текстуры, строки переводов, звуки, коды цветов и т.п.) используются вне Талона, благодаря тому что атрибуты могут своим значение ссылатся на ресурсы.

Стили и ресурсы добавленые в узел доступны из всех его потомков, если в потомке есть свои таблицы и возникают конфликты имёт — приоритет за стилями/ресурсами за младшей из таблиц.
