package talon.starling
{
	import starling.core.RenderSupport;
	import starling.display.BlendMode;
	import starling.display.Quad;
	import starling.display.QuadBatch;
	import starling.errors.AbstractMethodError;
	import starling.textures.Texture;
	import starling.textures.TextureSmoothing;

	import talon.enums.FillMode;

	internal class BackgroundRenderer
	{
		private static var POOL:Vector.<QuadData>;
		private static var HELPER:QuadWithUnsafeAccess;

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

		private var _mesh:Vector.<QuadData>;
		private var _batch:QuadBatch;
		private var _requestRedraw:Boolean;

		public function BackgroundRenderer():void
		{
			POOL = new <QuadData>[];
			HELPER = new QuadWithUnsafeAccess();

			_requestRedraw = true;
			_mesh = new <QuadData>[];
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
			if (_batch.alpha == 0 || _texture == null && _transparent) return;

			if (_requestRedraw)
			{
				createMesh();
				createQuadBatch();

				// Starling recommend use batchable if batch has less when 16 quads
				_batch.batchable = _batch.numQuads <= 16;
				_requestRedraw = false;
			}

			_batch.render(support, parentAlpha);
		}

		//
		// Defining quads for render
		//
		private function createMesh():void
		{
			// Release prev quads list
			while (_mesh.length > 0) POOL[POOL.length] = _mesh.pop();

			// Define _mesh for render
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
			_mesh[_mesh.length] = quad;
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
					_mesh[_mesh.length] = quad;
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
			var quad:QuadData;

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
						quad = getQuadData();

						var quadX:int = x*textureWidth;
						var quadY:int = y*textureHeight;
						var quadWidth:int = (x == numColumns-1) ? (_width - quadX) : textureWidth;
						var quadHeight:int = (y == numRows-1) ? (_height - quadY) : textureHeight;

						quad.setPositions(quadX, quadY, quadX + quadWidth, quadY + quadHeight);
						quad.setTexCoords(0, 0, quadWidth/textureWidth, quadHeight/textureHeight);
						_mesh[_mesh.length] = quad;
					}
				}
			}
			else
			{
				quad = getQuadData();
				quad.setPositions(0, 0, _width, _height);
				quad.setTexCoords(0, 0, _width/textureWidth, _height/textureHeight);
				_mesh[_mesh.length] = quad;
			}
		}

		private function remeshClip():void
		{
			var width:Number = Math.min(_width, texture.width);
			var height:Number = Math.min(_height, texture.height);
			var quad:QuadData = getQuadData();
			quad.setPositions(0, 0, width, height);
			quad.setTexCoords(0, 0, width/texture.width, height/texture.height);
			_mesh[_mesh.length] = quad;
		}

		//
		// Assembling QuadBatch
		//
		/** Compose BatchQuad use _mesh list. */
		private function createQuadBatch():void
		{
			_batch.reset();

			var numQuads:int = _mesh.length;
			var data:QuadData = null;

			for (var i:int = 0; i < numQuads; i++)
			{
				data = _mesh[i];

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

					_batch.addQuad(HELPER, _alpha, _texture, _smoothing);
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
		public function set9ScaleOffsets(topOffset:Number, rightOffset:Number, bottomOffset:Number, leftOffset:Number):void
		{
			_offsets.top = topOffset;
			_offsets.right = rightOffset;
			_offsets.bottom = bottomOffset;
			_offsets.left = leftOffset;
			_requestRedraw = true;
		}

		public function get texture():Texture { return _texture; }
		public function set texture(value:Texture):void
		{
			if (texture != value)
			{
				_texture = value;
				_requestRedraw = true;
			}
		}

		public function get smoothing():String { return _smoothing; }
		public function set smoothing(value:String):void
		{
			if (_smoothing != value)
			{
				if (TextureSmoothing.isValid(value)) _smoothing = value;
				else throw new ArgumentError("Invalid smoothing mode: " + value);
				_requestRedraw = true;
			}
		}

		public function get width():Number { return _width; }
		public function set width(value:Number):void
		{
			if (_width != value)
			{
				_width = value;
				_requestRedraw = true;
			}
		}

		public function get height():Number { return _height; }
		public function set height(value:Number):void
		{
			if (_height != value)
			{
				_height = value;
				_requestRedraw = true;
			}
		}

		public function get color():uint { return _color; }
		public function set color(value:uint):void
		{
			if (_color != value)
			{
				_color = value;
				_requestRedraw = true;
			}
		}

		public function get tint():uint { return _tint; }
		public function set tint(value:uint):void
		{
			if (_tint != value)
			{
				_tint = value;
				_requestRedraw = true;
			}
		}

		public function get transparent():Boolean { return _transparent; }
		public function set transparent(value:Boolean):void
		{
			if (_transparent != value)
			{
				_transparent = value;
				_requestRedraw = true;
			}
		}

		public function get alpha():Number { return _alpha; }
		public function set alpha(value:Number):void
		{
			if (_batch.alpha != value)
				_batch.alpha = value;
		}

		public function get blendMode():String { return _batch.blendMode; }
		public function set blendMode(value:String):void
		{
			if (_batch.blendMode != value)
				_batch.blendMode = value;
		}

		public function get fillMode():String { return _fillMode; }
		public function set fillMode(value:String):void
		{
			if (_fillMode != value)
			{
				_fillMode = value;
				_requestRedraw = true;
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