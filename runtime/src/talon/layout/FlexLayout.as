package talon.layout
{
	import talon.Node;

	public class FlexLayout extends Layout
	{
		public override function measureWidth(node:Node, availableHeight:Number):Number
		{
			return makeFlexContainer(node, Number.POSITIVE_INFINITY, availableHeight).size.x;
		}

		public override function measureHeight(node:Node, availableWidth:Number):Number
		{
			return makeFlexContainer(node, availableWidth, Number.POSITIVE_INFINITY).size.y;
		}

		public override function arrange(node:Node, width:Number, height:Number):void
		{
			makeFlexContainer(node, width, height).commit();
		}

		private function makeFlexContainer(node:Node, width:Number, height:Number):FlexContainer
		{
			// Setup flex container
			var container:FlexContainer = new FlexContainer();

			container.setup(
				0, 0, 0, 0, 0, 0, 0, 0, false
			);

			for (var i:int = 0; i < node.numChildren; i++)
			{
				container.addChild(
					0, 0, 0, 0, "", "", ""
				)
			}

			return container;
		}
	}
}

import flash.geom.Point;

import talon.Node;
import talon.enums.BreakMode;

class FlexContainer
{
	// Setup container
	public function setup(mPadding:Number,	cPadding:Number,
		 				  mSize:Number,		cSize:Number,
						  mGap:Number,		cGap:Number,
						  mAlign:Number,	cAlign:Number,
						  wrap:Boolean):void
	{

	}


	// Setup children
	public function addChild(mSize:Number,	 		cSize:Number,
							 mMargin:Number, 		cMargin:Number,
							 breakBefore:String,	breakAfter:String,
							 growMode:String):void
	{
		var childIndex:int = _elements.length;
		var child:FlexElement = _elements[childIndex] = FlexElement.fromPool(null);

		if (needBreak(breakBefore, mSize))
			addBreak();

		child.lineIndex = _lineIndex;
		child.linePos = _lineLength;

		_lineLength += mSize;
		_lineBreak = breakAfter;

		// what about break after?
	}

	private function needBreak(breakBefore:String, mSize:Number):Boolean
	{
		var needBreak:Boolean = false;

		if (_wrap)
		{
			needBreak ||= breakBefore==BreakMode.HARD;
			needBreak ||= breakBefore==BreakMode.SOFT && isOverflow(mSize);
		}

		return needBreak;
	}

	private function isOverflow(length:Number):Boolean
	{
		return (_lineLength+length) > _availableLength;
	}

	private function addBreak():void
	{
		_lineIndex++;
		_lineLength = 0;
	}

	private var _availableLength:Number;
	private var _availableCross:Number;
	private var _wrap:Boolean;

	private var _lineIndex:int;
	private var _lineLength:int;
	private var _lineBreak:String;
	private var _elements:Vector.<FlexElement>;

	// Commit changes
	public function arrange():void { }
	public function get size():Point { return null; }
	public function commit():void { }
}

class FlexElement
{
	public static function fromPool(node:Node):FlexElement { return null; }
	public static function rechargePool():void { }

	public var lineIndex:int;
	public var linePos:Number;

	public function commit():void
	{

	}
}