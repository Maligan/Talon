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
* <a href="#fillmode">fillMode (fillModeHorizontal, fillModeVertical)</a>
* <a href="#fillscale">fillScale (fillScaleHorizontal, fillScaleVertical)</a>
* <a href="#fillstretchgrid">fillStretchGrid (fillStretchGridTop, fillStretchGridRight, fillStretchGridBottom, fillStretchGridLeft)</a>
* <a href="#fillalign">fillAlign (fillAlignHorizontal, fillAlignVertical)</a>
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
* <a href="#align">align (halign, valign)</a>
* <a href="#gap">gap</a>
* <a href="#interline">interline</a>
* <a href="#wrap">wrap</a>
* <a href="#alignSelf">alignSelf (halignSelf, valignSelf)</a>
* <a href="#break">break (breakBefore, breakAfter)</a>

* * *

#### id
Node identifier

#### type
Node type only attribute which can't be change on runtime.
Defines node behaviour

* `div`
* `txt`
* `img`
* Any registered user types.

#### class
#### state

See <a href="#touchevents">`touchEvents`</a>

#### fill
#### fillAlpha
#### fillBlendMode
#### fillTint
#### fillMode
#### fillScale
#### fillStretchGrid
#### fillAlign

#### fontColor
Set up font color, default **`#FFFFFF`**.

* **`inherit`**
* <a href="#color">`COLOR`</a>

#### fontName
Set up font, default **`mini`**.

* **`inherit`**
* Any system, embed or bitmap font name.

#### fontSize
Set up font size, default **`12px`**.

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

Set up mouse cursor under node.

* **`auto`**
* `arrow`
* `button`
* `hand`
* `ibeam`
* Any registered custom cursors

#### blendMode
#### visible
> Invisible nodes doesn't included in parent layouts.

Set up node visibility.

* **`true`**
* `false`

#### filter
Set up node filter(s).

* **`none`**
* `blur(x = 0, y = x)`
* `saturate(value = 0)` within `[-1; +1]`
* `brightness(value = 0)` within `[-1; +1]`
* `contrast(value = 0)` within `[-1; +1]`
* `hue(angle = 0)` accept <a href="#angle">ANGLE</a>
* `tint(color = #000000, amount = 1)` accept <a href="#color">COLOR</a>, amount within `[-1; +1]`
* Any combinations of above filters, like `blur() hue(45)`

#### alpha
Set up node alpha, default **`1`**.

#### transform
> Transform doesn't change node layout bounds.

Set up node transformation use <a href="#pivot">pivot</a> as pivot point.

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
There are `pivotX` and `pivotY`, default **`0px`**.

* <a href="#gauge">GAUGE</a>

#### width/height
#### minWidth/maxWidth/minHeight/maxHeight
#### margin 
#### padding

#### source
#### tint

#### text

#### anchor
#### layout
#### orientation
#### align
#### gap
#### interline
#### wrap
#### alignSelf
#### break

* * *

### Color
### Gauge
### Angle
