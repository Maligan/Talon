## Talon CSS Dialect
All attribute names use *smallCamelCaseNotation*, without dashed like W3C/Flex dialects.  

#### Common
* <a href="#id">id</a>
* <a href="#type">type</a>
* <a href="#class">class</a>
* <a href="#state">state</a>
#### Background
* <a href="#fill">fill</a>
* <a href="#fillalpha">fillAlpha</a>
* <a href="#fillblendmode">fillBlendMode</a>
* <a href="#filltint">fillTint</a>
* <a href="#fillmode">fillMode (fillModeX, fillModeY)</a>
* <a href="#fillscale">fillScale (fillScaleX, fillScaleY)</a>
* <a href="#fillstretchgrid">fillStretchGrid (fillStretchGridTop, fillStretchGridRight, fillStretchGridBottom, fillStretchGridLeft)</a>
* <a href="#fillalign">fillAlign (fillAlignX, fillAlignY)</a>
#### Font
* <a href="#fontcolor">fontColor</a>
* <a href="#fontname">fontName</a>
* <a href="#fontsize">fontSize</a>
* <a href="#fontautoscale">fontAutoScale</a>
* <a href="#fonteffect">fontEffect</a>
#### Mouse
* <a href="#touchmode">touchMode</a>
* <a href="#touchevents">touchEvents</a>
* <a href="#cursor">cursor</a>
#### Display
* <a href="#blendmode">blendMode</a>
* <a href="#visible">visible</a>
* <a href="#filter">filter</a>
* <a href="#alpha">alpha</a>
* <a href="#transform">transform</a>
* <a href="#pivot">pivot (pivotX, pivotY)</a>
#### Layout
* <a href="#widthheight">width/height</a>
* <a href="#minwidthmaxwidthminheightmaxheight">minWidth/maxWidth/minHeight/maxHeight</a>
* <a href="#margin">margin (marginTop, marginRight, marginBottom, marginLeft)</a>
* <a href="#padding">padding (paddingTop, paddingRight, paddingBottom, paddingLeft)</a>
#### Type `img` related
* <a href="#source">source</a>
* <a href="#tint">tint</a>
#### Type `txt` related
* <a href="#text">text</a>
#### Type `div` related
* <a href="#layout">layout</a>
* <a href="#anchor">anchor (top, right, bottom, left)</a>
* <a href="#orientation">orientation</a>
* <a href="#align">align (alignX, alignY)</a>
* <a href="#gap">gap</a>
* <a href="#interline">interline</a>
* <a href="#wrap">wrap</a>
* <a href="#alignSelf">alignSelf (alignSelfX, valignSelfY)</a>
* <a href="#break">break (breakBefore, breakAfter)</a>

* * *

#### id
Node identifier, mapped with DisplayObject `name` property.

#### type
Define node behaviour and used for style applying.

* `div`
* `txt`
* `img`
* Any user types.

#### class
Define set of *css classes*: Used for style applying.

#### state
Define set of *css pseudo classes*: Used for style applying.  

#### fill
> See <a href="fill.md">background</a> article.

Setup node backgound.  

* **`none`**
* <a href="#color">`COLOR`</a>
* <a href="#resource">`RESOURCE`</a>

#### fillAlpha
> See <a href="fill.md">background</a> article.

Setup background alpha.

#### fillBlendMode
> See <a href="fill.md">background</a> article.

Setup background blendMode.

* Any supported <a href="http://doc.starling-framework.org/current/starling/display/BlendMode.html">BlendMode</a>

#### fillTint
> See <a href="fill.md">background</a> article.

Setup backgound tint color.

* **`none`**
* <a href="#color">`COLOR`</a>

#### fillMode
> See <a href="fill.md">background</a> article.  
> Use <a href="#pair">pair</a> of `fillModeX` and `fillModeY`.

Setup background image fill algorithm.  

* `none`
* **`stretch`**
* `repeat`

#### fillScale
> See <a href="fill.md">background</a> article.  
> Use <a href="#pair">pair</a> of `fillScaleX` and `fillScaleY`.

Setup backgound image scale, default **`1`**.

#### fillStretchGrid
> See <a href="fill.md">background</a> article.  
> Use <a href="#quad">quad</a> of `fillStretchGridTop`, `fillStretchGridRight`, `fillStretchGridBottom` and `fillStretchGridLeft`.

Setup 9-scale rectange for `fillMode = stretch`, default **`none`**.

* <a href="#gauge">`GAUGE`</a>

#### fillAlign
> See <a href="fill.md">background</a> article.  
> Use <a href="#pair">pair</a> of `fillAlignX` and `fillAlignY`.

Setup backgound image align for `fillMode = none | repeat`, default **`left top`**

* <a href="#align">ALIGN</a>

#### fontColor
Setup font color, default **`#FFFFFF`**.

* **`inherit`**
* <a href="#color">`COLOR`</a>

#### fontName
Setup font, default **`mini`**.

* **`inherit`**
* Any system, embed or bitmap font name.

#### fontSize
Setup font size, default **`12px`**.

* **`inherit`**
* <a href="#gauge">`GAUGE`</a>

#### fontAutoScale
> Scale down works only if text bounds is static.

Scale down font size if text doesn't fit into bounds, default **`false`**.

* **`inherit`**
* `false`
* `true`

#### fontEffect
> This effects internally works via signed distance field, and require sdf-, msdf-fonts usage.

Allow set up font effects like shadow, outline and stroke, default **`none`**.

* **`inherit`**
* `none`
* `shadow(x = 2, y = x, blur = 0.2, color = #000000, alpha = 0.5)`
* `stroke(width = 0.25, color = #000000, alpha = 1.0)`

#### touchMode
Define ineraction with mouse/touches.

* `none` - like Starling's `touchable = false`
* **`branch`** - like Starling's `touchGroup = false`
* `leaf` - like Starling's `touchGroup = true`
#### touchEvents

> This attribute added for optimization reasons.

Nodes with enabled `touchEvents` change self <a href="#state">`state`</a> value add/remove `hover` and `active` based on mouse/touch interactions.  

* **`false`**
* `true`

#### cursor

Setup mouse cursor above node.

* **`auto`**
* `arrow`
* `button`
* `hand`
* `ibeam`
* Any registered custom cursors

#### blendMode
* Any supported <a href="http://doc.starling-framework.org/current/starling/display/BlendMode.html">BlendMode</a>

#### visible
> Invisible nodes doesn't included in parent layouts.

Setup node visibility.

* **`true`**
* `false`

#### filter
Setup node filter(s).

* **`none`**
* `blur(x = 0, y = x)`
* `saturate(value = 0)` within `[-1; +1]`
* `brightness(value = 0)` within `[-1; +1]`
* `contrast(value = 0)` within `[-1; +1]`
* `hue(angle = 0)` accept <a href="#angle">ANGLE</a>
* `tint(color = #000000, amount = 1)` accept <a href="#color">COLOR</a>, amount within `[-1; +1]`
* Any combinations of above filters, like `blur() hue(45)`

#### alpha
Setup node alpha, default **`1`**.

#### transform
> Transform doesn't change node layout bounds.

Setup node transformation use <a href="#pivot">pivot</a> as pivot point.

* **`none`**
* `scale(scaleX = 1, scaleY = scaleX)`
* `scaleX(value = 1)`
* `scaleY(value = 1)`
* `rotate(value = 0)` accept <a href="#angle">ANGLE</a>
* `translate(x = 0, y = x)`
* `translateX(value = 0)`
* `translateY(value = 0)`
* `skewX(value = 0)`
* `skewY(value = 0)`
* `matrix(aa, ba, ca, da, txa, tya)` all arguments are required
* Any combinations of above transformations

#### pivot
> Use <a href="#pair">pair</a> of `pivotX` and `pivotY`.

Setup transformation pivot point, default **`0px`**.

* <a href="#gauge">`GAUGE`</a>

#### width/height
> See <a href="layouts.md">layouts</a> article.

#### minWidth/maxWidth/minHeight/maxHeight
> See <a href="layouts.md">layouts</a> article.

* <a href="#gauge">`GAUGE`</a>

#### margin 
> See <a href="layouts.md">layouts</a> article.  
> Use <a href="#quad">quad</a> of `marginTop`, `marginRight`, `marginBottom` and `marginLeft`.

* <a href="#gauge">`GAUGE`</a>

#### padding
> See <a href="layouts.md">layouts</a> article.  
> Use <a href="#quad">quad</a> of `paddingTop`, `paddingRight`, `paddingBottom` and `paddingLeft`.

* <a href="#gauge">`GAUGE`</a>

#### source
Setup image source.
* <a href="#resource">RESOURCE</a>

#### tint
Setup image source tint color.

#### text
Setup rendered text.

#### layout
#### anchor
#### orientation
#### align
#### gap
#### interline
#### wrap
#### alignSelf
#### break

* * *

### Types
Some data types is reusable and can has several formats, there are these types.

#### Color
* `#XXXXXX` hexadecimal format
* `rgb(r, g, b)` there `r,g,b` within `[0, 255]`
* `white`, `silver`, `gray`, `black`, `red`, `maroon`, `yellow`, `olive`, `lime`, `green`, `aqua`, `teal`, `blue`, `navy`, `fuchsia`, `purple`

#### Gauge
Format is `NUMBER [UNIT]` there are units:
* `none` this is null analog, in more cases calculated as `0`, but in same attributes (as `width`/`height`) has special logic
* `px` pysical pixel  
In case there is no units used pixels by default (`100px` equals `100`).  
* `dp` device-independent pixel like in Android it is equivalent to one physical pixel on 160 dpi screen
* `mm` pysical millimeter 
* `em` like css ems this is current node `fontSize` value in pixels
* `%` percents base value for calculation depends on attribute
* `*` stars implies "free space" see [layouts article](layouts.md) for more information  
In case stars it is possible to ommit amount for `1` value (`1*` equals `*`).

> **NB!** Today on web/desktop application air doesn't have access to screen DPI so `dp` and `mm` units are not correct value.


#### Angle
Format is `NUMBER [UNIT]` there are units:
* **`deg`** in case there is no units used degrees by default
* `rad`
* `turn`

For example: `0.5turn`, `45deg`, `90`, `1.5rad` etc.

#### Align
* `left`, `top`
* `center`, `middle`
* `right`, `bottom`
* `NUMBER %` in some cases useable percentages as value with next mapping:
	* `left` and `top` = `0%`
	* `center` and `middle` = `50%`
	* `right` and `bottom` = `100%`

#### Resource
Absolutely **any** attribute can use resource as value.

* `$KEY` in case KEY is simple identifier
* `$("KEY")` in case KEY contains non-identifier chars

* * *

### Compositions
Some of attributes are special composition of another attributes like `pivot` and `pivotX`, `pivotY`. There are 2 typical composition type, based on amount of composed attributes.  

#### Pair
For example:

* `pivot = X` equals:
	* `pivotX = X`
	* `pivotY = X`
* `pivot = X Y` equals:
	* `pivotX = X`
	* `pivotY = Y`

#### Quad
For example:

* `margin = X` equals:
	* `marginTop = X`
	* `marginRight = X`
	* `marginBottom = X`
	* `marginLeft = X`
* `margin = X Y` equals:
	* `marginTop = X`
	* `marginRight = Y`
	* `marginBottom = X`
	* `marginLeft = Y`
* `margin = X Y Z` equals:
	* `marginTop = X`
	* `marginRight = Y`
	* `marginBottom = Z`
	* `marginLeft = Y`
* `margin = X Y Z W` equals:
	* `marginTop = X`
	* `marginRight = Y`
	* `marginBottom = Z`
	* `marginLeft = W`
