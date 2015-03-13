# TML - Язык разметки интерфеса
## Альтернативы
 - XInclude
 - XSLT
 - TAL (Genshi)

## Содержание/Структура
Терминальный узел - узел который не связан с каким-либо шаблоном, и разбирается как есть.
В отличии от не терминальных узлов которые раскрываются в поддерево.
Любой не терминал подразумевает под собой то что это не просто узел, а поддерево.
Для того чтобы зарегистрировать новый не терминальный узел используется тег <define>.
Поддеревья можно описывать новые, а брать за основу старые и изменять их используя <rewrite>.
Для того чтобы использовать не терминальный узел можно:
 - Воспользоваться тегом <tree> с заданным атрибутом ref
 - Зарегистрировать за не терминалом собственное имя тега т.е. <define type="button" />

Tag-Keywords:
 - tree - insert exists tree pattern (consists from set of <rewrite>)
	+ ref - mandatory tree id
 - rewrite - replace any subtree on exists tree pattern (consist from 1 child (root) if mode==replace, any count of child if mode==content, empty if mode==attributes)
	+ ref - mandatory subtree root id
	+ mode - attributes | replace | content
 - define - create tree pattern (consists from only 1 child (root))
	+ id - mandatory
	+ type - linkage tag name
 - library - use as container for <define>, <style>
 - style - use to add css in library (without create addition .css file)

### Приоритет выполнения rewrite
 - replace
 - content
 - attributes
