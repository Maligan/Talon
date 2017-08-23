package
{
	import org.flexunit.Assert;

	import talon.core.Node;
	import talon.core.Style;
	import talon.utils.ParseUtil;
	import talon.utils.StyleUtil;

	public class StyleSheetTest
	{
		private var node:Node;
		private var sheet:Vector.<Style>;

		[Before]
		public function reset():void
		{
			node = new Node();
		}

		[Test]
		public function testAttributeOrder():void
		{
			sheet = ParseUtil.parseCSS("* { a1: 0; a2: 0; a3: 0; a4: 0; a5: 0 }");

			var styles:Object = StyleUtil.style(node, sheet);
			var array:Array = [];
			for (var name:String in styles)
				array.push(name);

			for (var i:int = 0; i < array.length; i++)
			{
				var key:String = "a" + (i + 1);
				Assert.assertEquals(key, array[i]);
			}
		}
	}
}