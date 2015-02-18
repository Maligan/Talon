package
{
	import flexunit.framework.Assert;

	import starling.events.Event;

	import talon.Attribute;
	import talon.Node;

	public class AttributeInherit
	{
		private var root:Node;
		private var parent:Node;
		private var node:Node;
		private var attribute:Attribute;

		[Before]
		public function setUp():void
		{
			node = new Node();
			node.getOrCreateAttribute("test").inheritable = true;

			parent = new Node();
			parent.addChild(node);
			parent.getOrCreateAttribute("test").inheritable = true;

			root = new Node();
			root.addChild(parent);
			root.getOrCreateAttribute("test").inheritable = true;

			attribute = node.getOrCreateAttribute("test");
		}

		[Test]
		public function testName():void
		{
			node.setAttribute("test", Attribute.INHERIT);
			parent.setAttribute("test", Attribute.INHERIT);
			root.setAttribute("test", "root_value");

			Assert.assertEquals("root_value", attribute.origin);
		}

		[Test]
		public function testName1():void
		{
			node.setAttribute("test", Attribute.INHERIT);
			parent.setAttribute("test", Attribute.INHERIT);
			node.addEventListener(Event.CHANGE, onChange);

			root.setAttribute("test", "root_value");

			function onChange(e:Event):void
			{
				if (e.data == "test")
				{
					Assert.assertEquals("root_value", attribute.origin);
				}
			}

		}

		[Test]
		public function testName2():void
		{
			var dispatched:Boolean = false;

			node.setAttribute("test", Attribute.INHERIT);
			parent.setAttribute("test", Attribute.INHERIT);
			root.setAttribute("test", "root_value");

			node.addEventListener(Event.CHANGE, onChange);
			parent.getOrCreateAttribute("test").inheritable = false;
			Assert.assertEquals(true, dispatched);

			function onChange(e:Event):void
			{
				if (e.data == "test")
				{
					dispatched = true;
					Assert.assertEquals("inherit", attribute.origin);
				}
			}
		}
	}
}
