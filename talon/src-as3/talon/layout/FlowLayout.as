package talon.layout
{
	import flash.geom.Rectangle;

	import talon.Attribute;
	import talon.Node;
	import talon.enums.Orientation;
	import talon.utils.Gauge;
	import talon.utils.StringUtil;

	public class FlowLayout extends Layout
	{
		public override function measureAutoWidth(node:Node, availableWidth:Number, availableHeight:Number):Number
		{
			var flow:Flow = measure(node, availableWidth, availableHeight, false);
			var flowWidth:Number = node.getAttribute(Attribute.ORIENTATION) == Orientation.HORIZONTAL ? flow.getLength() : flow.getThickness();
			flow.dispose();
			return flowWidth;
		}

		public override function measureAutoHeight(node:Node, availableWidth:Number, availableHeight:Number):Number
		{
			var flow:Flow = measure(node, availableWidth, availableHeight, false);
			var flowHeight:Number = node.getAttribute(Attribute.ORIENTATION) == Orientation.VERTICAL ? flow.getLength() : flow.getThickness();
			flow.dispose();
			return flowHeight;
		}

		public override function arrange(node:Node, width:Number, height:Number):void
		{
			var orientation:String = node.getAttribute(Attribute.ORIENTATION);
			var flow:Flow = measure(node, width, height, true);

			for (var i:int = 0; i < node.numChildren; i++)
			{
				var child:Node = node.getChildAt(i);
				var childBounds:Rectangle = flow.getChildBounds(i, orientation);
				child.bounds.copyFrom(childBounds);
				child.validate();
			}

			flow.dispose();
		}

		//
		// Implementation
		//
		private function measure(node:Node, availableWidth:Number, availableHeight:Number, arrange:Boolean):Flow
		{
			var flow:Flow = new Flow();
			flow.setSpacings(getGap(node), getInterline(node));
			flow.setWrap(getWrap(node));

			var orientation:String = node.getAttribute(Attribute.ORIENTATION);
			if (orientation == Orientation.HORIZONTAL)
			{
				flow.setMaxSize(availableWidth, availableHeight);
				flow.setAlign(getAlign(node, Attribute.HALIGN), getAlign(node, Attribute.VALIGN));

				for (var i:int = 0; i < node.numChildren; i++)
				{
					var child:Node = node.getChildAt(i);

					flow.beginChild();
					flow.setChildLength(child.width.amount, child.width.unit == Gauge.STAR);
					flow.setChildLengthMargin(child.margin.left.amount, child.margin.right.amount);
					flow.setChildThickness(child.height.amount, child.height.unit == Gauge.STAR);
					flow.setChildThicknessMargin(child.margin.top.amount, child.margin.top.amount);
					flow.setChildInlineAlign(getAlign(child, Attribute.IVALIGN));
					flow.setChildBreakMode(child.getAttribute(Attribute.BREAK));
					flow.endChild();
				}
			}
			else
			{
				flow.setMaxSize(node.height.isAuto ? Infinity : availableHeight, node.width.isAuto ? Infinity : availableWidth)
			}

			if (arrange) flow.arrange();
			return flow;
		}

		private function getWrap(node:Node):Boolean { return node.getAttribute(Attribute.WRAP) == "true"; }
		private function getAlign(node:Node, name:String):Number { return StringUtil.parseAlign(node.getAttribute(name)) }
		private function getGap(node:Node):Number { return Gauge.toPixels(node.getAttribute(Attribute.GAP), node.ppmm, node.ppem, node.ppdp, -1, 0, 0, 0, 0); }
		private function getInterline(node:Node):Number { return Gauge.toPixels(node.getAttribute(Attribute.INTERLINE), node.ppmm, node.ppem, node.ppdp, -1, 0, 0, 0, 0); }
	}
}

import flash.geom.Rectangle;
import flash.utils.Dictionary;

import talon.enums.Break;
import talon.enums.Orientation;

class Flow
{
	// Properties
	private var _maxLength:Number;
	private var _lengthPaddingBegin:Number = 0;
	private var _lengthPaddingEnd:Number = 0;
	private var _gap:Number;

	private var _maxThickness:Number;
	private var _thicknessPaddingBegin:Number = 0;
	private var _thicknessPaddingEnd:Number = 0;
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
	private var _break:Boolean;

	public function Flow()
	{
		_rectangle = new Rectangle();
		_lines = new <FlowLine>[];
		_lineByChildIndex = new Dictionary();
		_childIndex = -1;
		_break = true;
	}

	private function getNewLine():FlowLine
	{
		var line:FlowLine = new FlowLine(_maxLength, _gap, _childIndex);
		_lines[_lines.length] = line;
		return line;
	}

	// Phase 0
	public function setMaxSize(maxLength:Number, maxThickness:Number):void
	{
		_maxLength = maxLength;
		_maxThickness = maxThickness;
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

		// New Line
		if (_break)
		{
			_break = false;
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
			_break = _childBreakMode == Break.AFTER || _childBreakMode == Break.BOTH;
			var hasBreakBefore:Boolean = _childBreakMode == Break.BEFORE || _childBreakMode == Break.BOTH;
			if (hasBreakBefore && line.numChildren != 0)
			{
				line = getNewLine();
			}
			else if (!line.canAddChildWithoutOverflow(_child))
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
		var thickness:Number = 0;

		var lShift:Number = _maxLength!=Infinity ? (_maxLength-getLength())*_alignLengthwise : 0;
		var tShift:Number = _maxThickness!=Infinity ? (_maxThickness-getThickness())*_alignThicknesswise : 0;

		for each (var line:FlowLine in _lines)
		{
			line.arrange(lShift, tShift + thickness);
			thickness += line.thickness + _interline;
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
		var result:Number = _lengthPaddingBegin + _lengthPaddingEnd;
		for each (var line:FlowLine in _lines) result = Math.max(result, line.length);
		return result;
	}

	public function getThickness():Number
	{
		var result:Number = _thicknessPaddingBegin + _thicknessPaddingEnd;
		if (_lines.length > 0) result += (_lines.length - 1) * _interline;
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
		return _length+_gap+child.lengthBefore+(child.lengthIsStar?0:child.length)+child.lengthAfter < _maxLength;
	}

	public function addChild(child:FlowElement):void
	{
		_children[_children.length] = child;

		if (child.lengthIsStar) _lengthStar += child.length;
		else _length += child.length;
		if (_children.length > 1) _length += _gap;
		_length += child.lengthBefore + child.lengthAfter;

		if (!child.thicknessIsStar) _thickness = Math.max(_thickness, child.thickness);
	}

	public function arrange(lShift:Number, tShift:Number):void
	{
		var lOffset:Number = 0;

		for each (var element:FlowElement in _children)
		{
			element.lPos = lShift + lOffset + element.lengthBefore;
			element.tPos = tShift + (_thickness-element.thickness)*element.thicknessAlign;
			element.tSize = element.thicknessIsStar ? _thickness : element.thickness;

			if (!element.lengthIsStar) element.lSize = element.length;
			else if (_maxLength!=Infinity && _maxLength>_length) element.lSize = (_maxLength-_length)*(element.length/_lengthStar);
			else element.lSize = 0;

			lOffset += element.lengthBefore + element.lSize + element.lengthAfter  + _gap;
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
	public function get length():Number { return (_lengthStar!=0 && _length<_maxLength) ? _maxLength : _length }
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