package talon.starling
{
	import flash.geom.Rectangle;

	import starling.core.RenderSupport;
	import starling.display.QuadBatch;
	import starling.textures.Texture;
	import starling.textures.TextureSmoothing;

	public class Filler
	{
		private static var POOL:Vector.<QuadData>;
		private static var HELPER:QuadBetrayer;
		private static const QUAD:int = 0x1;
		private static const QUAD_AND_MESH:int = 0x3;

		private var _smoothing:String;
		private var _texture:Texture;
		private var _grid:Rectangle;
		private var _width:Number;
		private var _height:Number;
		private var _color:uint;
		private var _transparent:Boolean;
		private var _alpha:Number;

		private var _quads:Vector.<QuadData>;
		private var _batch:QuadBatch;

		private var _invalid:int;

		public function Filler():void
		{
			POOL = new <QuadData>[];
			HELPER = new QuadBetrayer();

			_invalid = QUAD_AND_MESH;
			_grid = new Rectangle();
			_quads = new <QuadData>[];
			_batch = new QuadBatch();
			_width = 0;
			_height = 0;
			_color = 0xFFFFFF;
			_alpha = 1;
			_smoothing = TextureSmoothing.BILINEAR;
		}

		public function render(support:RenderSupport, parentAlpha:Number):void
		{
			if (_texture == null && _transparent) return;

			if (_invalid != 0)
			{
				invalid(QUAD_AND_MESH) && remesh();
				invalid(QUAD) && compose();
				_invalid = 0;
			}

			support.batchQuadBatch(_batch, parentAlpha);
		}

		private function invalidate(mask:int):void { _invalid |= mask; }
		private function invalid(mask:int):Boolean { return (_invalid & mask) != 0; }

		private function remesh():void
		{
			// Release prev quads list
			while (_quads.length > 0)
				POOL[POOL.length] = _quads.pop();

			remesh9Scale();
		}

		/** Recalculate _quads list. */
		private function remesh9Scale():void
		{
			var tw:Number = _texture.width;
			var th:Number = _texture.height;

			if (_grid.width == tw && _grid.height == th)
			{
				// No 9-scale
				_quads[_quads.length] = getQuadData(0, 0, tw, th);
			}
			else if (_grid.width != tw && _grid.height == th)
			{
				// Row (3-scale)
				_quads[_quads.length] = getQuadData(0, 0, _grid.left, th); // left
				_quads[_quads.length] = getQuadData(_grid.left, 0, _grid.right, th); // center
				_quads[_quads.length] = getQuadData(_grid.right, 0, tw, th); // right

			}
			else if (_grid.width == tw && _grid.height != th)
			{
				// Column (3-scale)
				_quads[_quads.length] = getQuadData(0, 0, tw, _grid.top); // top
				_quads[_quads.length] = getQuadData(0, _grid.top, tw, _grid.bottom); // center
				_quads[_quads.length] = getQuadData(0, _grid.bottom, tw, th); // bottom
			}
			else
			{
				// 9-scale
				_quads[_quads.length] = getQuadData(0, 0, _grid.left, _grid.top); // top-left
				_quads[_quads.length] = getQuadData(_grid.left, 0, _grid.right, _grid.top); // top-center
				_quads[_quads.length] = getQuadData(_grid.right, 0, tw, _grid.top); // top-right

				_quads[_quads.length] = getQuadData(0, _grid.top, _grid.left, grid.bottom); // center-left
				_quads[_quads.length] = getQuadData(_grid.left, _grid.top, _grid.right, grid.bottom); // center-center
				_quads[_quads.length] = getQuadData(_grid.right, _grid.top, tw, grid.bottom); // center-right

				_quads[_quads.length] = getQuadData(0, _grid.bottom, _grid.left, th); // bottom-left
				_quads[_quads.length] = getQuadData(_grid.left, _grid.bottom, _grid.right, th); // bottom-center
				_quads[_quads.length] = getQuadData(_grid.right, _grid.bottom, tw, th); // bottom-right
			}
		}

		private function getQuadData(x1:Number, y1:Number, x2:Number, y2:Number):QuadData
		{
			var scaleX:Number = _width/_texture.width;
			var scaleY:Number = _height/_texture.height;
			var data:QuadData = POOL.pop() || new QuadData();
			data.adjust(x1*scaleX, y1*scaleY, x2*scaleX, y2*scaleY, _width, _height);
			return data;
		}

		/** Compose BatchQuad use _quads list. */
		private function compose():void
		{
			_batch.reset();

			var quadAmount:int = _quads.length;
			var quadData:QuadData = null;

			for (var i:int = 0; i < quadAmount; i++)
			{
				if (i == 4) continue;

				quadData = _quads[i];

				// Position
				HELPER.setVertexPosition(0, quadData.x1, quadData.y1);
				HELPER.setVertexPosition(1, quadData.x2, quadData.y1);
				HELPER.setVertexPosition(2, quadData.x1, quadData.y2);
				HELPER.setVertexPosition(3, quadData.x2, quadData.y2);

				// Texture
				HELPER.setTexCoords(0, quadData.ux1, quadData.vy1);
				HELPER.setTexCoords(1, quadData.ux2, quadData.vy1);
				HELPER.setTexCoords(2, quadData.ux1, quadData.vy2);
				HELPER.setTexCoords(3, quadData.ux2, quadData.vy2);

				HELPER.adjust(texture);

				_batch.addQuad(HELPER, 1.0, _texture, _smoothing);
			}
		}

		//
		// Properties
		//
		public function get texture():Texture { return _texture; }
		public function set texture(value:Texture):void
		{
			if (texture != value)
			{
				_texture = value;
				invalidate(QUAD);
			}
		}

		public function get grid():Rectangle { return _grid; }
		public function set grid(value:Rectangle):void
		{
			if (_grid != value)
			{
				if (value != null) _grid.copyFrom(value);
				else _grid.setEmpty();
				invalidate(QUAD_AND_MESH);
			}
		}

		public function get smoothing():String { return _smoothing; }
		public function set smoothing(value:String):void
		{
			if (_smoothing != value)
			{
				if (TextureSmoothing.isValid(value)) _smoothing = value;
				else throw new ArgumentError("Invalid smoothing mode: " + value);
				invalidate(QUAD);
			}
		}

		public function get width():Number { return _width; }
		public function set width(value:Number):void
		{
			if (_width != value)
			{
				_width = value;
				invalidate(QUAD_AND_MESH);
			}
		}

		public function get height():Number { return _height; }
		public function set height(value:Number):void
		{
			if (_height != value)
			{
				_height = value;
				invalidate(QUAD_AND_MESH);
			}
		}

		public function get color():uint { return _color; }
		public function set color(value:uint):void
		{
			if (_color != value)
			{
				_color = value;
				invalidate(QUAD_AND_MESH);
			}
		}

		public function get transparent():Boolean { return _transparent; }
		public function set transparent(value:Boolean):void
		{
			if (_transparent != value)
			{
				_transparent = value;
				invalidate(QUAD_AND_MESH);
			}
		}

		public function get alpha():Number { return _alpha; }
		public function set alpha(value:Number):void
		{
			if (_alpha != value)
			{
				_alpha = value;
				invalidate(QUAD);
			}
		}
	}
}

import flash.geom.Matrix;

import starling.display.Quad;
import starling.textures.Texture;
import starling.utils.VertexData;

class QuadBetrayer extends Quad
{
	private var mVertexDataCache:VertexData;

	public function QuadBetrayer():void
	{
		super(1, 1);
		mVertexDataCache = new VertexData(4);
	}

	public function setVertexPosition(vertexID:int, x:Number, y:Number):void
	{
		mVertexData.setPosition(vertexID, x, y);
		onVertexDataChanged();
	}

	public function setTexCoords(vertexID:int, u:Number, y:Number):void
	{
		mVertexData.setTexCoords(vertexID, u, y);
		onVertexDataChanged();
	}

	public function adjust(texture:Texture):void
	{
		mVertexData.copyTo(mVertexDataCache);
		texture.adjustVertexData(mVertexDataCache, 0, 4);
	}

	public override function copyVertexDataTo(targetData:VertexData, targetVertexID:int=0):void
	{
		copyVertexDataTransformedTo(targetData, targetVertexID, null);
	}

	public override function copyVertexDataTransformedTo(targetData:VertexData, targetVertexID:int=0, matrix:Matrix=null):void
	{
		mVertexDataCache.copyTransformedTo(targetData, targetVertexID, matrix, 0, 4);
	}
}

class QuadData
{
	public var x1:Number;
	public var y1:Number;

	public var x2:Number;
	public var y2:Number;

	public var ux1:Number;
	public var vy1:Number;

	public var ux2:Number;
	public var vy2:Number;

	public function adjust(x1:Number, y1:Number, x2:Number, y2:Number, tw:Number, th:Number):void
	{
		this.x1 = x1;
		this.y1 = y1;

		this.x2 = x2;
		this.y2 = y2;

		this.ux1 = x1/tw;
		this.vy1 = y1/th;

		this.ux2 = x2/tw;
		this.vy2 = y2/th;
	}
}