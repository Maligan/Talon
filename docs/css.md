## Talon CSS Dialect
All attribute names use *smallCamelCaseNotation*, without dashed like W3C/Flex dialects.
Next attributes used within Talon:

### Attribute list

#### `id`
#### `type`
class
state
width
height
minWidth
minHeight
maxWidth
maxHeight
margin
marginTop
marginRight
marginBottom
marginLeft  
padding     
paddingTop      
paddingRight    
paddingBottom   
paddingLeft     
anchor          
anchorTop       
anchorRight     
anchorBottom      
anchorLeft        
backgroundImage   
backgroundTint    
background9Scale  
backgroundColor   
backgroundAlpha   
backgroundBlendMode | `auto`                        | `auto`, `none`, `normal`, `add`, `multiply`, `screen`, `erase`, `mask`, `below`
backgroundFillMode
fontColor         
fontName          
fontSize          
fontSharpness     
alpha             
blendMode           | `auto`                        | `add`, `auto`, `below`, `erase`, `mask`, `multiply`, `none`, `normal`, `screen` (from [starling.display.BlendMode](https://github.com/Gamua/Starling-Framework/blob/master/starling%2Fsrc%2Fstarling%2Fdisplay%2FBlendMode.as))
cursor              | `auto`                        | `arrow`, `auto`, `button`, `hand`, `ibeam` (from [flash.ui.MouseCursor](http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/flash/ui/MouseCursor.html))
layout              | `flow`                        | `flow`, `abs`, `grid`
visible             
filter              
position            
x                   
y                   
pivot               
pivotX              
pivotY              
orientation         
halign              
valign             
ihalign            
ivalign            
gap                
interline          
wrap               
break              
autoScale          
src                
text               

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
