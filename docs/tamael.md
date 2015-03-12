# TML - Язык разметки интерфеса
## Альтернативы
 - XInclude
 - XSLT
 - TAL (Genshi)

## Содержание/Структура
Tag-Keywords:
 - define - create tree pattern (consists from only 1 child (root) OR (if definded base attribute) set of <rewrite>)
	+ id - mandatory
	+ base - base definition id
	+ type - linkage tag name
 - definition - insert exists tree pattern (consists from set of <rewrite>)
	+ ref - mandatory definition id
 - rewrite - replace any subtree on exists tree pattern (consist from 1 child (root) if mode==replace, any count of child if mode==content, empty if mode==attributes)
	+ ref - mandatory subtree root id
	+ mode - attributes | replace | content

### Приоритет выполненеия rewrite
 - replace
 - content
 - attributes
