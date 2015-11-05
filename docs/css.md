### Node Style Sheet (CSS)
В названиях аттрбутов используется только *малаяВерблюжьяНотация*, без чёрточек как в W3C/Flex диалектах.
Следующий список аттрибутов используется в движке:

### Attribute list

Name                | Initial   | Range                                                                           | Comment
------              | -------   | -------------------                                                             | -------

id                  | null      | Identifier                                                                      |
type                | null      | Identifier                                                                      |
class               | null      | Array of identifier                                                             |
state               | null      | Array of identifier                                                             |

width               | `none`    | Gauge                                                                           |
height              | `none`    | Gauge                                                                           |
minWidth            | `none`    | Gauge                                                                           |
minHeight           | `none`    | Gauge                                                                           |
maxWidth            | `none`    | Gauge                                                                           |
maxHeight           | `none`    | Gauge                                                                           |

margin              | `none`    | Gauge Quad                                                                      |
marginTop           | `none`    | Gauge                                                                           |
marginRight         | `none`    | Gauge                                                                           |
marginBottom        | `none`    | Gauge                                                                           |
marginLeft          | `none`    | Gauge                                                                           |

padding             | `none`    | Gauge Quad                                                                      |
paddingTop          | `none`    | Gauge                                                                           |
paddingRight        | `none`    | Gauge                                                                           |
paddingBottom       | `none`    | Gauge                                                                           |
paddingLeft         | `none`    | Gauge                                                                           |

anchor              | `none`    | Gauge Quad                                                                      |
anchorTop           | `none`    | Gauge                                                                           |
anchorRight         | `none`    | Gauge                                                                           |
anchorBottom        | `none`    | Gauge                                                                           |
anchorLeft          | `none`    | Gauge                                                                           |

backgroundImage     | `none`    | Resource                                                                        |
backgroundTint      | `white`   | Color                                                                           |
background9Scale    | `none`    | Gauge Quad                                                                      |
backgroundColor     | `none`    | Color                                                                           |
backgroundAlpha     | `1`       | [0; 1]                                                                          |
backgroundBlendMode | `auto`    | `auto`, `none`, `normal`, `add`, `multiply`, `screen`, `erase`, `mask`, `below` |
backgroundFillMode  | `scale`   | `scale`, `clip`, `repeat`                                                       |

fontColor           | `inherit` | Color                                                                           | Inheritable defalut `white`
fontName            | `inherit` | Font Name (bitmap, embeded or system)                                           | Inheritable default `Times New Roman`
fontSize            | `inherit` | Gauge                                                                           | Inheritable default `12px`
fontSharpness       | `inherit` | [0; 1]                                                                          | Inheritable default `0`

alpha	| `1` | [0; 1] |
clipping | `false` | `true`, `false` |
"blendMode"
"cursor"
"filter"
"layout"
"visible"

"position"
"x"
"y"
"pivot"
"pivotX"
"pivotY"
"value"
"originX"
"originY"

"orientation"
"halign"
"valign"
"ihalign"
"ivalign"
"gap"
"interline"
"wrap"
"break"

"autoScale"
"text"
"src"
