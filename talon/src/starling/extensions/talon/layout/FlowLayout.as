package starling.extensions.talon.layout
{
	import starling.extensions.talon.core.Gauge;
	import starling.extensions.talon.core.Node;
	import starling.extensions.talon.utils.Orientation;

	public class FlowLayout extends Layout
	{
		private static const GAP:String = "gap";
		private static const INTERLINE:String = "interline";
		private static const ORIENTATION:String = "orientation";
		private static const WRAP:String = "wrap";
		private static const BREAK:String = "break";
		private static const TRUE:String = "true";


		private static const _gaugeHelper:Gauge = new Gauge();

		private static function toPixels(attribute:String, node:Node, target:Number):Number
		{
			var source:String = node.getAttribute(attribute);
			_gaugeHelper.parse(source);
			return _gaugeHelper.toPixels(node.ppmm, node.ppem, target, 0, 0);
		}

		public override function arrange(node:Node, width:Number, height:Number):void
		{
			// Optimization
			if (node.numChildren == 0) return;

			var orientation:String = node.getAttribute(ORIENTATION);
			if (Orientation.isValid(orientation) === false) throw new Error("Attribute orientation has invalid value: " + orientation);

			var gap:Number = toPixels(GAP, node, (orientation == Orientation.HORIZONTAL? width : height));
			var interline:Number = toPixels(INTERLINE, node, (orientation == Orientation.HORIZONTAL ? width : height));

			var offsetGap:Number = 0;
			var offsetInterline:Number = 0;

			var lines:Vector.<Line> = measure(node, width, height);
			for each (var line:Line in lines)
			{
				offsetGap = 0;

				for (var i:int = line.firstChildIndex; i <= line.lastChildIndex; i++)
				{
					var child:Node = node.getChildAt(i);

					if (orientation == Orientation.HORIZONTAL)
					{
						child.bounds.width = getSize(child.width, child.minWidth, child.maxWidth, child.ppmm, child.ppem, width, line.starLength, line.starAmount);
						child.bounds.height = getSize(child.height, child.minHeight, child.maxHeight, child.ppmm, node.ppem, height, line.thickness, 1);
						offsetGap += child.margin.left.toPixels(node.ppmm, node.ppem, width, 0, 0);
						child.bounds.x = offsetGap;
						offsetGap += child.bounds.width;
						offsetGap += child.margin.right.toPixels(node.ppmm, node.ppem, width, 0, 0);
						offsetGap += gap;
						child.bounds.y = offsetInterline;
					}
					else
					{
						child.bounds.width = getSize(child.width, child.minWidth, child.maxWidth, child.ppmm, child.ppem, width, line.thickness, 1);
						child.bounds.height = getSize(child.height, child.minHeight, child.maxHeight, child.ppmm, node.ppem, height, line.starLength, line.starAmount);
						offsetGap += child.margin.top.toPixels(node.ppmm, node.ppem, width, 0, 0);
						child.bounds.y = offsetGap;
						offsetGap += child.bounds.height;
						offsetGap += child.margin.bottom.toPixels(node.ppmm, node.ppem, width, 0, 0);
						offsetGap += gap;
						child.bounds.x = offsetInterline;
					}

					child.commit();
				}

				offsetInterline += line.thickness + interline;
			}
		}

		public override function measureAutoWidth(node:Node, width:Number, height:Number):Number
		{
			return measureSide(node, Orientation.HORIZONTAL, width, height);
		}

		public override function measureAutoHeight(node:Node, width:Number, height:Number):Number
		{
			return measureSide(node, Orientation.VERTICAL, width, height);
		}

		private function measureSide(node, side:String, width:Number, height:Number):Number
		{
			var orientation:String = node.getAttribute(ORIENTATION);
			if (Orientation.isValid(orientation) === false) throw new Error("Attribute orientation has invalid value: " + orientation);

			var lines:Vector.<Line> = measure(node, width, height);
			var line:Line = null;
			var length:Number = 0;

			if (side == orientation)
			{
				for each (line in lines) length = Math.max(length, line.length);
			}
			else
			{
				for each (line in lines) length = length + line.thickness;
				var interline:Number = toPixels(INTERLINE, node, length);
				length += (lines.length>1) ? (lines.length-1)*interline : 0;
			}

			return length;
		}

		private function measure(node:Node, width:Number, height:Number):Vector.<Line>
		{
			var result:Vector.<Line> = new Vector.<Line>();
			var line:Line;

			var orientation:String = node.getAttribute(ORIENTATION);
			var isHorizontal:Boolean = orientation == Orientation.HORIZONTAL;
			var isVertical:Boolean = orientation == Orientation.VERTICAL;

			var wrap:Boolean = node.getAttribute(WRAP) == TRUE;
			var gap:Number = toPixels(GAP, node, (isHorizontal ? width : height));
			var isAuto:Boolean = (isHorizontal ? node.width : node.height).isAuto;

			var i:int = 0;
			var lineLengthLimit:Number = isHorizontal ? width : height;
			var lineThicknessLimit:Number = isVertical ? width : height;

			while (i < node.numChildren)
			{
				line = new Line();

				// ----
				line.firstChildIndex = i;
				line.length = 0;
				line.thickness = 0;
				line.starAmount = 0;
				line.starLength = 0;

				for (i = line.firstChildIndex; i < node.numChildren; i++)
				{
					var child:Node = node.getChildAt(i);

					// If child require new line - break it
					var childIsBreak:Boolean = wrap && (line.firstChildIndex != i) && (child.getAttribute(BREAK) == TRUE);
					if (childIsBreak) break;

					var size:Gauge = isHorizontal ? child.width : child.height;
					var minSize:Gauge = isHorizontal ? child.minWidth : child.minHeight;
					var maxSize:Gauge = isHorizontal ? child.maxWidth : child.maxHeight;
					var margin1:Gauge = isHorizontal ? child.margin.left : child.margin.top;
					var margin2:Gauge = isHorizontal ? child.margin.right : child.margin.bottom;

					// Define margin
					var margin:Number = 0;
					margin += margin1.toPixels(child.ppmm, child.ppem, lineLengthLimit, 0, 0);
					margin += margin2.toPixels(child.ppmm, child.ppem, lineLengthLimit, 0, 0);

					// Star unit doesn't add any length
					if (size.unit == Gauge.STAR)
					{
						line.starAmount += size.amount;
						if (i != line.firstChildIndex) line.length += gap;
					}
					else
					{
						// Define size
						var childLength:Number = getSize(size, minSize, maxSize, child.ppmm, child.ppem, lineLengthLimit, 0, 0) + margin;
						if (i != line.firstChildIndex) childLength += gap;

						if (wrap && (i != line.firstChildIndex) && !isAuto)
						{
							var isOverflow:Boolean = line.length + childLength > lineLengthLimit;
							if (isOverflow) break;
						}

						line.length += childLength;
					}

					line.lastChildIndex = i;

					// Calculate line thickness
					size = isVertical ? child.width : child.height;
					minSize = isVertical ? child.minWidth : child.minHeight;
					maxSize = isVertical ? child.maxWidth : child.maxHeight;
					margin1 = isVertical ? child.margin.left : child.margin.top;
					margin2 = isVertical ? child.margin.right : child.margin.bottom;

					margin = margin1.toPixels(node.ppmm, node.ppem, lineThicknessLimit, 0, 0) + margin2.toPixels(node.ppmm, node.ppem, lineThicknessLimit, 0, 0);
					line.thickness = Math.max(line.thickness, getSize(size, minSize, maxSize, child.ppmm, child.ppem, lineThicknessLimit, 0, 0) + margin);
				}

				line.starLength = Math.max(0, lineLengthLimit - line.length);
				result.push(line);
				//-------------
			}

			return result;
		}

		private function getSize(size:Gauge, min:Gauge, max:Gauge, pppt:Number, ppem:Number, percentTarget:Number, starTarget:Number = 0, starCount:Number = 0):Number
		{
			var value:Number = size.toPixels(pppt, ppem, percentTarget, starTarget, starCount);
			if (!min.isNone) value = Math.max(value, min.toPixels(pppt, ppem, percentTarget, starTarget, starCount));
			if (!max.isNone) value = Math.min(value, max.toPixels(pppt, ppem, percentTarget, starTarget, starCount));
			return value;
		}
	}
}

class Line
{
	public var firstChildIndex:int;
	public var lastChildIndex:int;

	public var length:Number;
	public var thickness:Number;

	public var starLength:Number;
	public var starAmount:Number;
}