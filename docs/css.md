## Talon CSS Dialect
All attribute names use *smallCamelCaseNotation*, without dashed like W3C/Flex dialects.
Next attributes used within Talon:

### Attribute list

Name                | Initial                       | Range
------              | -------                       | -------------------
id                  | `null`                        | Identifier
type                | `null`                        | Identifier
class               | `null`                        | Array of identifier
state               | `null`                        | Array of identifier
width               | `none`                        | Gauge
height              | `none`                        | Gauge
minWidth            | `none`                        | Gauge
minHeight           | `none`                        | Gauge
maxWidth            | `none`                        | Gauge
maxHeight           | `none`                        | Gauge
margin              | `none`                        | Gauge Quad
marginTop           | `none`                        | Gauge
marginRight         | `none`                        | Gauge
marginBottom        | `none`                        | Gauge
marginLeft          | `none`                        | Gauge
padding             | `none`                        | Gauge Quad
paddingTop          | `none`                        | Gauge
paddingRight        | `none`                        | Gauge
paddingBottom       | `none`                        | Gauge
paddingLeft         | `none`                        | Gauge
anchor              | `none`                        | Gauge Quad
anchorTop           | `none`                        | Gauge
anchorRight         | `none`                        | Gauge
anchorBottom        | `none`                        | Gauge
anchorLeft          | `none`                        | Gauge
backgroundImage     | `none`                        | Resource or `none`
backgroundTint      | `white`                       | Color
background9Scale    | `none`                        | Gauge Quad
backgroundColor     | `none`                        | Color
backgroundAlpha     | `1`                           | Segment `[0; 1]`
backgroundBlendMode | `auto`                        | `auto`, `none`, `normal`, `add`, `multiply`, `screen`, `erase`, `mask`, `below`
backgroundFillMode  | `scale`                       | `scale`, `clip`, `repeat`
fontColor           | `inherit` (`white`)           | Color
fontName            | `inherit` (`Times New Roman`) | Font Name (bitmap, embeded or system)
fontSize            | `inherit` (`12px`)            | Gauge
fontSharpness       | `inherit` (`0`)               | Segment `[0; 1]`
alpha               | `1`                           | Segment `[0; 1]`
clipping            | `false`                       | `true`, `false`
blendMode           | `auto`                        | `add`, `auto`, `below`, `erase`, `mask`, `multiply`, `none`, `normal`, `screen` (from [starling.display.BlendMode](https://github.com/Gamua/Starling-Framework/blob/master/starling%2Fsrc%2Fstarling%2Fdisplay%2FBlendMode.as))
cursor              | `auto`                        | `arrow`, `auto`, `button`, `hand`, `ibeam` (from [flash.ui.MouseCursor](http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/flash/ui/MouseCursor.html))
layout              | `flow`                        | `flow`, `abs`, `grid`
visible             | `true`                        | `true`, `false`
filter              | `none`                        | `none` or Filter
position            | `0px`                         | Gauge Pair
x                   | `0px`                         | Gauge
y                   | `0px`                         | Gauge
pivot               | `0px`                         | Gauge Pair
pivotX              | `0px`                         | Gauge
pivotY              | `0px`                         | Gauge
origin              | `0px`                         | Gauge Pair
originX             | `0px`                         | Gauge
originY             | `0px`                         | Gauge
orientation         | `horizontal`                  | `horizontal`, `vertical`
halign              | `left`                        | `left`, `center`, `right`
valign              | `top`                         | `top`, `center`, `bottom`
ihalign             | `left`                        | `left`, `center`, `right`
ivalign             | `top`                         | `top`, `center`, `bottom`
gap                 | `0px`                         | Gauge
interline           | `0px`                         | Gauge
wrap                | `false`                       | `true`, `false`
break               | `auto`                        | `auto`, `before`, `after`, `both`
autoScale           | `false`                       | `true`, `false`
src                 | `none`                        | Resource or `none`
text                | `null`                        | Text

### Types
Gauge - measurment value in format `NUMBER[UNIT]`, example: `10px, 50%, 3*`,

- Unit is optional field, by default it is equals to `px`
- Next units is implemented: 
	- none ?
	- px
	- dp
	- mm
	- em
	- %
	- *

<button>Button</button>

### Background
Отображение заднего плана выполняется по следующим правилам:
	* Задний план не является явным участником дерева отображение (на него не возможно получить прямую ссылку) и является "внутренним" обектом для *любого* узла
	* Задний план распростостраняется только на область ограниченную width/height узла, не на contentWidth/contentHeight, за пределами этого прямоугольника задник не отображается
	*
