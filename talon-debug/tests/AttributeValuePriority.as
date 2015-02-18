package
{
	import flexunit.framework.Assert;

	import talon.Attribute;
	import talon.Node;

	public class AttributeValuePriority
	{
		private var node:Node;
		private var attribute:Attribute;

		[Before]
		public function setUp():void
		{
			node = new Node();
			attribute = node.getOrCreateAttribute("test");
		}

		[Test]
		public function testName():void
		{
			attribute.assigned = "assigned";
			Assert.assertEquals("assigned", attribute.value);
		}

		[Test]
		public function testName2():void
		{
			attribute.initial = "initial";
			Assert.assertEquals("initial", attribute.value);
		}

		[Test]
		public function testName3():void
		{
			attribute.initial = "initial";
			attribute.assigned = "assigned";
			Assert.assertEquals("assigned", attribute.value);
		}

		[Test]
		public function testName4():void
		{
			attribute.initial = "initial";
			attribute.styled = "styled";
			attribute.styleable = true;
			Assert.assertEquals("styled", attribute.value);
		}

		[Test]
		public function testName5():void
		{
			attribute.initial = "initial";
			attribute.styled = "styled";
			attribute.styleable = false;
			Assert.assertEquals("initial", attribute.value);
		}

		[Test]
		public function testName6():void
		{
			attribute.initial = "initial";
			attribute.styled = "styled";
			attribute.styleable = true;
			attribute.assigned = "assigned";
			Assert.assertEquals("assigned", attribute.value);
		}

		[Test]
		public function testName7():void
		{
			attribute.initial = "initial";
			Assert.assertEquals(null, attribute.assigned);
			Assert.assertEquals("initial", attribute.value);
		}
	}
}
