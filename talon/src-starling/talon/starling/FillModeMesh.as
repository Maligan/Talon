package talon.starling
{
	import starling.display.Mesh;
	import starling.rendering.IndexData;
	import starling.rendering.MeshStyle;
	import starling.rendering.Painter;
	import starling.rendering.VertexData;
	import starling.utils.Align;

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
				var result:Vector.<Vertex> = new <Vertex>[];

				fillRepeat(result, width, horizontalAlign, true);
				fillRepeat(result, height, verticalAlign, false);

				// ... sort
				// ... reverse

				while (result.length)
				{
					var vertex:Vertex = result.pop();
					// ... write to VertexData
					Vertex.putVertex(vertex);
				}

				_requiresRecomposition = false;
			}
		}

		private function fillRepeat(result:Vector.<Vertex>, size:int, align:*, horizontal:Boolean):void
		{
			if (result.length == 0)
			{

			}
		}
	}
}

class Vertex
{
	private static const  _pool:Vector.<Vertex> = new <Vertex>[];

	public static function getVertex(x:Number = 0, y:Number = 0, u:Number = 0, v:Number = 0):Vertex { return (_pool.pop() || new Vertex()).reset(x, y, u ,v); }
	public static function putVertex(vertex:Vertex):void { _pool.push(vertex); }

	public var x:Number;
	public var y:Number;
	public var u:Number;
	public var v:Number;

	public function setValues(p:Number, t:Number, horizontal:Boolean):void
	{
		if (horizontal)
		{
			x = p;
			u = t;
		}
		else
		{
			y = p;
			v = t;
		}
	}

	public function clone():Vertex
	{
		return getVertex(x, y, u, v);
	}

	private function reset(x:Number, y:Number, u:Number, v:Number):Vertex
	{
		this.x = x;
		this.y = y;
		this.u = u;
		this.v = v;
		return this;
	}
}