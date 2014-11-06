package starling.extensions.talon.layout
{
	import flash.utils.Dictionary;
	import starling.extensions.talon.core.Node;

	public class Layout
	{
		//
		// Static Registry & Layout multitone
		//
		private static const _strategy:Dictionary = new Dictionary();
		private static const _strategySelfAttributes:Dictionary = new Dictionary();

		public static function registerLayoutAlias(aliasName:String, layout:Layout, selfAttributes:Array = null, childAttributes:Array = null):void
		{
			var attributesDictionary:Dictionary = new Dictionary();
			for each (var attribute:String in selfAttributes) attributesDictionary[attribute] = true;

			_strategy[aliasName] = layout;
			_strategySelfAttributes[aliasName] = attributesDictionary;
		}

		public static function getLayoutByAlias(aliasName:String):Layout
		{
			return _strategy[aliasName];
		}

		//
		// Layout methods
		//
		public function measureAutoWidth(node:Node, ppp:Number, pem:Number):Number
		{
			return 0;
		}

		public function measureAutoHeight(node:Node, ppp:Number, pem:Number):Number
		{
			return 0;
		}

		public function arrange(node:Node, ppp:Number, pem:Number, width:Number, height:Number):void
		{
			// NOP
		}
	}
}