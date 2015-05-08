package talon.starling
{
	import starling.core.RenderSupport;
	import starling.display.BlendMode;
	import starling.display.QuadBatch;
	import starling.errors.AbstractMethodError;
	import starling.textures.Texture;
	import starling.textures.TextureSmoothing;

	import talon.enums.FillMode;

	internal class BackgroundRenderer
	{
		private static var POOL:Vector.<QuadData>;
		private static var HELPER:QuadWithUnsafeAccess;
		private static const QUAD:int = 0x1;
		private static const MESH:int = 0x3;

		private var _smoothing:String;
		private var _texture:Texture;
		private var _width:Number;
		private var _height:Number;
		private var _color:uint;
		private var _tint:uint;
		private var _transparent:Boolean;
		private var _alpha:Number;
		private var _fillMode:String;

		private var _offsets:Scale9Offsets;

		private var _quads:Vector.<QuadData>;
		private var _batch:QuadBatch;

		private var _invalid:int;

		public function BackgroundRenderer():void
		{
			POOL = new <QuadData>[];
			HELPER = new QuadWithUnsafeAccess();

			_invalid = MESH;
			_quads = new <QuadData>[];
			_batch = new QuadBatch();
			_width = 0;
			_height = 0;
			_color = 0xFFFFFF;
			_tint = 0xFFFFFF;
			_alpha = 1;
			_smoothing = TextureSmoothing.BILINEAR;
			_offsets = new Scale9Offsets();
			_fillMode = FillMode.SCALE;
			_transparent = true;
		}

		public function render(support:RenderSupport, parentAlpha:Number):void
		{
			if (_texture == null && _transparent) return;

			if (_invalid != 0)
			{
				remesh();
				compose();
				_invalid = 0;
			}

			support.batchQuadBatch(_batch, parentAlpha);
		}

		private function invalidate(mask:int):void { _invalid |= mask; }
		private function invalid(mask:int):Boolean { return (_invalid & mask) != 0; }

		//
		// Defining quads for render
		//
		private function remesh():void
		{
			// Release prev quads list
			while (_quads.length > 0) POOL[POOL.length] = _quads.pop();

			// Define _quads for render
			if (_texture)
			{
				switch (_fillMode)
				{
					case FillMode.SCALE:    remeshScale();  break;
					case FillMode.REPEAT:   remeshRepeat(); break;
					case FillMode.CLIP:     remeshClip();   break;
					default: throw new Error("Unknown fillMode: " + _fillMode);
				}
			}
			else if (_transparent == false)
			{
				remeshColor();
			}
		}

		private function remeshColor():void
		{
			var quad:QuadData = getQuadData();
			quad.setPositions(0, 0, _width, _height);
			_quads[_quads.length] = quad;
		}

		private function remeshScale():void
		{
			var hp:Array = []; // Horizontal positions
			var ht:Array = []; // Horizontal texture positions (aka U)
			rulers(_width, _texture.width, _offsets.left, _offsets.right, hp, ht);

			var vp:Array = []; // Vertical positions
			var vt:Array = []; // Vertical texture positions (aka V)
			rulers(_height, _texture.height, _offsets.top, _offsets.bottom, vp, vt);

			for (var y:int = 0; y < vp.length - 1; y++)
			{
				for (var x:int = 0; x < hp.length - 1; x++)
				{
					var quad:QuadData = getQuadData();
					quad.setPositions(hp[x], vp[y], hp[x+1], vp[y+1]);
					quad.setTexCoords(ht[x], vt[y], ht[x+1], vt[y+1]);
					_quads[_quads.length] = quad;
				}
			}
		}

		private function rulers(s:Number, ts:Number, t1:Number, t2:Number, o1:Array, o2:Array):void
		{
			// Hard method. Fill arrays o1, o2 with one-dimension "rulers".
			// o1 - rulers positions in range [0; s]
			// o2 - rulers u/v coords in range [0; 1]
			var tsum:Number = t1 + t2;
			if (tsum == 0 || s == ts || tsum >= s) o1.push(0, s) && o2.push(0, 1);
			else o1.push(0, t1, s-t2, s) && o2.push(0, t1/ts, 1-t2/ts, 1);
		}

		private function remeshRepeat():void
		{
			var textureWidth:int = _texture.width;
			var textureHeight:int = _texture.height;

			if (_texture.repeat === false)
			{
				var numColumns:int = Math.ceil(_width / textureWidth);
				var numRows:int = Math.ceil(_height / textureHeight);

				for (var x:int = 0; x < numColumns; x++)
				{
					for (var y:int = 0; y < numRows; y++)
					{
						var quad:QuadData = getQuadData();

						var quadX:int = x*textureWidth;
						var quadY:int = y*textureHeight;
						var quadWidth:int = (x == numColumns-1) ? (_width - quadX) : textureWidth;
						var quadHeight:int = (y == numRows-1) ? (_height - quadY) : textureHeight;

						quad.setPositions(quadX, quadY, quadX + quadWidth, quadY + quadHeight);
						quad.setTexCoords(0, 0, quadWidth/textureWidth, quadHeight/textureHeight);
						_quads[_quads.length] = quad;
					}
				}
			}
			else
			{
				var quad:QuadData = getQuadData();
				quad.setPositions(0, 0, _width, _height);
				quad.setTexCoords(0, 0, _width/textureWidth, _height/textureHeight);
				_quads[_quads.length] = quad;
			}
		}

		private function remeshClip():void
		{

		}

		//
		// Assembling QuadBatch
		//
		/** Compose BatchQuad use _quads list. */
		private function compose():void
		{
			_batch.reset();

			var numQuads:int = _quads.length;
			var data:QuadData = null;

			for (var i:int = 0; i < numQuads; i++)
			{
				data = _quads[i];

				// Position
				HELPER.setVertexPosition(0, data.x1, data.y1);
				HELPER.setVertexPosition(1, data.x2, data.y1);
				HELPER.setVertexPosition(2, data.x1, data.y2);
				HELPER.setVertexPosition(3, data.x2, data.y2);

				if (data.isTextured)
				{
					// Texture
					HELPER.setVertexTexCoords(0, data.ux1, data.vy1);
					HELPER.setVertexTexCoords(1, data.ux2, data.vy1);
					HELPER.setVertexTexCoords(2, data.ux1, data.vy2);
					HELPER.setVertexTexCoords(3, data.ux2, data.vy2);

					HELPER.setVertexColor(0, _tint);
					HELPER.setVertexColor(1, _tint);
					HELPER.setVertexColor(2, _tint);
					HELPER.setVertexColor(3, _tint);

					HELPER.adjustByTexture(texture);

					_batch.addQuad(HELPER, _alpha, _texture, _smoothing, null, BlendMode.NONE);
				}
				else
				{
					// Uniform color
					HELPER.setVertexColor(0, _color);
					HELPER.setVertexColor(1, _color);
					HELPER.setVertexColor(2, _color);
					HELPER.setVertexColor(3, _color);

					_batch.addQuad(HELPER, _alpha);
				}
			}
		}

		//
		// Utils
		//
		private function getQuadData():QuadData
		{
			var data:QuadData = POOL.pop() || new QuadData();
			data.reset();
			return data;
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
				invalidate(MESH);
			}
		}

		public function setScaleOffsets(topOffset:Number, rightOffset:Number, bottomOffset:Number, leftOffset:Number):void
		{
			_offsets.top = topOffset;
			_offsets.right = rightOffset;
			_offsets.bottom = bottomOffset;
			_offsets.left = leftOffset;
			invalidate(MESH);
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
				invalidate(MESH);
			}
		}

		public function get height():Number { return _height; }
		public function set height(value:Number):void
		{
			if (_height != value)
			{
				_height = value;
				invalidate(MESH);
			}
		}

		public function get color():uint { return _color; }
		public function set color(value:uint):void
		{
			if (_color != value)
			{
				_color = value;
				invalidate(MESH);
			}
		}

		public function get tint():uint { return _tint; }
		public function set tint(value:uint):void
		{
			if (_tint != value)
			{
				_tint = value;
				invalidate(MESH);
			}
		}

		public function get transparent():Boolean { return _transparent; }
		public function set transparent(value:Boolean):void
		{
			if (_transparent != value)
			{
				_transparent = value;
				invalidate(MESH);
			}
		}

		public function get alpha():Number { return _alpha; }
		public function set alpha(value:Number):void
		{
			if (_alpha != value)
			{
				_alpha = value;
				invalidate(MESH);
			}
		}

		public function get fillMode():String { return _fillMode; }
		public function set fillMode(value:String):void
		{
			if (_fillMode != value)
			{
				_fillMode = value;
				invalidate(MESH);
			}
		}
	}
}

import starling.display.Quad;
import starling.textures.Texture;

class QuadWithUnsafeAccess extends Quad
{
	public function QuadWithUnsafeAccess():void
	{
		super(1, 1);
	}

	public function setVertexPosition(vertexID:int, x:Number, y:Number):void
	{
		mVertexData.setPosition(vertexID, x, y);
	}

	public function setVertexTexCoords(vertexID:int, u:Number, y:Number):void
	{
		mVertexData.setTexCoords(vertexID, u, y);
	}

	public function adjustByTexture(texture:Texture):void
	{
		texture.adjustVertexData(mVertexData, 0, 4);
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

	public var isTextured:Boolean;

	public function reset():void
	{
		x1 = y1 = x2 = y2 = 0;
		ux1 = vy1 = 0;
		ux2 = vy2 = 1;
		isTextured = false;
	}

	public function setPositions(x1:Number, y1:Number, x2:Number, y2:Number):void
	{
		this.x1 = x1;
		this.y1 = y1;
		this.x2 = x2;
		this.y2 = y2;
	}

	public function setTexCoords(ux1:Number, vy1:Number, ux2:Number, vy2:Number):void
	{
		this.isTextured = true;
		this.ux1 = ux1;
		this.vy1 = vy1;
		this.ux2 = ux2;
		this.vy2 = vy2;
	}
}

class Scale9Offsets
{
	public var top:Number = 0;
	public var right:Number = 0;
	public var bottom:Number = 0;
	public var left:Number = 0;
}