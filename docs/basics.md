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

### Types `div`, `txt`, `img`
В основе талона лежат три базовых визуальных элемента,
при помощи которых можно создавать очень сложные и разнообразные интерфесы.
Эти элементы - контейнер, тектовое поле и изображение. У каждого из них есть
смысл использования, в некоторых случаях они могут подменять друг друга, с целью
какой-либо оптимизации.

Каждый из типов поддерживает свои особые аттрибуты.

* `div`
Этот элемент - контейнер, его смысл в том чтобы содержать в себе другие элементы,
осноное свойство которое есть у контейнера - это `layout` оно определяет алгоритм
расположения элементов-потомков внутри контейнера. Это может быть расположение строкой,
столбцом, таблицей и т.п.

* `txt`
Текстовое поле - название говорит само за себя, если вам нужна текстовая подпись,
описание в каком-либо месте используйте его.

* `img`
Данный элемент это семантическое изображение т.е. например иконка, аватарка и пр. В талоне
есть и другой метод вывода изображений на экран, но этот способ подразумевает что изображение
является отдельной логической еденицей, а не просто декорацией.