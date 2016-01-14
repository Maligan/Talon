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
		private var _fillModeX:String;
		private var _fillModeY:String;
		private var _horizontalAlign:String;
		private var _verticalAlign:String;
		private var _scale9Offsets:Vector.<Number>;

		private var _requiresRecomposition:Boolean;

		public function FillModeMesh()
		{
			var vertexData:VertexData = new VertexData(MeshStyle.VERTEX_FORMAT, 4);
			vertexData.setPoint(0, "position", 0,  0);
			vertexData.setPoint(1, "position", 100, 0);
			vertexData.setPoint(2, "position", 0,  100);
			vertexData.setPoint(3, "position", 100, 100);

			var indexData:IndexData = new IndexData(6);
			indexData.appendQuad(0, 1, 2, 3);

			super(vertexData, indexData, style);

			_scale9Offsets = new Vector.<Number>(4, true);
			_scale9Offsets[0] = _scale9Offsets[1] = _scale9Offsets[2] = _scale9Offsets[3] = 0;
			_fillModeX = _fillModeY = FillMode.SCALE;
			_horizontalAlign = Align.LEFT;
			_verticalAlign = Align.TOP;
		}

		/** @inherit */
		public override function render(painter:Painter):void
		{
			if (_requiresRecomposition) recompose();
			super.render(painter);
		}

		/** @inherit */
		private function setRequiresRecomposition():void
		{
			_requiresRecomposition = true;
			setRequiresRedraw();
		}

		//
		// Properties
		//

		/** Define algorithm of filling background area by texture via x-axis. */
		public function get fillModeX():String { return _fillModeX; }
		public function set fillModeX(value:String):void
		{
			if (_fillModeX != value)
			{
				_fillModeX = value;
				setRequiresRecomposition();
			}
		}

		/** Define algorithm of filling background area by texture via y-axis. */
		public function get fillModeY():String { return _fillModeX; }
		public function set fillModeY(value:String):void
		{
			if (_fillModeY != value)
			{
				_fillModeY = value;
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

		/** Define FillMode.SCALE 9-scale grid for texture filling. */
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
				switch (fillModeX)
				{
					case FillMode.SCALE:
						fillScale(width, texture.width, _scale9Offsets[3], _scale9Offsets[1], byX);
						break;
					case FillMode.REPEAT:
						fillRepeat(width, texture.width, horizontalAlign, byX);
						break;
					case FillMode.NONE:
						fillClip(width, texture.width, horizontalAlign, byX);
				}

				// .. vertical
				var byY:Vector.<Point> = new <Point>[];
				switch (fillModeY)
				{
					case FillMode.SCALE:
						fillScale(height, texture.height, _scale9Offsets[0], _scale9Offsets[2], byY);
						break;
					case FillMode.REPEAT:
						fillRepeat(height, texture.height, verticalAlign, byY);
						break;
					case FillMode.NONE:
						fillClip(height, texture.height, verticalAlign, byY);
				}

				// Compose vertices from rulers
				vertexData.numVertices = byX.length * byY.length;
				var vertexIndex:int = 0;

				for each (var h:Point in byX)
				{
					for each (var v:Point in byY)
					{
						vertexData.setPoint(vertexIndex, "position", h.x, v.x);
						vertexData.setPoint(vertexIndex, "texCoords", h.y, v.y);
						vertexIndex++;
					}
				}

				// Return points to starling pool
				while (byX.length) Pool.putPoint(byX.pop());
				while (byY.length) Pool.putPoint(byY.pop());

				_requiresRecomposition = false;
			}
		}

		private function fillRepeat(size:Number, tsize:Number, align:Number, result:Vector.<Point>):Vector.<Point>
		{

		}

		private function fillScale(size:Number, tsize:Number, offset1:Number, offset2:Number, result:Vector.<Point>):Vector.<Point>
		{
			var sumOffset:Number = offset1 + offset2;
			if (sumOffset == 0 || size == tsize || sumOffset >= size)
			{
				result[0] = Pool.getPoint(0, 0);
				result[1] = Pool.getPoint(size, 1);
			}
			else
			{
				result[0] = Pool.getPoint(0,            0);
				result[1] = Pool.getPoint(offset1,      offset1/tsize);
				result[2] = Pool.getPoint(size-offset2, 1-offset2/tsize);
				result[3] = Pool.getPoint(size,         1);
			}

			return result;
		}

		private function fillClip(size:Number, tsize:Number, align:Number, result:Vector.<Point>):Vector.<Point>
		{
			result[0] = Pool.getPoint()
		}
	}
}