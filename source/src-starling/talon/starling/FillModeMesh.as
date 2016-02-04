package talon.starling
{
	import starling.display.Mesh;
	import starling.rendering.IndexData;
	import starling.rendering.MeshStyle;
	import starling.rendering.Painter;
	import starling.rendering.VertexData;
	import starling.utils.Align;
	import starling.utils.Color;

	import talon.enums.FillMode;
	import talon.utils.StringParseUtil;

	public class FillModeMesh extends Mesh
	{
		private static var _byX:Vector.<Ruler>;
		private static var _byY:Vector.<Ruler>;

		private var _width:Number;
		private var _height:Number;
		private var _color:uint;

		private var _transparent:Boolean;
		private var _horizontalFillMode:String;
		private var _verticalFillMode:String;
		private var _horizontalAlign:String;
		private var _verticalAlign:String;
		private var _stretchOffsets:Vector.<Number>;

		private var _requiresRecomposition:Boolean;

		public function FillModeMesh()
		{
			var vertexData:VertexData = new VertexData(MeshStyle.VERTEX_FORMAT, 4);
			var indexData:IndexData = new IndexData(6);

			super(vertexData, indexData, style);

			_stretchOffsets = new Vector.<Number>(4, true);
			_stretchOffsets[0] = _stretchOffsets[1] = _stretchOffsets[2] = _stretchOffsets[3] = 0;
			_horizontalFillMode = _verticalFillMode = FillMode.STRETCH;
			_horizontalAlign = Align.LEFT;
			_verticalAlign = Align.TOP;

			_transparent = true;
			_color = Color.WHITE;
			_width = 0;
			_height = 0;
			_requiresRecomposition = true;
		}

		/** @inherit */
		public override function render(painter:Painter):void
		{
			if (_requiresRecomposition) recompose();
			super.render(painter);
		}

		private function setRequiresRecomposition():void
		{
			_requiresRecomposition = true;
			setRequiresRedraw();
		}

		//
		// Properties
		//

		/** @inherit */
		public override function get width():Number { return _width; }
		public override function set width(value:Number):void
		{
			if (_width != value)
			{
				_width = value;
				setRequiresRecomposition();
			}
		}

		/** @inherit */
		public override function get height():Number { return _height; }
		public override function set height(value:Number):void
		{
			if (_height != value)
			{
				_height = value;
				setRequiresRecomposition();
			}
		}

		/** @inherit */
		public override function get color():uint { return _color; }
		public override function set color(value:uint):void
		{
			if (_color != value)
			{
				_color = value;
				setRequiresRecomposition();
			}
		}

		public function get transparent():Boolean { return _transparent; }
		public function set transparent(value:Boolean):void
		{
			if (_transparent != value)
			{
				_transparent = value;
				setRequiresRecomposition();
			}
		}

		/** Define algorithm of filling background area with texture via x-axis. */
		public function get horizontalFillMode():String { return _horizontalFillMode; }
		public function set horizontalFillMode(value:String):void
		{
			if (_horizontalFillMode != value)
			{
				_horizontalFillMode = value;
				setRequiresRecomposition();
			}
		}

		/** Define algorithm of filling background area with texture via y-axis. */
		public function get verticalFillMode():String { return _verticalFillMode; }
		public function set verticalFillMode(value:String):void
		{
			if (_verticalFillMode != value)
			{
				_verticalFillMode = value;
				setRequiresRecomposition();
			}
		}

		public function get horizontalAlign():String { return _horizontalAlign; }
		public function set horizontalAlign(value:String):void
		{
			if (_horizontalAlign != value)
			{
				_horizontalAlign = value;
				setRequiresRecomposition();
			}
		}

		public function get verticalAlign():String { return _verticalAlign; }
		public function set verticalAlign(value:String):void
		{
			if (_verticalAlign != value)
			{
				_verticalAlign = value;
				setRequiresRecomposition();
			}
		}

		/** Define FillMode.STRETCH 9-scale grid for texture filling. */
		public function setStretchOffsets(top:Number, right:Number, bottom:Number, left:Number):void
		{
			_stretchOffsets[0] = top;
			_stretchOffsets[1] = right;
			_stretchOffsets[2] = bottom;
			_stretchOffsets[3] = left;

			setRequiresRecomposition();
		}

		//
		// Recompose algorithm - main purpose of this class and all background system
		//

		private function recompose():void
		{
			if (_requiresRecomposition)
			{
				// Calculate horizontal and vertical rulers
				_byX ||= new <Ruler>[];
				_byY ||= new <Ruler>[];
				recomposeRulers(_byX, _byY);

				// Compose vertices from rulers
				vertexData.clear();
				indexData.clear();

				var quadIndex:int = 0;

				for (var h:int = 0; h < _byX.length-1; h++)
				{
					for (var v:int = 0; v < _byY.length-1; v++)
					{
						var n:int = quadIndex * 4;

						// Init quad with starling 'quad layout'
						setVertex(n, 0, _byX[h],   _byY[v]);
						setVertex(n, 1, _byX[h+1], _byY[v]);
						setVertex(n, 2, _byX[h],   _byY[v+1]);
						setVertex(n, 3, _byX[h+1], _byY[v+1]);

						indexData.addQuad(n, n+1, n+2, n+3);
						quadIndex++;
					}
				}

				// Return rulers to pool
				while (_byX.length) Ruler.putRuler(_byX.pop());
				while (_byY.length) Ruler.putRuler(_byY.pop());

				_requiresRecomposition = false;
			}
		}

		private function recomposeRulers(horizontal:Vector.<Ruler>, vertical:Vector.<Ruler>):void
		{
			if (texture)
			{
				switch (horizontalFillMode)
				{
					case FillMode.STRETCH:  fillStretch(width, texture.width, _stretchOffsets[3], _stretchOffsets[1], horizontal); break;
					case FillMode.REPEAT:   fillRepeat(width, texture.width, StringParseUtil.parseAlign(horizontalAlign), horizontal); break;
					case FillMode.NONE:     fillNone(width, texture.width, StringParseUtil.parseAlign(horizontalAlign), horizontal); break;
				}

				switch (verticalFillMode)
				{
					case FillMode.STRETCH:  fillStretch(height, texture.height, _stretchOffsets[0], _stretchOffsets[2], vertical); break;
					case FillMode.REPEAT:   fillRepeat(height, texture.height, StringParseUtil.parseAlign(verticalAlign), vertical); break;
					case FillMode.NONE:     fillNone(height, texture.height, StringParseUtil.parseAlign(verticalAlign), vertical); break;
				}
			}
			else if (!transparent)
			{
				horizontal.push(Ruler.getRuler(0, 0, 1));
				horizontal.push(Ruler.getRuler(width, 0, 1));

				vertical.push(Ruler.getRuler(0, 0, 1));
				vertical.push(Ruler.getRuler(height, 0, 1));
			}
		}

		private function setVertex(indexBase:int, indexShift:int, h:Ruler, v:Ruler):void
		{
			var index:int = indexBase + indexShift;
			var tx:Number = (indexShift==0 || indexShift==2) ? h.texAtBegin : h.texAtEnd;
			var ty:Number = (indexShift==0 || indexShift==1) ? v.texAtBegin : v.texAtEnd;

			vertexData.setPoint(index, "position", h.pos, v.pos);
			vertexData.setPoint(index, "texCoords", tx, ty);
			vertexData.setColor(index, "color", color);
		}

		private function fillRepeat(size:Number, tsize:Number, align:Number, result:Vector.<Ruler>):void
		{
			var fullRepsCount:int = size/tsize;
			var fullRepsSize:int = fullRepsCount*tsize;
			var offset:Number = (size - fullRepsSize) * align;

			// Begin partial tile
			if (offset > 0) result[result.length] = Ruler.getRuler(0, 1 - offset/tsize, NaN);

			// Full repeat tile(s)
			if (fullRepsCount > 0 || int(align) == align)
			{
				for (; offset <= size; offset += tsize)
					result[result.length] = Ruler.getRuler(offset, 0, 1);

				offset -= tsize;
			}

			// End partial tile
			if (offset < size) result[result.length] = Ruler.getRuler(size, NaN, (size-offset) / tsize);
		}

		private function fillStretch(size:Number, tsize:Number, offset1:Number, offset2:Number, result:Vector.<Ruler>):void
		{
			// Begin point
			result.push(Ruler.getRuler(0, 0, NaN));

			var hasUnstretchable:Boolean = (size > offset1+offset2) && (size > tsize);
			if (hasUnstretchable)
			{
				// Unstretchable section #1
				if (offset1 != 0) result.push(Ruler.getRuler(offset1, offset1/tsize, offset1/tsize));

				// Unstretchable section #2
				if (offset2 != 0) result.push(Ruler.getRuler(size-offset2, 1-offset2/tsize, 1-offset2/tsize));
			}

			// End point
			result.push(Ruler.getRuler(size, NaN, 1));
		}

		private function fillNone(size:Number, tsize:Number, align:Number, result:Vector.<Ruler>):void
		{
			if (size > tsize)
			{
				var posOffset:Number = (size - tsize) * align;
				result.push(Ruler.getRuler(posOffset,         0,   NaN));
				result.push(Ruler.getRuler(posOffset + tsize, NaN, 1));
			}
			else
			{
				var texOffset:Number = (tsize-size)/tsize * align;
				result.push(Ruler.getRuler(0,    texOffset, NaN));
				result.push(Ruler.getRuler(size, NaN,       texOffset + size/tsize));
			}
		}
	}
}

class Ruler
{
	private static const _pool:Vector.<Ruler> = new <Ruler>[];

	public static function getRuler(pos:Number, texAtBegin:Number, texAtEnd:Number):Ruler { return (_pool.pop() || new Ruler()).reset(pos, texAtBegin, texAtEnd); }
	public static function putRuler(ruler:Ruler):void { _pool.push(ruler); }

	public var pos:Number;
	public var texAtBegin:Number;
	public var texAtEnd:Number;

	private function reset(pos:Number, texAtBegin:Number, texAtEnd:Number):Ruler
	{
		this.pos = pos;
		this.texAtBegin = texAtBegin;
		this.texAtEnd = texAtEnd;

		return this;
	}
}