package talon.utils
{
	import flash.system.Capabilities;

	import talon.core.Node;

	public class Metrics
	{
		private static const PPMM:Number = Capabilities.screenDPI / 25.4;  // 25.4mm in 1 inch
		
		private var _node:Node;
		
		private var _ppdp:Number;
		private var _ppmm:Number;

		public function Metrics(node:Node)
		{
			_node = node;
			_ppmm = PPMM;
			_ppdp = 1;
		}

		/** Pixel per density-independent point (in Starling also known as content scale factor [csf]). */
		public function get ppdp():Number { return _ppdp; }
		public function set ppdp(value:Number):void { _ppdp = value; }

		/** Pixels per millimeter. */
		public function get ppmm():Number { return _ppmm; }
		public function set ppmm(value:Number):void{ _ppmm = value; }

		/** Node 'fontSize' expressed in pixels.*/
		public function get ppem():Number
		{
			var fontSize:Gauge = _node.fontSize;

			// Avoid loops (toPixels() <-> ppem) with EM or PERCENT units
			// 12 is hardcoded version of fontSize 'based' value

			if (fontSize.unit == Gauge.EM)
				return fontSize.amount * (_node.parent ? _node.parent.metrics.ppem : 12);

			else if (fontSize.unit == Gauge.PERCENT)
				return fontSize.amount * (_node.parent ? _node.parent.metrics.ppem : 12) / 100;

			return fontSize.toPixels(this);
		}
	}
}
