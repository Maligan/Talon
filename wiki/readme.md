# Talon
Talon is UI toolkit for responsive interface building. It allow you:

* Use responsible layouts
* Use CSS
* Use XML based template markup languages
* View your game interfaces outside game clients

## The Basics
Talon determines UI as tree of displayable **Nodes**.

### Node
Node - is main building block, you can teat it as `DisplayObject`.
In core node consist from 4 main parts:

1. Has visible *bounds* (simple rectangle)
3. Can contain children nodes
2. Has *dynamic* set of **Attributes**
4. Can contain attached **Style Sheet** and **Resource Dictionary**

Fore example see next message box:

![Message Box example](img/img1.png)

And such note tree it can has:

![Message Box example Node Tree](img/img2.png)

<!-- Тут нужно расписать что на картинке и как это соотносится с пунктами 1-4 -->

Let's look at each item details.

### Node visible bounds
Visible bounds is a trivial property which determine region occupied by Node, it is set in the coordinate space of the parent Node.
100% similarly `starling.display.DisplayObject#bounds`.

### Node children
Node is realization of [Composite Pattern](https://en.wikipedia.org/wiki/Composite_pattern) like a `DisplayObjectContainer`.
There is small but unfamiliar difference.
There are two approach to implementation composite pattern:

<!-- Уточнить по GOF эти названия -->
1. Security - base composite object (aka `DisplayObject`) can be only leaf node in trees, and there is another inherit class (aka `DisplayObjectContainer`) which *can* contain another objects.
2. Transparency - base composite object already has methods for work with children (aka `numChildren`, `getChildAt`, `addChild`, etc.)

Any of this ways has pros and cons.
Native flash or starling display tree use first way, but talon Node implement second way.

### Node Attribute
Attribute is named value. The principal rule:
> Attribute *name* and *value* is always **string** values, no exceptions.

This rule give solid basis for all toolkit, but it is not always easy to work with string, for example if you need work with set then array `["one", "two", "three"]` is more comfortable than string `"one two three"`.
Therefore for most used attributes (like `width`, `x`, `classes` and same another) `Node` has strong typed accessors.

#### Name
Attribute name can be any string value: `id`, `width`, `y`, `alpha`, `bla-bla-bla`, `1#@!:`, etc. as you want. Node has a dynamically collection of attributes witch is lazy initialized by request i.e. function [`Node#getOrCreateAttribute(name:String):Attribute`](http://google.com/) always return non-null attribute object (as difined in its name :-)

#### Value
Attribute value has complex calculation algorithm, look at this diagram:

![Attribute value calculation](img/img3.png)

1. `inited` this is a initial value of attribute. For example `width`, `height` set to *auto*, `visible` to *true*, `backgroundImage` to *none*, etc.
2. `styled` this value witch installed from attached style sheet. For example if there is selector `*: { fontColor: #FF0000 }` in attached to node tree style sheet, and there is no other selectors, all nodes (CSS "\*" mean any node) has attribute `fontColor` value equal to *#FF0000*.
This value is calculated only if attribute marked as [`Attriubte#isStyleable`](http://google.com/).
3. `setted` this value changed directly from code via [`Node#setAttributeValue(name:String, setted:String)`](http://google.com/), strong typed node attribute accessors like `Node#width`, `Node#margin`, etc. or looking ahead while TML parsing in XML tag attribute `<node attribute="value" />`.
4. `origin` this is first one of previous which is non-null `setted`, `styled`, `inited` (NB! in this sequence):<br/>
	- By default origin equals to `setted` value.<br/>
	- If attribute has no `setted` value (it equals to `null`), used `styled` value.<br/>
	- If also `styled` value equals to `null` used `inited` value.<br/>
	- If in this case `inited` value is also `null`, origin will also be `null`.<br/>
5. `inherit` this is `value` (see next item) of such named attribute from parent node. This behavior defined by CSS (you can read [CSS Paragraph 7.2 Inheritance](https://drafts.csswg.org/css-cascade/#inheriting)), Talon borrow this feature.
This value is calculated only if attribute marked as [`Attriubte#isInheritable`](http://google.com/) 
6. `value` this is resulting value it is equals to `origin`, but if attribute is inheritable and `origin` equals to special *inherit* constant, used `inherit` value.

And there is one special `valueCache` property this is not attribute value in the full sense of the term, but this layer added for resolve next problems:

* Resulting value has complex calculation path.
* Resulting value may be mapped (with special syntax) to resource which can link to other resource and etc. produce long chain, unwinding this chain can be hard process.

But node resource may not be a string value, and therefore `valueCache` is only code sugar.

### Node Resources
### Node Style Sheet (CSS)
### Layouts
#### Absolute
#### Flow

## TML (Template Markup Language)
## Browser

## Appendix
### CSS Dialect
