package
{
	import flexunit.framework.Assert;

	import talon.utils.OrderedObject;
	import talon.utils.ParseUtil;

	public class UtilTest
	{
		[Test]
		public function testParseFunction():void
		{
			Assert.assertNull(ParseUtil.parseFunction(null));
			Assert.assertNull(ParseUtil.parseFunction("identifier"));
			Assert.assertEquals(1, ParseUtil.parseFunction("key()").length);
			Assert.assertEquals(2, ParseUtil.parseFunction("key(arg1)").length);
			Assert.assertEquals(3, ParseUtil.parseFunction("key(arg1, arg2)").length);
		}

		[Test]
		public function testOrderedObject():void
		{
			var properties:Array =
			[
				"one",
				"two",
				"three",
				"four",
				"five",
				"six",
				"seven",
				"eight",
				"nine",
				"ten"
			];

			var object:Object = new OrderedObject();

			for (var i:int = 0; i < properties.length; i++)
			{
				var key:String = properties[i];
				var value:int = i;
				object[key] = value;
			}

			var index:int = 0;
			for (var attribute:String in object)
			{
				Assert.assertEquals(properties[index], attribute);
				Assert.assertEquals(object[attribute], index);
				index++;
			}
		}
	}
}