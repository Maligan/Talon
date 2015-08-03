package
{
	import flexunit.framework.Assert;

	import talon.utils.StringUtil;

	public class StringUtilTest
	{
		[Test]
		public function testParseFunction():void
		{
			var split:Array = null;

			split = StringUtil.parseFunction(null);
			Assert.assertNull(split);

			split = StringUtil.parseFunction("not valid functional string");
			Assert.assertNull(split);

			split = StringUtil.parseFunction("key()");
			Assert.assertNotNull(split);
			Assert.assertEquals(1, split.length);
		}
	}
}
