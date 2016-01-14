package talon.starling
{
	import flash.geom.Point;

	import starling.display.Mesh;
	import starling.rendering.IndexData;
	import starling.rendering.MeshStyle;
	import starling.rendering.Painter;
	import starling.rendering.VertexData;
	import starling.utils.Align;
	import starling.utils.Pool;

	import talon.enums.FillMode;

	public class FillModeMesh extends Mesh
	{
		private var _horizontalFillMode:String;
		private var _verticalFillMode:String;
		private var _horizontalAlign:String;
		private var _verticalAlign:String;
		private var _scale9Offsets:Vector.<Number>;

		private var _width:Number;
		private var _height:Number;

		private var _requiresRecomposition:Boolean;

		public function FillModeMesh()
		{
			var vertexData:VertexData = new VertexData(MeshStyle.VERTEX_FORMAT, 4);
			var indexData:IndexData = new IndexData(6);

			super(vertexData, indexData, style);

			_scale9Offsets = new Vector.<Number>(4, true);
			_scale9Offsets[0] = _scale9Offsets[1] = _scale9Offsets[2] = _scale9Offsets[3] = 0;
			_horizontalFillMode = _verticalFillMode = FillMode.STRETCH;
			_horizontalAlign = Align.LEFT;
			_verticalAlign = Align.TOP;

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

		/** Define algorithm of filling background area by texture via x-axis. */
		public function get horizontalFillMode():String { return _horizontalFillMode; }
		public function set horizontalFillMode(value:String):void
		{
			if (_horizontalFillMode != value)
			{
				_horizontalFillMode = value;
				setRequiresRecomposition();
			}
		}

		/** Define algorithm of filling background area by texture via y-axis. */
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
		public function setScale9Offsets(top:Number, right:Number, bottom:Number, left:Number):void
		{
			_scale9Offsets[0] = top;
			_scale9Offsets[1] = right;
			_scale9Offsets[2] = bottom;
			_scale9Offsets[3] = left;

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

				// ... horizontal
				var byX:Vector.<Point> = new <Point>[];
				switch (horizontalFillMode)
				{
					case FillMode.STRETCH:  fillStretch(width, 25, _scale9Offsets[3], _scale9Offsets[1], byX); break;
					case FillMode.REPEAT:   fillRepeat(width, 25, horizontalAlign, byX); break;
					case FillMode.NONE:     fillNone(width, 25, horizontalAlign, byX); break;
				}

				// .. vertical
				var byY:Vector.<Point> = new <Point>[];
				switch (verticalFillMode)
				{
					case FillMode.STRETCH:  fillStretch(height, 25, _scale9Offsets[0], _scale9Offsets[2], byY); break;
					case FillMode.REPEAT:   fillRepeat(height, 25, verticalAlign, byY); break;
					case FillMode.NONE:     fillNone(height, 25, verticalAlign, byY); break;
				}

				// Compose vertices from rulers
				vertexData.clear();
				indexData.clear();

				var quadIndex:int = 0;

				for (var h:int = 0; h < byX.length-1; h++)
				{
					for (var v:int = 0; v < byY.length-1; v++)
					{
						var n:int = quadIndex * 4;

						_col = int(Math.random() * 0xFFFFFF);
						setVertex(n,   byX[h],   byY[v]);
						setVertex(n+1, byX[h+1], byY[v]);
						setVertex(n+2, byX[h],   byY[v+1]);
						setVertex(n+3, byX[h+1], byY[v+1]);

						indexData.appendQuad(n, n+1, n+2, n+3);
						quadIndex++;
					}
				}

				// Return points to starling pool
				while (byX.length) Pool.putPoint(byX.pop());
				while (byY.length) Pool.putPoint(byY.pop());

				_requiresRecomposition = false;
			}
		}

		private var _col:uint;

		private function setVertex(index:int, h:Point, v:Point):void
		{
			// flash.geom.Point usage: in 'x' - vertex position, in 'y' - texture position
			vertexData.setPoint(index, "position", h.x, v.x);
			vertexData.setPoint(index, "texCoords", h.y, v.y);
			vertexData.setColor(index, "color", _col);
		}

		private function fillRepeat(size:Number, tsize:Number, align:*, result:Vector.<Point>):void
		{
			var offset:Number = 0;
			while (offset < size)
			{
				result[result.length] = Pool.getPoint(offset, 0); // ? what add texture position
				offset += tsize;
			}

			result[result.length] = Pool.getPoint(size);
		}

		private function fillStretch(size:Number, tsize:Number, offset1:Number, offset2:Number, result:Vector.<Point>):void
		{
			// Begin point
			result.push(Pool.getPoint(0, 0));

			var hasValid9Scale:Boolean = (size > offset1+offset2) && (size > tsize);
			if (hasValid9Scale)
			{
				// Unscalable section #1
				if (offset1 != 0) result.push(Pool.getPoint(offset1, offset1/tsize));

				// Unscalable section #2
				if (offset2 != 0) result.push(Pool.getPoint(size-offset2, 1-offset2/tsize));
			}

			// End point
			result.push(Pool.getPoint(size, 1));
		}

		private function fillNone(size:Number, tsize:Number, align:*, result:Vector.<Point>):void
		{
			// Nope
		}
	}
}

class Ruler
{
	private static const _pool:Vector.<Ruler> = new <Ruler>[];
	public static function getRuler(pos:Number, texBefore:Number, texAfter:Number):Ruler { return _pool.pop() || new Ruler(); }
	public static function putRuler(ruler:Ruler):void { _pool.push(ruler); }

	public var pos:Number;
	public var texBefore:Number;
	public var texAfter:Number;
}