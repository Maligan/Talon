package talon.layout
{
	import flash.geom.Rectangle;

	import talon.Attribute;
	import talon.Node;
	import talon.enums.Orientation;
	import talon.utils.AttributeGauge;
	import talon.utils.ParseUtil;
	import talon.utils.ParseUtil;

	public class FlowLayout extends Layout
	{
		public override function measureWidth(node:Node, availableHeight:Number):Number
		{
			var flow:Flow = calculateFlow(node, Infinity, availableHeight);
			var flowWidth:Number = node.getAttributeCache(Attribute.ORIENTATION) == Orientation.HORIZONTAL ? flow.getLength() : flow.getThickness();
			flow.dispose();
			return flowWidth;
		}

		public override function measureHeight(node:Node, availableWidth:Number):Number
		{
			var flow:Flow = calculateFlow(node, availableWidth, Infinity);
			var flowHeight:Number = node.getAttributeCache(Attribute.ORIENTATION) == Orientation.VERTICAL ? flow.getLength() : flow.getThickness();
			flow.dispose();
			return flowHeight;
		}

		public override function arrange(node:Node, width:Number, height:Number):void
		{
			var orientation:String = node.getAttributeCache(Attribute.ORIENTATION);
			var flow:Flow = calculateFlow(node, width, height);
			flow.arrange();

			for (var i:int = 0; i < node.numChildren; i++)
			{
				var child:Node = node.getChildAt(i);
				var childBounds:Rectangle = flow.getChildBounds(i, orientation);
				child.bounds.copyFrom(childBounds);
				child.commit();
			}

			flow.dispose();
		}

		//
		// Implementation
		//
		private function calculateFlow(node:Node, maxWidth:Number, maxHeight:Number):Flow
		{
			var orientationAttribute:Attribute = node.getOrCreateAttribute(Attribute.ORIENTATION);
			var orientation:String = orientationAttribute.valueCache;
			if (Orientation.isValid(orientation) == false)
			{
				trace("[FlowLayout]", "Invalid orientation value ='" + orientation + "' use default.");
				orientation = orientationAttribute.inited;
			}

			var paddingLeft:Number = node.paddingLeft.toPixels(node.ppmm, node.ppem, node.ppdp, 0);
			var paddingRight:Number = node.paddingRight.toPixels(node.ppmm, node.ppem, node.ppdp, 0);
			var paddingTop:Number = node.paddingTop.toPixels(node.ppmm, node.ppem, node.ppdp, 0);
			var paddingBottom:Number = node.paddingBottom.toPixels(node.ppmm, node.ppem, node.ppdp, 0);

			var contentWidth:Number = maxWidth==Infinity ? 0 : (maxWidth - paddingLeft - paddingRight);
			var contentHeight:Number = maxHeight==Infinity ? 0 : (maxHeight - paddingTop - paddingBottom);

			var flow:Flow = new Flow();
			flow.setSpacings(getGap(node), getInterline(node));
			flow.setWrap(getWrap(node));

			// Common orientation based flow setup
			if (orientation == Orientation.HORIZONTAL)
			{
				flow.setMaxSize(maxWidth, maxHeight);
				flow.setAlign(getAlign(node, Attribute.HALIGN), getAlign(node, Attribute.VALIGN));
				flow.setPadding(paddingLeft, paddingRight, paddingTop, paddingBottom);
			}
			else
			{
				flow.setMaxSize(maxHeight, maxWidth);
				flow.setAlign(getAlign(node, Attribute.VALIGN), getAlign(node, Attribute.HALIGN));
				flow.setPadding(paddingTop, paddingBottom, paddingLeft, paddingRight);
			}

			// Child calculation
			for (var i:int = 0; i < node.numChildren; i++)
			{
				var child:Node = node.getChildAt(i);

				// TODO: Respect minWidth/maxWidth/minHeight/maxHeight values
				// ------------------------------------------
				var childWidth:Number = 0;
				var childHeight:Number = 0;

				if (child.width.isNone && !child.height.isNone)
				{
					// contentWidth && and contentHeight for auto!
					childHeight = child.height.toPixels(node.ppmm, node.ppem, node.ppdp, contentHeight, Infinity, child.height.amount, child.height.amount);
					childWidth  = child.width.toPixels (node.ppmm, node.ppem, node.ppdp, contentWidth, childHeight, child.width.amount, child.width.amount);
				}
				else if (child.height.isNone && !child.width.isNone)
				{
					childWidth  = child.width.toPixels (node.ppmm, node.ppem, node.ppdp, contentWidth, Infinity, child.width.amount, child.width.amount);
					childHeight = child.height.toPixels(node.ppmm, node.ppem, node.ppdp, contentHeight, childWidth, child.height.amount, child.height.amount);
				}
				else
				{
					childWidth  = child.width.toPixels (node.ppmm, node.ppem, node.ppdp, contentWidth, Infinity, child.width.amount, child.width.amount);
					childHeight = child.height.toPixels(node.ppmm, node.ppem, node.ppdp, contentHeight, Infinity, child.height.amount, child.height.amount);
				}
				// ------------------------------------------

				var childMarginLeft:Number      = child.marginLeft.toPixels(node.ppmm, node.ppem, node.ppdp, contentWidth);
				var childMarginRight:Number     = child.marginRight.toPixels(node.ppmm, node.ppem, node.ppdp, contentWidth);
				var childMarginTop:Number       = child.marginTop.toPixels(node.ppmm, node.ppem, node.ppdp, contentHeight);
				var childMarginBottom:Number    = child.marginBottom.toPixels(node.ppmm, node.ppem, node.ppdp, contentHeight);

				// Setup child flow values
				flow.beginChild();
				flow.setChildBreakMode(child.getAttributeCache(Attribute.BREAK));
				if (orientation == Orientation.HORIZONTAL)
				{
					flow.setChildLength(childWidth, child.width.unit == AttributeGauge.STAR);
					flow.setChildLengthMargin(childMarginLeft, childMarginRight);
					flow.setChildThickness(childHeight, child.height.unit == AttributeGauge.STAR);
					flow.setChildThicknessMargin(childMarginTop, childMarginBottom);
					flow.setChildInlineAlign(getAlign(child, Attribute.IVALIGN));
				}
				else
				{
					flow.setChildLength(childHeight, child.height.unit == AttributeGauge.STAR);
					flow.setChildLengthMargin(childMarginTop, childMarginBottom);
					flow.setChildThickness(childWidth, child.width.unit == AttributeGauge.STAR);
					flow.setChildThicknessMargin(childMarginLeft, childMarginRight);
					flow.setChildInlineAlign(getAlign(child, Attribute.IHALIGN));
				}
				flow.endChild();
			}

			return flow;
		}

		private function getWrap(node:Node):Boolean { return ParseUtil.parseBoolean(node.getAttributeCache(Attribute.WRAP)); }
		private function getAlign(node:Node, name:String):Number { return ParseUtil.parseAlign(node.getAttributeCache(name)); }
		private function getGap(node:Node):Number { return AttributeGauge.toPixels(node.getAttributeCache(Attribute.GAP), node.ppmm, node.ppem, node.ppdp, -1); }
		private function getInterline(node:Node):Number { return AttributeGauge.toPixels(node.getAttributeCache(Attribute.INTERLINE), node.ppmm, node.ppem, node.ppdp, -1); }
	}
}

import flash.geom.Rectangle;
import flash.utils.Dictionary;

import talon.enums.BreakMode;
import talon.enums.Orientation;
import talon.layout.Layout;

class Flow
{
	// Properties
	private var _maxLength:Number;
	private var _lengthPaddingBegin:Number;
	private var _lengthPaddingEnd:Number;
	private var _gap:Number;

	private var _maxThickness:Number;
	private var _thicknessPaddingBegin:Number;
	private var _thicknessPaddingEnd:Number;
	private var _interline:Number;

	private var _wrap:Boolean;
	private var _alignLengthwise:Number;
	private var _alignThicknesswise:Number;

	private var _lines:Vector.<FlowLine>;
	private var _lineByChildIndex:Dictionary;

	private var _childIndex:int;
	private var _childBreakMode:String;
	private var _child:FlowElement;

	private var _rectangle:Rectangle;
	private var _breakOnNextChild:Boolean;

	public function Flow()
	{
		_rectangle = new Rectangle();
		_lines = new <FlowLine>[];
		_lineByChildIndex = new Dictionary();
		_childIndex = -1;
		_breakOnNextChild = true;
	}

	private function getNewLine():FlowLine
	{
		var line:FlowLine = new FlowLine(_maxLength - _lengthPaddingBegin - _lengthPaddingEnd, _gap, _childIndex);
		_lines[_lines.length] = line;
		return line;
	}

	// Phase 0
	public function setMaxSize(lMax:Number, tMax:Number):void
	{
		_maxLength = lMax;
		_maxThickness = tMax;
	}

	public function setWrap(wrap:Boolean):void
	{
		_wrap = wrap;
	}

	public function setSpacings(gap:Number, interline:Number):void
	{
		_gap = gap;
		_interline = interline;
	}

	public function setPadding(lBefore:Number, lAfter:Number, tBefore:Number, tAfter:Number):void
	{
		_lengthPaddingBegin = lBefore;
		_lengthPaddingEnd = lAfter;
		_thicknessPaddingBegin = tBefore;
		_thicknessPaddingEnd = tAfter;
	}

	public function setAlign(lengthwise:Number, thicknesswise:Number):void
	{
		_alignLengthwise = lengthwise;
		_alignThicknesswise = thicknesswise;
	}

	// Phase 1
	public function beginChild():void
	{
		// New Child
		_childIndex++;
		_child = new FlowElement();
		_child.lengthBefore = _child.lengthAfter = 0;

		if (_breakOnNextChild)
		{
			_breakOnNextChild = false;
			getNewLine();
		}
	}

	public function setChildLength(value:Number, isStar:Boolean):void { _child.length = value; _child.lengthIsStar = isStar }
	public function setChildLengthMargin(before:Number, after:Number):void { _child.lengthBefore = before; _child.lengthAfter = after }
	public function setChildThickness(value:Number, isStar:Boolean):void { _child.thickness = value; _child.thicknessIsStar = isStar }
	public function setChildThicknessMargin(before:Number, after:Number):void { _child.thicknessBefore = before; _child.thicknessAfter = after }
	public function setChildInlineAlign(value:Number):void { _child.thicknessAlign = value }
	public function setChildBreakMode(value:String):void { _childBreakMode = value }

	public function endChild():void
	{
		var line:FlowLine = _lines[_lines.length-1];

		if (_wrap)
		{
			_breakOnNextChild = BreakMode.isBreakAfter(_childBreakMode);

			if (BreakMode.isBreakBefore(_childBreakMode) && line.numChildren != 0 || !line.canAddChildWithoutOverflow(_child))
			{
				line = getNewLine();
			}
		}

		line.addChild(_child);
		_lineByChildIndex[_childIndex] = line;
		_child = null;
	}

	public function arrange():void
	{
		var calcLength:Number = getLength();
		var calcThickness:Number = getThickness();

		// Content bounds
		var contentLength:Number    = calcLength - _lengthPaddingBegin - _lengthPaddingEnd;
		var contentThickness:Number = calcThickness - _thicknessPaddingBegin - _thicknessPaddingEnd;

		// Full bounds
		var length:Number           = _maxLength != Infinity    ? _maxLength    : calcLength;
		var thickness:Number        = _maxThickness != Infinity ? _maxThickness : calcLength;

		var offset:Number = 0;
		for each (var line:FlowLine in _lines)
		{
			var l:Number = Layout.pad(length, contentLength, _lengthPaddingBegin, _lengthPaddingEnd, _alignLengthwise);
			var t:Number = Layout.pad(thickness, contentThickness, _thicknessPaddingBegin, _thicknessPaddingEnd, _alignThicknesswise);

			line.arrange(l, offset + t);
			offset += line.thickness + _interline;
		}
	}

	// Phase 2
	public function getChildBounds(index:int, orientation:String):Rectangle
	{
		var line:FlowLine = _lineByChildIndex[index];
		var lineChildIndex:int = index - line.firstChildIndex;
		return line.getChildBounds(lineChildIndex, orientation, _rectangle);
	}

	public function getLength():Number
	{
		var result:Number = 0;
		for each (var line:FlowLine in _lines) result = Math.max(result, line.length);
		return _lengthPaddingBegin + result + _lengthPaddingEnd;
	}

	public function getThickness():Number
	{
		var result:Number = _thicknessPaddingBegin + _thicknessPaddingEnd;
		if (_lines.length > 1) result += (_lines.length - 1) * _interline;
		for each (var line:FlowLine in _lines) result += line.thickness;
		return result;
	}

	// Phase 3
	public function dispose():void
	{

	}
}

class FlowLine
{
	private var _children:Vector.<FlowElement>;

	private var _maxLength:Number;
	private var _gap:Number;
	private var _firstChildIndex:int;

	private var _thickness:Number;
	private var _length:Number;
	private var _lengthStar:Number;

	public function FlowLine(maxLength:Number, gap:Number, firstChildIndex:int):void
	{
		_maxLength = maxLength;
		_gap = gap;
		_firstChildIndex = firstChildIndex;
		_length = 0;
		_lengthStar = 0;
		_thickness = 0;
		_children = new <FlowElement>[];
	}

	public function canAddChildWithoutOverflow(child:FlowElement):Boolean
	{
		return _length+_gap+child.lengthBefore+(child.lengthIsStar?0:child.length)+child.lengthAfter <= _maxLength;
	}

	public function addChild(child:FlowElement):void
	{
		_children[_children.length] = child;

		if (child.lengthIsStar) _lengthStar += child.length;
		else _length += child.length;

		if (_children.length > 1) _length += _gap;
		_length += child.lengthBefore + child.lengthAfter;

		_thickness = Math.max(_thickness, child.thicknessBefore + (!child.thicknessIsStar ? child.thickness : 0) + child.thicknessAfter);
	}

	public function arrange(lShift:Number, tShift:Number):void
	{
		var lOffset:Number = 0;

		for each (var element:FlowElement in _children)
		{
			// Via length
			element.lPos = lShift + lOffset + element.lengthBefore;
			if (!element.lengthIsStar) element.lSize = element.length;
			else if (_maxLength!=Infinity && _length<_maxLength) element.lSize = (_maxLength-_length)*(element.length/_lengthStar);
			else element.lSize = 0;

			// Via thickness
			element.tSize = element.thicknessIsStar ? _thickness : element.thickness;
			element.tPos = tShift + Layout.pad(_thickness, element.tSize, element.thicknessBefore, element.thicknessAfter, element.thicknessAlign);

			lOffset += element.lengthBefore + element.lSize + element.lengthAfter + _gap;
		}
	}

	public function getChildBounds(index:int, orientation:String, result:Rectangle):Rectangle
	{
		var child:FlowElement = _children[index];

		orientation == Orientation.HORIZONTAL
			? result.setTo(child.lPos, child.tPos, child.lSize, child.tSize)
			: result.setTo(child.tPos, child.lPos, child.tSize, child.lSize);

		return result;
	}

	public function get firstChildIndex():int { return _firstChildIndex }
	public function get length():Number { return (_lengthStar!=0 && _length<_maxLength && _maxLength!=Infinity) ? _maxLength : _length }
	public function get thickness():Number { return _thickness }
	public function get numChildren():int { return _children.length }
}

class FlowElement
{
	public var lengthBefore:Number;
	public var lengthAfter:Number;
	public var length:Number;
	public var lengthIsStar:Boolean;

	public var thicknessBefore:Number;
	public var thicknessAfter:Number;
	public var thickness:Number;
	public var thicknessIsStar:Boolean;
	public var thicknessAlign:Number;

	// Result
	public var lPos:Number;
	public var lSize:Number;
	public var tPos:Number;
	public var tSize:Number;
}