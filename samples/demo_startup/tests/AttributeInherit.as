package
{
	import flexunit.framework.Assert;

	import starling.events.Event;

	import starling.extensions.talon.core.Attribute;
	import starling.extensions.talon.core.Node;

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

			function onChange(e:Event):void
			{
				if (e.data == "test")
				{
					Assert.assertEquals("root_value", attribute.origin);
				}
			}

			root.setAttribute("test", "root_value");
		}
	}
}
